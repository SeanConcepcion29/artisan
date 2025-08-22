import 'package:artisan/components/notif_card.dart';
import 'package:artisan/pages/profile.dart';
import 'package:artisan/pages/project_workspace.dart';
import 'package:artisan/services/firestore_notif.dart';
import 'package:flutter/material.dart';
import 'package:artisan/services/firestore_user.dart';
import 'package:artisan/services/firestore_project.dart';
import 'package:artisan/components/shared_projects_card.dart';
import 'package:artisan/components/project_card.dart';
import 'package:artisan/components/guide_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class HomePage extends StatefulWidget {
  final String userEmail;

  const HomePage({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final firestoreUsers = FirestoreUsers();
  final firestoreProjects = FirestoreProjects();
  final firestoreNotifications = FirestoreNotifications();


  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userProjects = [];
  List<Map<String, dynamic>> sharedProjects = [];
  List<Map<String, dynamic>> userNotifications = [];


  bool isLoading = true;
  int _selectedIndex = 0; // Track selected tab

  @override
  void initState() {
    super.initState();
    fetchUserAndProjects();
  }

  Future<void> fetchUserAndProjects() async {
    final data = await firestoreUsers.getUserByEmail(widget.userEmail);

    if (data != null) {
      final projects =
          await firestoreProjects.getAllProjectsByEmail(widget.userEmail);

      final allShared = await firestoreProjects.getAllPublicProjects();

      // ✅ Fetch notifications from Firestore collection
      final notifications =
          await firestoreNotifications.getNotificationsByEmail(widget.userEmail);

      setState(() {
        userData = data;
        userProjects = projects;
        sharedProjects = allShared;
        userNotifications = notifications; // not from user doc
        isLoading = false;
      });
    } else {
      setState(() {
        userData = null;
        isLoading = false;
      });
    }
  }



  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1F2A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (userData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1F2A),
        body: Center(
          child: Text("User not found", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // Pick which projects to show
    final projectsToShow =
        _selectedIndex == 0 ? userProjects : _selectedIndex == 1 ? sharedProjects : [];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1F2A),
      body: SafeArea(
        child: Column(
          children: [

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left icon clickable
                  InkWell(
                    onTap: () {
                      print("Left icon clicked");
                    },
                    child: const Icon(Icons.hexagon_outlined, color: Colors.white, size: 28),
                  ),

                  // Title
                  const Text(
                    "ARTISAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 16,
                    ),
                  ),

                  // Right icon clickable
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(userData: userData!),
                        ),
                      );
                    },
                    child: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 28),
                  ),

                ],
              ),
            ),

            
            const SizedBox(height: 20),

            // Main content per tab
            Expanded(
              child: _selectedIndex == 2
                  ? const GuidePage()
                  : _selectedIndex == 3
                      // ✅ Live Notifications tab
                      ? StreamBuilder<QuerySnapshot>(
                          stream: firestoreNotifications.notifications
                              .where('email', isEqualTo: widget.userEmail)
                              .orderBy('date', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(color: Colors.white));
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text("No notifications",
                                    style: TextStyle(color: Colors.white70)),
                              );
                            }

                            final notifs = snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return {
                                "email": data['email'] ?? "Unknown",
                                "message": data['message'] ?? "",
                                "opened": data['opened'] ?? false,
                                "date": (data['date'] as Timestamp).toDate(),
                              };
                            }).toList();

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: notifs.length,
                              itemBuilder: (context, index) {
                                final notif = notifs[index];
                                return NotificationCard(
                                  email: notif['email'],
                                  message: notif['message'],
                                  opened: notif['opened'],
                                  date: notif['date'],
                                );
                              },
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: projectsToShow.length,
                          itemBuilder: (context, index) {
                            final project = projectsToShow[index];
                            final projectName = project['title'] ?? "Untitled Project";

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProjectWorkspacePage(projectName: projectName),
                                  ),
                                );
                              },
                              child: _selectedIndex == 1
                                  ? SharedProjectCard(
                                      projectId: project['id'],   // 👈 make sure `id` exists in project map
                                      userEmail: userData!['email'],
                                      project: project,
                                    )
                                  : ProjectCard(project: project),
                            );
                          },
                        ),
            ),


          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1F2A),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_shared_outlined),
            label: 'Shared',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Guide',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifs',
          ),
        ],
      ),
    );
  }
}
