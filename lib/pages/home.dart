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

  const HomePage({super.key, required this.userEmail});

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
  int _selectedIndex = 0;

  // ✅ Track edit mode
  bool _isEditMode = false;

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
      final notifications =
          await firestoreNotifications.getNotificationsByEmail(widget.userEmail);

      setState(() {
        userData = data;
        userProjects = projects;
        sharedProjects = allShared;
        userNotifications = notifications;
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

  Future<void> _deleteProject(String projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Project", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to delete this project?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await firestoreProjects.deleteProject(projectId);
      fetchUserAndProjects();
    }
  }


  void _showRenameDialog(String projectId, String oldTitle) {
    final controller = TextEditingController(text: oldTitle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Project", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await firestoreProjects.updateProjectTitle(projectId, newName);
                fetchUserAndProjects();
                Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

    final projectsToShow =
        _selectedIndex == 0 ? userProjects : _selectedIndex == 1 ? sharedProjects : [];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1F2A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 👇 Gear icon toggles edit mode only in Projects tab
                  InkWell(
                    onTap: () {
                      if (_selectedIndex == 0) {
                        setState(() {
                          _isEditMode = !_isEditMode;
                        });
                      }
                    },
                    child: Icon(
                      _isEditMode && _selectedIndex == 0
                          ? Icons.settings
                          : Icons.settings_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const Text(
                    "ARTISAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 16,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfilePage(userData: userData!),
                        ),
                      );
                    },
                    child: const Icon(Icons.account_circle_outlined,
                        color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _selectedIndex == 2
                  ? const GuidePage()
                  : _selectedIndex == 3
                      ? StreamBuilder<QuerySnapshot>(
                          stream: firestoreNotifications.notifications
                              .where('email', isEqualTo: widget.userEmail)
                              .orderBy('date', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white));
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text("No notifications",
                                    style: TextStyle(color: Colors.white70)),
                              );
                            }

                            final notifs = snapshot.data!.docs.map((doc) {
                              final data =
                                  doc.data() as Map<String, dynamic>;
                              return {
                                "email": data['email'] ?? "Unknown",
                                "message": data['message'] ?? "",
                                "opened": data['opened'] ?? false,
                                "date":
                                    (data['date'] as Timestamp).toDate(),
                              };
                            }).toList();

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0),
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
                          itemCount: _selectedIndex == 1
                              ? projectsToShow.length
                              : projectsToShow.length + 1,
                          itemBuilder: (context, index) {
                            if (_selectedIndex != 1 &&
                                index == projectsToShow.length) {
                              // 👇 Last card: Create New Project
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        final TextEditingController
                                            nameController =
                                            TextEditingController();
                                        final formKey =
                                            GlobalKey<FormState>();

                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12)),
                                          title: const Text(
                                              "Create New Project", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
                                          content: Form(
                                            key: formKey,
                                            child: TextFormField(
                                              controller: nameController,
                                              decoration:
                                                  const InputDecoration(
                                                labelText: "Project Name",
                                                border:
                                                    OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return "Project name is required";
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context),
                                              child:
                                                  const Text("Cancel", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                if (formKey.currentState!
                                                    .validate()) {
                                                  final newProjectId =
                                                      FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              'projects')
                                                          .doc()
                                                          .id;
                                                  final now =
                                                      DateTime.now();

                                                  await firestoreProjects
                                                      .createProject(
                                                    email: userData![
                                                        'email'],
                                                    owner: userData![
                                                        'email'],
                                                    projectId:
                                                        newProjectId,
                                                    title: nameController
                                                        .text
                                                        .trim(),
                                                    dateCreated: now,
                                                    dateModified: now,
                                                    public: false,
                                                    solo: true,
                                                    collabs: [],
                                                    downloads: 0,
                                                    likes: 0,
                                                  );

                                                  fetchUserAndProjects();
                                                  Navigator.pop(context);
                                                }
                                              },
                                              child:
                                                  const Text("Create", style: TextStyle(color: Color.fromARGB(255, 34, 36, 49), fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add,
                                            size: 28,
                                            color: Color(0xFF1E1F2A)),
                                        SizedBox(width: 8),
                                        Text(
                                          "Create New Project",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E1F2A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            // 👇 Normal project cards
                            final project = projectsToShow[index];
                            final projectName =
                                project['title'] ?? "Untitled Project";
                            final projectId =
                                project['id'] ?? "unknown_id";

                            return InkWell(
                              onTap: () {
                                if (_isEditMode) return; // disable open
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProjectWorkspacePage(
                                      projectName: projectName,
                                      projectId: projectId,
                                    ),
                                  ),
                                );
                              },
                              child: _selectedIndex == 1
                                  ? SharedProjectCard(
                                      projectId: project['id'],
                                      userEmail: userData!['email'],
                                      project: project,
                                    )
                                  : ProjectCard(
                                      project: project,
                                      isEditMode: _isEditMode,
                                      onEdit: () => _showRenameDialog(
                                          projectId, projectName),
                                      onDelete: () =>
                                          _deleteProject(projectId),
                                    ),
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
