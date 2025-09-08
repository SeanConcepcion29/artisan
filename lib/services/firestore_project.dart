import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProjects {
  final CollectionReference projectsCollection =
      FirebaseFirestore.instance.collection('projects');

  // CREATE NEW PROJECT
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

  // GET ALL PROJECTS BY EMAIL
  Future<List<Map<String, dynamic>>> getAllProjectsByEmail(String email) async {
    final querySnapshot =
        await projectsCollection.where('email', isEqualTo: email).get();

    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
  }

  // 🚀 GET ALL PUBLIC PROJECTS
  Future<List<Map<String, dynamic>>> getAllPublicProjects() async {
    final querySnapshot =
        await projectsCollection.where('public', isEqualTo: true).get();

    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
  }

  // UPDATE DATE MODIFIED TO CURRENT DATE
  Future<void> updateDateModified(String docId) async {
    final now = DateTime.now();
    await projectsCollection.doc(docId).update({
      'datemodified': Timestamp.fromDate(now),
    });
  }

  // ✅ UPDATE PROJECT TITLE
  Future<void> updateProjectTitle(String docId, String newTitle) async {
    final now = DateTime.now();
    await projectsCollection.doc(docId).update({
      'title': newTitle,
      'datemodified': Timestamp.fromDate(now),
    });
  }

  // ✅ DELETE PROJECT
  Future<void> deleteProject(String docId) async {
    await projectsCollection.doc(docId).delete();
  }

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

    /// Add member by email
  Future<void> addMember(String projectId, String email) async {
    if (email.isEmpty) return;
    await projectsCollection.doc(projectId).update({
      "collabs": FieldValue.arrayUnion([email]),
    });
  }

  /// Toggle public/private
  Future<void> updatePublic(String projectId, bool public) async {
    await projectsCollection.doc(projectId).update({
      "public": public,
    });
  }
}
