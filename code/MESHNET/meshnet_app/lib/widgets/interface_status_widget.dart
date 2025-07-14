// lib/widgets/interface_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/interface_manager.dart';

class InterfaceStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<InterfaceManager>(
      builder: (context, interfaces, child) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.device_hub, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Interfaces',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('Active Interfaces: ${interfaces.activeInterfaces.length}'),
                ...interfaces.activeInterfaces.map((interface) => 
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: interface.isActive ? Colors.green : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text('${interface.name} (${interface.type.name})'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
