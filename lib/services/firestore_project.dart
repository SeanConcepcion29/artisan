import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProjects {

  final CollectionReference projectsCollection =  FirebaseFirestore.instance.collection('projects');


  /* CREATES new project */
  Future<void> createProject({
    required String email,
    required String owner,
    required String projectId,
    required String title,
    required DateTime dateCreated,
    required DateTime dateModified,
    bool public = false,
    bool solo = true,
    List<String> collabs = const [],
    int downloads = 0,
    int likes = 0,
  }) async {
    await projectsCollection.add({
      'collabs': collabs,
      'datecreated': Timestamp.fromDate(dateCreated),
      'datemodified': Timestamp.fromDate(dateModified),
      'downloads': downloads,
      'email': email,
      'likes': likes,
      'owner': owner,
      'projectId': projectId,
      'public': public,
      'solo': solo,
      'title': title,
    });
  }


  /* READS and retrieve specific project based on id */
  Future<Map<String, dynamic>?> getProjectById(String docId) async {
    final docSnapshot = await projectsCollection.doc(docId).get();

    if (docSnapshot.exists) {
      return {
        'id': docSnapshot.id,
        ...docSnapshot.data() as Map<String, dynamic>,
      };
    }
    return null;
  }


  /* READS and retrieve all projects of specific user via email */
  Future<List<Map<String, dynamic>>> getAllProjectsByEmail(String email) async {
    final ownedQuery = await projectsCollection.where('email', isEqualTo: email).get();
    final collabQuery = await projectsCollection.where('collabs', arrayContains: email).get();

    final allDocs = [...ownedQuery.docs, ...collabQuery.docs];

    /* removes duplicates (in case user is both owner and collab) */
    final uniqueDocs = {for (var doc in allDocs) doc.id: doc}.values.toList();

    return uniqueDocs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }


  /* READS and retrieve all public projects */
  Future<List<Map<String, dynamic>>> getAllPublicProjects() async {
    final querySnapshot = await projectsCollection.where('public', isEqualTo: true).get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }


  /* UPDATES the date modified attribute of the project */
  Future<void> updateDateModified(String docId) async {
    final now = DateTime.now();
    await projectsCollection.doc(docId).update({
      'datemodified': Timestamp.fromDate(now),
    });
  }


  /* UPDATES the title attribute of the project */
  Future<void> updateProjectTitle(String docId, String newTitle) async {
    final now = DateTime.now();
    await projectsCollection.doc(docId).update({
      'title': newTitle,
      'datemodified': Timestamp.fromDate(now),
    });
  }


  /* DELETES the project */
  Future<void> deleteProject(String docId) async {
    await projectsCollection.doc(docId).delete();
  }


  /* ADDS new member to the collabs attribute of a project */
  Future<void> addMember(String projectId, String email) async {
    if (email.isEmpty) return;
    await projectsCollection.doc(projectId).update({
      "collabs": FieldValue.arrayUnion([email]),
    });
  }


  /* TOGGLES public/private measures of a project */
  Future<void> updatePublic(String projectId, bool public) async {
    await projectsCollection.doc(projectId).update({
      "public": public,
    });
  }
}
