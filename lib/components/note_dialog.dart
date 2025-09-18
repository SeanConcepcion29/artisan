import 'package:flutter/material.dart';
import 'package:artisan/services/firestore_notif.dart';


class NoteDialog extends StatefulWidget {
  final String initialTitle;
  final String initialMessage;
  final Map<String, dynamic> projectData;
  final String projectId;
  final String currentUserEmail;
  final FirestoreNotifications firestoreNotifications;

  const NoteDialog({
    super.key,
    required this.initialTitle,
    required this.initialMessage,
    required this.projectData,
    required this.projectId,
    required this.currentUserEmail,
    required this.firestoreNotifications,
  });

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}


class _NoteDialogState extends State<NoteDialog> {
  late String _title;
  late String _message;
  bool _isEditing = false;

  /* handles the text field for ntoe title and message */
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

      /* prompts a text field for the title if user is in mode; otherwise, show the title */
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

      /* prompts a text field for the message if user is in mode; otherwise, show the message */
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
            onPressed: () async {

              /* stores title and message of note */
              final title = _titleController.text.trim();
              final message = _messageController.text.trim();

              if (title.isNotEmpty && message.isNotEmpty) {
                setState(() {
                  _title = title;
                  _message = message;
                  _isEditing = false;
                });
              }
            },
            child: const Text("Save", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
          ),


        /*** CANCEL/EDIT BUTTON ***/
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        /*** CLOSE BUTTON ***/
        TextButton(
          onPressed: () { Navigator.pop(context, {'title': _title, 'message': _message}); },
          child: const Text(
            "Close",
            style: TextStyle(
              color: Color.fromARGB(255, 34, 36, 49),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
