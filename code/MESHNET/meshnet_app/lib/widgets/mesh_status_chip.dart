// MeshStatusChip - Ağ bağlantı durumu göstergesi
import 'package:flutter/material.dart';

class MeshStatusChip extends StatelessWidget {
  final String status;
  final Color color;
  final IconData icon;
  final String? detail;

  const MeshStatusChip({
    Key? key,
    required this.status,
    required this.color,
    required this.icon,
    this.detail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: color, size: 20),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          if (detail != null)
            Text(detail!, style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
        ],
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: StadiumBorder(),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
