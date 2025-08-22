import 'package:artisan/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:artisan/services/firestore_user.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData; // contains firstname, lastname, etc.

  const ProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final firestoreUsers = FirestoreUsers();

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;

  @override
  void initState() {
    super.initState();
    firstNameController =
        TextEditingController(text: widget.userData['firstname']);
    lastNameController =
        TextEditingController(text: widget.userData['lastname']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232531), // dark background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView( // makes sure it won’t overflow on smaller screens
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // center vertically
                crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
                children: [
                  // Profile Icon
                  const Icon(
                    Icons.account_circle_outlined,
                    color: Colors.white,
                    size: 200,
                  ),

                  const SizedBox(height: 10),

                  // First & Last name display
                  Text(
                    "${widget.userData['firstname']} ${widget.userData['lastname']}",
                    style: const TextStyle(color: Colors.white, fontSize: 28),
                  ),
                  Text(
                    "${widget.userData['email']}",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),

                  const SizedBox(height: 40),

                  // First name input
                  TextField(
                    controller: firstNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "First Name",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Last name input
                  TextField(
                    controller: lastNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Last Name",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Change name button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        await firestoreUsers.updateName(
                          widget.userData['email'], // 🔑 using email as identifier
                          firstNameController.text,
                          lastNameController.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Name updated! Changes will appear on restart.")),
                        );
                      },
                      child: const Text("CHANGE NAME",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // go back
                      },
                      child: const Text("BACK",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Delete account button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        final firestoreUsers = FirestoreUsers();
                        await firestoreUsers.deleteUser(widget.userData['email']);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LogInPage(),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Account deleted")),
                        );
                      },
                      child: const Text("DELETE ACCOUNT",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
