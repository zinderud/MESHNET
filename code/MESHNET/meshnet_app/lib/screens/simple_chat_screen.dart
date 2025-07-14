// lib/screens/simple_chat_screen.dart - Basit Chat Ekranı
import 'package:flutter/material.dart';

class SimpleChatScreen extends StatefulWidget {
  @override
  _SimpleChatScreenState createState() => _SimpleChatScreenState();
}

class _SimpleChatScreenState extends State<SimpleChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MESHNET Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            color: Colors.green,
            child: Text(
              'Ready to send messages',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Message list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_messages[index]),
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
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add('You: $message');
      });
      _messageController.clear();
      
      // Auto scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Simulate a response after 1 second
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _messages.add('MESHNET: Message received and broadcasted');
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
