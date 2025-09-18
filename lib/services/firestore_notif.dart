import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreNotifications {

  final CollectionReference notifications = FirebaseFirestore.instance.collection('notifications');


  /* CREATES new notification for single recipient */
  Future<void> createNotification({
    String projectName = "",
    String projectId = "",
    required String from,
    required String recipient,
    required String message,
    required bool opened,
    required DateTime date,
  }) async {
    await notifications.add({
      "projectName": projectName,
      "projectId": projectId,
      "from": from,
      "recipient": recipient,
      "message": message,
      "opened": opened,
      "date": Timestamp.fromDate(date),
    });
  }


  /* CREATES new notification for multiple recipients */
  Future<void> createNotificationsForRecipients({
    String projectName = "",
    String projectId = "",
    required String from,
    required List<String> recipients,
    required String message,
    required DateTime date,
  }) async {
    for (final recipient in recipients) {
      await createNotification(
        projectName: projectName,
        projectId: projectId,
        from: from,
        recipient: recipient,
        message: message,
        opened: false,
        date: date,
      );
    }
  }


  /* READS and retrieve notification list for a specific user */
  Future<List<Map<String, dynamic>>> getNotificationsByRecipient(String email) async {
    final query = await notifications.where("recipient", isEqualTo: email).get();

    final notificationsList = query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        "projectName": data["projectName"],
        "projectId": data["projectId"],
        "from": data["from"],
        "recipient": data["recipient"],
        "message": data["message"],
        "opened": data["opened"] ?? false,
        "date": (data["date"] as Timestamp).toDate(),
      };
    }).toList();

    notificationsList.sort((a, b) => b["date"].compareTo(a["date"]));
    return notificationsList;
  }
}
