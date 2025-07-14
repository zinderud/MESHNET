// lib/widgets/message_bubble.dart - BitChat'teki message display
import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  
  const MessageBubble({Key? key, required this.message}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isSystemMessage = message.type == MessageType.system;
    final isEmergencyMessage = message.type == MessageType.emergency;
    
    if (isSystemMessage) {
      return _buildSystemMessage();
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: _getAvatarColor(),
            child: Text(
              message.senderId.substring(0, 1).toUpperCase(),
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          
          SizedBox(width: 12),
          
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with sender and timestamp
                Row(
                  children: [
                    Text(
                      _getSenderDisplayName(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getSenderColor(),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatTimestamp(),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    if (message.hopCount > 0) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.alt_route,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      Text(
                        '${message.hopCount}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                
                SizedBox(height: 4),
                
                // Message content
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEmergencyMessage 
                        ? Colors.red[900] 
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: isEmergencyMessage 
                        ? Border.all(color: Colors.red, width: 2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEmergencyMessage)
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'EMERGENCY',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      
                      if (isEmergencyMessage) SizedBox(height: 4),
                      
                      Text(
                        message.content,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Route path indicator for multi-hop messages
                if (message.routePath.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Route: ${message.routePath.join(' → ')}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemMessage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: Colors.blue[100],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getAvatarColor() {
    // Generate consistent color based on sender ID
    final hash = message.senderId.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];
    return colors[hash.abs() % colors.length];
  }
  
  Color _getSenderColor() {
    return _getAvatarColor();
  }
  
  String _getSenderDisplayName() {
    // Extract display name from sender ID
    if (message.senderId.startsWith('user_')) {
      return 'User${message.senderId.substring(5, 9)}';
    }
    return message.senderId;
  }
  
  String _formatTimestamp() {
    final now = DateTime.now();
    final diff = now.difference(message.timestamp);
    
    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}
