import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreNotifications {
  final CollectionReference notifications =
      FirebaseFirestore.instance.collection('notifications');

  Future<void> createNotification({
    required String email,
    required String message,
    required bool opened,
    required DateTime date,
  }) async {
    await notifications.add({
      "email": email,
      "message": message,
      "opened": opened,
      "date": Timestamp.fromDate(date),
    });
  }

  Future<List<Map<String, dynamic>>> getNotificationsByEmail(String email) async {
    final query = await notifications
        .where("email", isEqualTo: email)
        .orderBy("date", descending: true)
        .get();

    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        "email": data["email"],
        "message": data["message"],
        "opened": data["opened"] ?? false,
        "date": (data["date"] as Timestamp).toDate(),
      };
    }).toList();
  }
}
