import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final bool isEditMode;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ProjectCard({
    super.key,
    required this.project,
    this.isEditMode = false,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final title = project['title'] ?? "Untitled Project";

    String formatDate(dynamic ts) {
      if (ts == null) return "N/A";
      try {
        final date = ts.toDate();
        return "${date.day.toString().padLeft(2, '0')}/"
            "${date.month.toString().padLeft(2, '0')}/"
            "${date.year}";
      } catch (e) {
        return "N/A";
      }
    }

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
          // Title + Edit/Delete actions
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Dates + Solo/Group icon
          Row(
            children: [
              Expanded(
                child: Text(
                  "Last Modified: ${formatDate(project['datemodified'])}\n"
                  "Date Created: ${formatDate(project['datecreated'])}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (isEditMode) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ] else ...[
                Icon(
                project['solo'] == true
                    ? Icons.person_outline
                    : Icons.group_outlined,
                color: Colors.white70,
                size: 20,
              ),      
              ]


            ],
          ),
        ],
      ),
    );
  }
}
