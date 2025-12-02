import 'package:flutter/material.dart';
import 'package:artisan/services/firestore_user.dart';
import 'home.dart';


class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}


class _SignUpPageState extends State<SignUpPage> {
  final firestoreUsers = FirestoreUsers();

  /* handles the text field for email, password, and name */
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();


  String? errorMessage;
  bool isLoading = false;


  /* FUNCTION that signs up the user */
  Future<void> signUp() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      setState(() => errorMessage = "Please fill all fields");
      return;
    }

    if (password != confirmPassword) {
      setState(() => errorMessage = "Password mismatch");
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

      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(userEmail: email)));

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

            /*** WELCOME TITLE ***/
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Welcome,\nNew User!",
                style: TextStyle(
                  fontSize: 26,
                  letterSpacing: 4,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 100),


            /*** FIRST NAME TEXT FIELD ***/
            TextField(
              controller: firstNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "First Name",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.person_outline, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),


            /*** LAST NAME TEXT FIELD ***/
            TextField(
              controller: lastNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Last Name",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.person, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),


            /*** LAST NAME TEXT FIELD ***/
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.email_outlined, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),


            /*** PASSWORD TEXT FIELD ***/
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Password",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),


            /*** CONFIRM PASSWORD TEXT FIELD ***/
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Confirm Password",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),


            /*** ERROR MESSAGE & SIGN UP BUTTON***/
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                /*** ERROR MESSAGE ***/
                Expanded(
                  child: errorMessage != null
                      ? Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox(),
                ),

                /*** SIGN UP BUTTON ***/
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isLoading ? null : signUp,
                    child: isLoading
                        ? const SizedBox( height: 18, width: 36, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("SIGN UP", style: TextStyle(fontWeight: FontWeight.bold)),
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