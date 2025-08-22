import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String email;
  final String message;
  final bool opened;
  final DateTime date;

  const NotificationCard({
    Key? key,
    required this.email,
    required this.message,
    required this.opened,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              // Date
              Expanded(
                child: Text(
                  "$message",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ), 
              ),


          opened == false
              ? Icon(
                  Icons.circle,
                  color: Colors.red,
                  size: 16, // small red dot
                )
              : const SizedBox.shrink(), // show nothing

            ],
          ),

          Text( 
            "$email\n"
            "$date",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
              



        ],
      ),

    );
  }
}
