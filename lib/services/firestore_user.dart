import 'package:cloud_firestore/cloud_firestore.dart';


class FirestoreUsers {

  final CollectionReference users = FirebaseFirestore.instance.collection('users');


  /* CREATES new user */
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
      'timestamp': FieldValue.serverTimestamp(), 
    });
  }


  /* READS and retrieve all user */
  Stream<QuerySnapshot> getUsersStream() {
    final usersStream = users.orderBy('timestamp', descending: true).snapshots();
    return usersStream;
  }


  /* READS and retrieve specific user based on email */
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final querySnapshot = await users.where('email', isEqualTo: email).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data() as Map<String, dynamic>;
    }

    return null;
  }


  /* UPDATES the name of the user based on email */
  Future<void> updateName(String email, String firstName, String lastName) async {
    final querySnapshot = await users.where('email', isEqualTo: email).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      await users.doc(docId).update({
        'firstname': firstName,
        'lastname': lastName,
      });
    }
  }


  /* DELETES the user based on email */
  Future<void> deleteUser(String email) async {
    final querySnapshot =
        await users.where('email', isEqualTo: email).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      await users.doc(docId).delete();
    }
  }
}
