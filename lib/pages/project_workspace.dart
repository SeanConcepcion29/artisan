import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProjectWorkspacePage extends StatelessWidget {
  final String projectName;

  const ProjectWorkspacePage({super.key, required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F2A),
      body: SafeArea(
        child: Column(
          children: [
            // Top AppBar-like section
            Container(
              color: const Color(0xFF1E1F2A),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Project name with icon
                  Row(
                    children: [
                    SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 30,
                    ),
                      const SizedBox(width: 8),
                      Text(
                        projectName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Right: Action icons
                  Row(
                    children: const [
                      Icon(Icons.group, color: Colors.white),
                      SizedBox(width: 16),
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 16),
                      Icon(Icons.share, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),

            // Secondary Toolbar
            Container(
              color: const Color(0xFF2A2B38),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _toolbarButton("Select Tool"),
                  _toolbarButton("Inspect Tool"),
                  _toolbarButton("Delete"),
                  _toolbarButton("Add Note"),
                ],
              ),
            ),

            // Workspace area
            Expanded(
              child: Container(
                color: Colors.white,
                child: const Center(
                  child: Text(
                    "Workspace Area",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),

            // Bottom bar
            Container(
              color: const Color(0xFF1E1F2A),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left controls
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.history, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    ],
                  ),
                  // Right add button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2B38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toolbar button widget
  static Widget _toolbarButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
