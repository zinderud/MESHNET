// MessageBubble - Mesaj balonu widget'ı
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshnet_app/providers/settings_provider.dart';
import 'package:meshnet_app/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        final ui = provider.ui;
        final bubbleColor = isMe 
            ? Color(ui.primaryColor).withOpacity(0.2)
            : Colors.grey[200];
        final textColor = isMe 
            ? Color(ui.primaryColor)
            : Colors.black87;
        final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
        final borderRadius = _getBorderRadius(ui.messageBubbleStyle);
        
        return Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            crossAxisAlignment: align,
            children: [
              if (!isMe && ui.showAvatars)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(message.senderId.substring(0, 1).toUpperCase()),
                    ),
                    SizedBox(width: 8),
                    Text(
                      message.senderId,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              if (!isMe && !ui.showAvatars)
                Text(
                  message.senderId,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              SizedBox(height: 4),
              Material(
                color: bubbleColor,
                borderRadius: borderRadius,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: ui.fontSize,
                      color: textColor,
                      fontFamily: ui.fontFamily == 'System Default' ? null : ui.fontFamily,
                    ),
                  ),
                ),
              ),
              if (ui.showTimestamps)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimestamp(message.timestamp, ui.timeFormat),
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  BorderRadius _getBorderRadius(String style) {
    switch (style) {
      case 'Rounded':
        return BorderRadius.circular(16);
      case 'Square':
        return BorderRadius.circular(2);
      case 'Minimal':
        return BorderRadius.circular(4);
      case 'Outlined':
        return BorderRadius.circular(8);
      default:
        return BorderRadius.circular(8);
    }
  }

  String _formatTimestamp(DateTime timestamp, String timeFormat) {
    if (timeFormat == '24-hour') {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = timestamp.hour == 0 ? 12 : timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
      final period = timestamp.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${timestamp.minute.toString().padLeft(2, '0')} $period';
    }
  }
}
