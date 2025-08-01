// lib/screens/chat_screen.dart - Bluetooth Mesh Chat Ekranı
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshnet_app/widgets/message_bubble.dart';
import 'package:meshnet_app/models/chat_message.dart';
import '../services/bluetooth_mesh_manager.dart';
import '../services/location_manager.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  BluetoothMeshManager? _meshManager;

  @override
  void initState() {
    super.initState();
    _initializeMeshNetwork();
  }

  Future<void> _initializeMeshNetwork() async {
    final meshManager = Provider.of<BluetoothMeshManager>(context, listen: false);
    final locationManager = Provider.of<LocationManager>(context, listen: false);
    
    _meshManager = meshManager;
    
    final initialized = await _meshManager!.initialize();
    if (initialized) {
      await _meshManager!.startScanning();
      
      // Listen for changes in mesh network
      _meshManager!.addListener(_onMeshNetworkChanged);
      
      setState(() {
        _messages.add(ChatMessage.simple(
          content: 'MESHNET başlatıldı. Node ID: ${_meshManager!.nodeId}',
          isSystem: true,
          timestamp: DateTime.now(),
        ));
      });
    } else {
      setState(() {
        _messages.add(ChatMessage.simple(
          content: 'MESHNET başlatılamadı. Bluetooth izinlerini kontrol edin.',
          isSystem: true,
          isError: true,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  void _onMeshNetworkChanged() {
    // This will be called when new messages arrive or network state changes
    setState(() {
      // UI will rebuild to show network status changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MESHNET Chat'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Network status indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _getNetworkStatusColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _meshManager?.encryptionEnabled == true ? Icons.lock : Icons.lock_open,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  '${_meshManager?.connectedDevices.length ?? 0} peers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Network status bar
          _buildNetworkStatusBar(),
          
          // Message list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message,
                  isMe: message.isOwn,
                );
              },
            ),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
      drawer: _buildNetworkDrawer(),
    );
  }

  Widget _buildNetworkStatusBar() {
    if (_meshManager == null) return SizedBox.shrink();
    
    final connectedCount = _meshManager!.connectedDevices.length;
    final isScanning = _meshManager!.isScanning;
    
    Color statusColor = connectedCount > 0 ? Colors.green.shade700 : 
                       isScanning ? Colors.orange.shade700 : Colors.red.shade700;
    String statusText = connectedCount > 0 
        ? '$connectedCount cihaza bağlı${_meshManager?.encryptionEnabled == true ? ' 🔐' : ''}'
        : isScanning 
            ? 'Cihaz aranıyor...'
            : 'Bağlantı yok';
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: statusColor,
      child: Row(
        children: [
          if (isScanning)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          if (isScanning) SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Text(
            'Node: ${_meshManager!.nodeId.substring(0, 8)}...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isOwn 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isOwn && !message.isSystem) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, size: 16, color: Colors.blue.shade700),
            ),
            SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.isSystem 
                    ? (message.isError ? Colors.red.shade100 : Colors.grey.shade200)
                    : message.isOwn 
                        ? Colors.blue.shade500 
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isOwn && !message.isSystem && message.senderName != null)
                    Text(
                      message.senderName!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isSystem 
                          ? (message.isError ? Colors.red.shade700 : Colors.grey.shade700)
                          : message.isOwn 
                              ? Colors.white 
                              : Colors.black87,
                      fontSize: message.isSystem ? 12 : 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isSystem 
                          ? Colors.grey.shade600
                          : message.isOwn 
                              ? Colors.white70 
                              : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isOwn) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade500,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // GPS location share button
          IconButton(
            onPressed: _shareCurrentLocation,
            icon: Icon(Icons.my_location),
            color: Colors.blue.shade600,
            tooltip: 'Konumu paylaş',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Mesaj yazın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _sendMessage,
            backgroundColor: Colors.blue.shade500,
            child: Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MESHNET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Mesh Ağ Durumu',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Node ID: ${_meshManager?.nodeId.substring(0, 12) ?? 'Bilinmiyor'}...',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _meshManager?.encryptionEnabled == true ? Icons.lock : Icons.lock_open,
                      color: Colors.white60,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'E2E Encryption: ${_meshManager?.encryptionEnabled == true ? 'ON' : 'OFF'}',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Bağlı Cihazlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          Expanded(
            child: _meshManager == null 
                ? Center(child: Text('Ağ başlatılıyor...'))
                : _meshManager!.connectedDevices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_searching, 
                                 size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Henüz bağlı cihaz yok'),
                            SizedBox(height: 8),
                            Text(
                              'Diğer MESHNET cihazları aranıyor...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _meshManager!.connectedDevices.length,
                        itemBuilder: (context, index) {
                          final device = _meshManager!.connectedDevices[index];
                          final isEncrypted = _meshManager!.isPeerEncrypted(device.remoteId);
                          return ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bluetooth_connected, color: Colors.green),
                                SizedBox(width: 4),
                                Icon(
                                  isEncrypted ? Icons.lock : Icons.lock_open,
                                  color: isEncrypted ? Colors.green : Colors.orange,
                                  size: 16,
                                ),
                              ],
                            ),
                            title: Text(device.platformName.isNotEmpty 
                                       ? device.platformName 
                                       : 'Bilinmeyen Cihaz'),
                            subtitle: Text(device.remoteId.toString()),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isEncrypted ? Colors.green.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isEncrypted ? 'Encrypted' : 'Plain',
                                style: TextStyle(
                                  color: isEncrypted ? Colors.green.shade700 : Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getNetworkStatusColor() {
    if (_meshManager == null) return Colors.grey;
    return _meshManager!.connectedDevices.length > 0 
        ? Colors.green 
        : _meshManager!.isScanning 
            ? Colors.orange 
            : Colors.red;
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _meshManager == null) return;

    // Add own message to UI immediately
    setState(() {
      _messages.add(ChatMessage.simple(
        content: content,
        isOwn: true,
        timestamp: DateTime.now(),
      ));
    });

    // Send via mesh network
    try {
      await _meshManager!.sendChatMessage.simple(content);
      _messageController.clear();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage.simple(
          content: 'Mesaj gönderilemedi: $e',
          isSystem: true,
          isError: true,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  void _shareCurrentLocation() async {
    try {
      if (_meshManager == null) return;
      
      // Check if location is available
      final locationManager = _meshManager!.locationManager;
      
      if (!locationManager.locationEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Konum servisleri kapalı'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      if (!locationManager.permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Konum izni gerekli'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Send location update
      await _meshManager!.sendLocationUpdate(
        message: 'Mevcut konumum paylaşıldı',
      );
      
      // Add location message to chat
      setState(() {
        _messages.add(ChatMessage.simple(
          content: '📍 Konum paylaşıldı',
          isOwn: true,
          timestamp: DateTime.now(),
        ));
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Konumunuz mesh ağa paylaşıldı'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Konum paylaşılamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _meshManager?.removeListener(_onMeshNetworkChanged);
    _meshManager?.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
