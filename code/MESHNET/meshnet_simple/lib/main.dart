import 'package:flutter/material.dart';

void main() {
  runApp(MeshNetApp());
}

class MeshNetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MESHNET',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MESHNET Emergency Chat'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            color: Colors.green.shade700,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'MESH Network Active - ${_messages.length} messages',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Emergency info banner
          if (_messages.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.orange.shade100,
              child: Column(
                children: [
                  Icon(Icons.emergency, color: Colors.orange.shade700, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'ACIL DURUM MESH NETWORK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'İnternet olmadan mesajlaşma sistemi',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          
          // Message list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isFromMe ? Colors.blue.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: message.isFromMe ? Colors.blue.shade300 : Colors.grey.shade400,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            message.isFromMe ? Icons.person : Icons.group,
                            size: 16,
                            color: message.isFromMe ? Colors.blue.shade700 : Colors.grey.shade600,
                          ),
                          SizedBox(width: 4),
                          Text(
                            message.sender,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: message.isFromMe ? Colors.blue.shade700 : Colors.grey.shade700,
                            ),
                          ),
                          Spacer(),
                          Text(
                            _formatTime(message.time),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        message.text,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Message input
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Acil durum mesajı yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  mini: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          sender: 'Siz',
          time: DateTime.now(),
          isFromMe: true,
        ));
      });
      _messageController.clear();
      
      // Simulate network response
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: 'Mesaj MESH ağ üzerinden ${(_messages.length * 2 + 1)} kişiye ulaştı',
              sender: 'MESHNET Sistem',
              time: DateTime.now(),
              isFromMe: false,
            ));
          });
        }
      });
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final String sender;
  final DateTime time;
  final bool isFromMe;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.time,
    required this.isFromMe,
  });
}
