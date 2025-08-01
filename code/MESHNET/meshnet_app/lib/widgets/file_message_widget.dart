// FileMessageWidget - Dosya mesajı gösterimi
import 'package:flutter/material.dart';

class FileMessageWidget extends StatelessWidget {
  final String fileName;
  final int fileSize;
  final VoidCallback? onDownload;

  const FileMessageWidget({
    Key? key,
    required this.fileName,
    required this.fileSize,
    this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Icon(Icons.attach_file, color: Colors.blue),
        title: Text(fileName),
        subtitle: Text('${(fileSize / 1024).toStringAsFixed(1)} KB'),
        trailing: IconButton(
          icon: Icon(Icons.download, color: Colors.green),
          onPressed: onDownload,
        ),
      ),
    );
  }
}
