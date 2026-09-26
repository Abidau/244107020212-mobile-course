import 'package:flutter/material.dart';
import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    this.onLongPress,
  });

  final Note note;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(note.body),
      trailing: note.dirty
          ? const Chip(
              avatar: Icon(Icons.cloud_off, size: 16),
              label: Text('belum tersinkron'),
            )
          : const Icon(Icons.cloud_done, size: 18, color: Colors.green),
      onLongPress: onLongPress,
    );
  }
}