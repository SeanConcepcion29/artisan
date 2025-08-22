import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  const ProjectCard({super.key, required this.project});

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
          // Title
          Text(
            project['title'] ?? "Untitled Project",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Date + Likes + Downloads row
          Row(
            children: [
              // Date
              Expanded(
                child: Text( 
                  "Last Modified: ${project['datemodified'] != null ? "${project['datemodified'].toDate().day.toString().padLeft(2, '0')}/${project['datemodified'].toDate().month.toString().padLeft(2, '0')}/${project['datemodified'].toDate().year}" : 'N/A'}\n"
                  "Date Created: ${project['datecreated'] != null ? "${project['datecreated'].toDate().day.toString().padLeft(2, '0')}/${project['datecreated'].toDate().month.toString().padLeft(2, '0')}/${project['datecreated'].toDate().year}" : 'N/A'}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Icon(
                project['solo'] == true 
                    ? Icons.person_outline 
                    : Icons.group_outlined,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ],
      ),

    );
  }
}
