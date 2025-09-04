import 'package:flutter/material.dart';

class NoteDialog extends StatefulWidget {
  final String initialTitle;
  final String initialMessage;

  const NoteDialog({
    super.key,
    required this.initialTitle,
    required this.initialMessage,
  });

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late String _title;
  late String _message;
  bool _isEditing = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _message = widget.initialMessage;
    _titleController.text = _title;
    _messageController.text = _message;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _isEditing
          ? TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Enter note title",
                border: InputBorder.none,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          : Text(_title, style: const TextStyle(fontWeight: FontWeight.bold)),

      content: _isEditing
          ? TextField(
              controller: _messageController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Enter note message",
                border: InputBorder.none,
              ),
            )
          : SingleChildScrollView(child: Text(_message)),

      actions: [
        if (_isEditing)
          TextButton(
            onPressed: () {
              setState(() {
                _title = _titleController.text;
                _message = _messageController.text;
                _isEditing = false;
              });
            },
            child: const Text(
              "Save",
              style: TextStyle(
                  color: Color.fromARGB(255, 34, 36, 49),
                  fontWeight: FontWeight.bold),
            ),
          ),

        TextButton(
          onPressed: () {
            setState(() {
              if (_isEditing) {
                _titleController.text = _title;
                _messageController.text = _message;
              }
              _isEditing = !_isEditing;
            });
          },
          child: Text(
            _isEditing ? "Cancel" : "Edit",
            style: const TextStyle(
                color: Color.fromARGB(255, 34, 36, 49),
                fontWeight: FontWeight.bold),
          ),
        ),

        TextButton(
          onPressed: () {
            Navigator.pop(context, {'title': _title, 'message': _message});
          },
          child: const Text(
            "Close",
            style: TextStyle(
                color: Color.fromARGB(255, 34, 36, 49),
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
