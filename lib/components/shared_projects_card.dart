import 'package:flutter/material.dart';

// 🔥 Shared Project Card
class SharedProjectCard extends StatefulWidget {
  final Map<String, dynamic> project;
  const SharedProjectCard({super.key, required this.project});

  @override
  State<SharedProjectCard> createState() => _SharedProjectCardState();
}

class _SharedProjectCardState extends State<SharedProjectCard> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

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

          // Owner (own row)
          Text(
            "Owner: ${project['owner'] ?? 'Unknown'}",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),

          // Date + Likes + Downloads row
          Row(
            children: [
              // Date
              Expanded(
                child: Text(
                  "Date Created: ${project['datecreated'] != null ? "${project['datecreated'].toDate().day.toString().padLeft(2, '0')}/${project['datecreated'].toDate().month.toString().padLeft(2, '0')}/${project['datecreated'].toDate().year}" : 'N/A'}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Likes
              GestureDetector(
                onTap: () {
                  setState(() {
                    isLiked = !isLiked;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isLiked ? Colors.red : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${project['likes'] ?? 0}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Downloads
              Row(
                children: [
                  const Icon(Icons.download_outlined,
                      size: 20, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    "${project['downloads'] ?? 0}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
