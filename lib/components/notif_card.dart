import 'package:flutter/material.dart';
import 'package:artisan/pages/project_workspace.dart';
import 'package:artisan/services/firestore_notif.dart';

class NotificationCard extends StatelessWidget {
  final String id; 
  final String email;
  final String message;
  final String projectId;
  final String projectName;
  final String userEmail;
  final bool opened;
  final DateTime date;

  const NotificationCard({
    Key? key,
    required this.id, 
    required this.email,
    required this.message,
    required this.projectId,
    required this.projectName,
    required this.userEmail,
    required this.opened,
    required this.date,
  }) : super(key: key);


  /* FUNCTION that reformats the date into dd/mm/yyyy hh:mm AM/PM */
  String formatDate(DateTime ts) {
    final day = ts.day.toString().padLeft(2, '0');
    final month = ts.month.toString().padLeft(2, '0');
    final year = ts.year;

    int hour = ts.hour;
    final minute = ts.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? "PM" : "AM";

    if (hour == 0) { hour = 12; }
    else if (hour > 12) { hour -= 12; }

    return "$day/$month/$year  $hour:$minute $ampm";
  }


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {

        if (!opened) {
          await FirestoreNotifications().markAsOpened(id);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectWorkspacePage(
              projectName: projectName,
              projectId: projectId,
              currentUserEmail: userEmail,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [

                /*** NOTIFICATION MESSAGE ***/
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                /*** OPENED PROMPT ***/
                opened == false ? const Icon(Icons.circle, color: Colors.red, size: 16) : const SizedBox.shrink(),
              ],
            ),

            /*** NOTIFICATION DETAILS ***/
            Text(
              "$email\n${formatDate(date)}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
