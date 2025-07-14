// lib/screens/chat_screen.dart - BitChat'teki ContentView'dan çevrildi
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_manager.dart';
import '../services/mesh_network_manager.dart';
import '../services/encryption_service.dart';
import '../models/message.dart';
import '../models/peer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/peer_list.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final EncryptionService _encryptionService = EncryptionService();
  
  @override
  void initState() {
    super.initState();
    _encryptionService.initialize();
    
    // Initialize mesh network with random user ID
    final meshManager = context.read<MeshNetworkManager>();
    meshManager.initialize('user_${DateTime.now().millisecondsSinceEpoch}');
    
    // Start Bluetooth scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothManager>().startScanning();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<MeshNetworkManager>(
          builder: (context, meshManager, child) {
            final currentChannel = meshManager.currentChannel;
            return Text(currentChannel?.name ?? 'MESHNET');
          },
        ),
        actions: [
          // Peer count indicator
          Consumer<BluetoothManager>(
            builder: (context, bluetoothManager, child) {
              return Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '${bluetoothManager.discoveredPeers.length} peers',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          ),
          // Settings button
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      drawer: _buildPeerDrawer(),
      body: Column(
        children: [
          // Status bar - BitChat'teki network status
          _buildStatusBar(),
          
          // Messages list
          Expanded(
            child: Consumer<MeshNetworkManager>(
              builder: (context, meshManager, child) {
                final currentChannel = meshManager.currentChannel;
                final messages = currentChannel?.messages ?? [];
                
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(message: messages[index]);
                  },
                );
              },
            ),
          ),
          
          // Message input - BitChat'teki message input
          _buildMessageInput(),
        ],
      ),
    );
  }
  
  Widget _buildStatusBar() {
    return Consumer2<BluetoothManager, MeshNetworkManager>(
      builder: (context, bluetoothManager, meshManager, child) {
        final peersCount = bluetoothManager.discoveredPeers.length;
        final connectionsCount = bluetoothManager.activeConnections.length;
        final isScanning = bluetoothManager.isScanning;
        
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Colors.grey[800],
          child: Row(
            children: [
              Icon(
                isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                color: connectionsCount > 0 ? Colors.green : Colors.grey,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Peers: $peersCount | Connected: $connectionsCount',
                style: TextStyle(fontSize: 12, color: Colors.grey[300]),
              ),
              Spacer(),
              if (isScanning)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPeerDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MESHNET', style: TextStyle(color: Colors.white, fontSize: 24)),
                SizedBox(height: 8),
                Text('Emergency Mesh Network', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: PeerList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Row(
        children: [
          // Command button - BitChat'teki IRC-style commands
          IconButton(
            icon: Icon(Icons.code),
            onPressed: () => _showCommandsDialog(),
          ),
          
          // Message input field
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Send button
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final meshManager = context.read<MeshNetworkManager>();
    final bluetoothManager = context.read<BluetoothManager>();
    
    // Check for IRC-style commands - BitChat'teki command system
    if (text.startsWith('/')) {
      _handleCommand(text);
      return;
    }
    
    // Create message
    final message = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: meshManager.currentUserId,
      content: text,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
    
    // Add to current channel
    if (meshManager.currentChannel != null) {
      meshManager.addMessageToChannel(message, meshManager.currentChannel!.id);
    }
    
    // Broadcast to connected peers
    bluetoothManager.broadcastMessage(message);
    
    // Clear input
    _messageController.clear();
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
  
  void _handleCommand(String command) {
    final parts = command.split(' ');
    final cmd = parts[0].toLowerCase();
    final meshManager = context.read<MeshNetworkManager>();
    
    switch (cmd) {
      case '/j':
      case '/join':
        if (parts.length > 1) {
          final channelName = parts[1];
          final password = parts.length > 2 ? parts[2] : null;
          meshManager.joinChannel(channelName, password: password);
        }
        break;
        
      case '/w':
      case '/who':
        _showPeersList();
        break;
        
      case '/channels':
        _showChannelsList();
        break;
        
      case '/clear':
        // Clear current channel messages
        break;
        
      default:
        // Show unknown command error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown command: $cmd')),
        );
    }
    
    _messageController.clear();
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Emergency Wipe'),
              subtitle: Text('Clear all data and reset encryption'),
              trailing: Icon(Icons.warning, color: Colors.red),
              onTap: () {
                _encryptionService.emergencyWipe();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Emergency wipe completed')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showCommandsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Commands'),
        content: Text(
          '/j #channel [password] - Join channel\n'
          '/w - List online users\n'
          '/channels - Show all channels\n'
          '/clear - Clear messages\n'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showPeersList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Online Peers'),
        content: Consumer<BluetoothManager>(
          builder: (context, bluetoothManager, child) {
            final peers = bluetoothManager.discoveredPeers;
            return Container(
              width: 300,
              height: 200,
              child: ListView.builder(
                itemCount: peers.length,
                itemBuilder: (context, index) {
                  final peer = peers[index];
                  return ListTile(
                    title: Text(peer.name),
                    subtitle: Text(peer.id),
                    trailing: peer.isOnline() 
                        ? Icon(Icons.circle, color: Colors.green, size: 12)
                        : Icon(Icons.circle, color: Colors.grey, size: 12),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showChannelsList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Channels'),
        content: Consumer<MeshNetworkManager>(
          builder: (context, meshManager, child) {
            final channels = meshManager.channels;
            return Container(
              width: 300,
              height: 200,
              child: ListView.builder(
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  return ListTile(
                    title: Text(channel.name),
                    subtitle: Text('${channel.members.length} members'),
                    trailing: channel.isPasswordProtected 
                        ? Icon(Icons.lock, size: 16)
                        : null,
                    onTap: () {
                      // Switch to channel logic
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
