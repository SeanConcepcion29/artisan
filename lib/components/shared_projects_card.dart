import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SharedProjectCard extends StatefulWidget {
  final String projectId;   
  final String userEmail;   
  final Map<String, dynamic> project; 

  const SharedProjectCard({
    super.key,
    required this.projectId,
    required this.userEmail,
    required this.project,
  });

  @override
  State<SharedProjectCard> createState() => _SharedProjectCardState();
}


class _SharedProjectCardState extends State<SharedProjectCard> {

  /* FUNCTION that allows user to toggle like/unlike */
  Future<void> toggleLike(bool isLiked, Map<String, dynamic> project) async {
    final projectRef = FirebaseFirestore.instance.collection('projects').doc(widget.projectId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(projectRef);

      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final currentLikes = data['likes'] ?? 0;

      /* allows user to unlike the project */
      if (isLiked) {
        likedBy.remove(widget.userEmail);
        transaction.update(projectRef, {
          'likes': currentLikes - 1,
          'likedBy': likedBy,
        });
      }
      
      /* allows user to like the project */
      else {
        if (!likedBy.contains(widget.userEmail)) {
          likedBy.add(widget.userEmail);
          transaction.update(projectRef, {
            'likes': currentLikes + 1,
            'likedBy': likedBy,
          });
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final projectRef = FirebaseFirestore.instance.collection('projects').doc(widget.projectId);

    return StreamBuilder<DocumentSnapshot>(
      stream: projectRef.snapshots(),
      builder: (context, snapshot) {

        /* ensures the projects are loaded properly */
        if (!snapshot.hasData) { return const Center(child: CircularProgressIndicator()); }

        /* stores project and like states */
        final project = snapshot.data!.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(project['likedBy'] ?? []);
        final isLiked = likedBy.contains(widget.userEmail);

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

              /*** PROJECT TITLE ***/
              Text(
                project['title'] ?? "Untitled Project",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Row(
                children: [

                  /*** PROJECT DETAILS ***/
                  Expanded(
                    child: Text(
                      "Owner: ${project['owner'] ?? 'Unknown'}\n"
                      "Date Created: ${project['datecreated'] != null ? "${project['datecreated'].toDate().day.toString().padLeft(2, '0')}/${project['datecreated'].toDate().month.toString().padLeft(2, '0')}/${project['datecreated'].toDate().year}" : 'N/A'}",
                      style: const TextStyle( color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  /*** LIKES COUNTER ***/
                  GestureDetector(
                    onTap: () => toggleLike(isLiked, project),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isLiked ? Colors.red : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text("${project['likes'] ?? 0}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  /*** DOWNLOADS COUNTER ***/
                  Row(
                    children: [
                      const Icon(Icons.download_outlined, size: 20, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text("${project['downloads'] ?? 0}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
