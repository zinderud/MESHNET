// PeerListWidget - Ağdaki peer'ları gösteren liste
import 'package:flutter/material.dart';

class PeerListWidget extends StatelessWidget {
  final List<String> peers;
  final void Function(String)? onTap;

  const PeerListWidget({
    Key? key,
    required this.peers,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (peers.isEmpty) {
      return Center(child: Text('Bağlı peer yok', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      itemCount: peers.length,
      separatorBuilder: (_, __) => Divider(height: 1),
      itemBuilder: (context, index) {
        final peer = peers[index];
        return ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text(peer),
          onTap: onTap != null ? () => onTap!(peer) : null,
        );
      },
    );
  }
}
