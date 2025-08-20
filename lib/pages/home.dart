import 'package:flutter/material.dart';
import 'package:artisan/services/firestore_user.dart';
import 'package:artisan/services/firestore_project.dart';
import 'package:artisan/components/shared_projects_card.dart';
import 'package:artisan/components/project_card.dart';
import 'package:artisan/components/guide_tab.dart';

class HomePage extends StatefulWidget {
  final String userEmail;

  const HomePage({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final firestoreUsers = FirestoreUsers();
  final firestoreProjects = FirestoreProjects();

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userProjects = [];
  List<Map<String, dynamic>> sharedProjects = [];

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

      // Also fetch shared/public projects
      final allShared = await firestoreProjects.getAllPublicProjects();

      setState(() {
        userData = data;
        userProjects = projects;
        sharedProjects = allShared;
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

    if (index == 3) {
      // Generate a dummy project ID
      final dummyId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a dummy project in Firestore
      await firestoreProjects.createProject(
        email: widget.userEmail,
        owner: userData?['firstname'] ?? 'Unknown Owner',
        projectId: dummyId,
        title: 'Dummy Project $dummyId',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        public: true,
        solo: true,
        collabs: [],
        downloads: 0,
        likes: 0,
      );

      // Refresh project list
      await fetchUserAndProjects();
    }
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
                children: const [
                  Icon(Icons.hexagon_outlined, color: Colors.white, size: 28),
                  Text(
                    "ARTISAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 16,
                    ),
                  ),
                  Icon(Icons.person_outline, color: Colors.white, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main content per tab
            Expanded(
              child: _selectedIndex == 2
                  ? const GuidePage() // Guide Page
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: projectsToShow.length,
                      itemBuilder: (context, index) {
                        final project = projectsToShow[index];

                        // Shared page card
                        if (_selectedIndex == 1) {
                          return SharedProjectCard(project: project);
                        }

                        // Projects page card
                        return ProjectCard(project: project);
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
