// EmergencyButton - Acil durum butonu
import 'package:flutter/material.dart';

class EmergencyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool active;

  const EmergencyButton({
    Key? key,
    this.onPressed,
    this.active = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.sos, color: Colors.white),
      label: Text(active ? 'Acil Durum Aktif' : 'Acil Durum', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Colors.red : Colors.orange,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: StadiumBorder(),
        elevation: 4,
      ),
      onPressed: onPressed,
    );
  }
}
