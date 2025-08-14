import 'package:flutter/material.dart';
import 'package:artisan/services/firestore_user.dart';
import 'home.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final firestoreUsers = FirestoreUsers();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  Future<void> signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      setState(() => errorMessage = "Please fill all fields");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await firestoreUsers.createUser(
        email: email,
        firstname: firstName,
        lastname: lastName,
        password: password,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userEmail: email)),
      );
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 36, 49),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome, New User!",
              style: TextStyle(
                fontSize: 26,
                letterSpacing: 3,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 100),

            // Name
            TextField(
              controller: firstNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "First Name",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.person_outline, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: lastNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Last Name",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.person, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),


            // Email
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.email_outlined, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Password",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Error + Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: errorMessage != null
                      ? Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox(),
                ),
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading ? null : signUp,
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 36,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "SIGN UP",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
