import 'package:flutter/material.dart';
import 'package:artisan/services/firestore_user.dart';
import 'package:artisan/services/firestore_project.dart';

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
      final projects = await firestoreProjects.getAllProjectsByEmail(widget.userEmail);

      setState(() {
        userData = data;
        userProjects = projects;
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

    return Scaffold(
      backgroundColor: const Color(0xFF1E1F2A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.hexagon_outlined, color: Colors.white, size: 28),
                  Text(
                    "ARTISAN",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 16,
                    ),
                  ),
                  const Icon(Icons.person_outline, color: Colors.white, size: 28),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: userProjects.length,
                itemBuilder: (context, index) {
                  final project = userProjects[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),

                    child: ListTile(
                      title: Text(
                        project['title'] ?? "Untitled Project",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        "Last Modified: ${project['datemodified'] != null
                            ? "${project['datemodified'].toDate().day.toString().padLeft(2, '0')}/${project['datemodified'].toDate().month.toString().padLeft(2, '0')}/${project['datemodified'].toDate().year}"
                            : 'N/A'}\n"
                        "Date Created: ${project['datecreated'] != null
                            ? "${project['datecreated'].toDate().day.toString().padLeft(2, '0')}/${project['datecreated'].toDate().month.toString().padLeft(2, '0')}/${project['datecreated'].toDate().year}"
                            : 'N/A'}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),

                      
                      trailing: const Icon(Icons.person_outline, color: Colors.white),
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

