
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUsers {

  // GET
  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  // CREATE
  Future<void> createUser({
    required String email,
    required String firstname,
    required String lastname,
    required String password,
  }) async {
    await users.add({
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'notifications': [],
      'password': password,
      'projects': [],
    });
  }

  // READ
  Stream<QuerySnapshot> getUsersStream() {
    final usersStream = users.orderBy('timestamp', descending: true).snapshots();
    return usersStream;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final querySnapshot = await users.where('email', isEqualTo: email).limit(1).get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data() as Map<String, dynamic>;
    }
    
    return null;
  }
}
