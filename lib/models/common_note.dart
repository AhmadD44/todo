import 'package:cloud_firestore/cloud_firestore.dart';

/// A note in the shared "Common" feed that both partners can read and write.
///
/// Stored in Firestore at `couples/{coupleCode}/notes/{noteId}` so any two
/// devices using the same couple code see the same feed in real time.
class CommonNote {
  final String id;
  final String text;
  final String author;
  final DateTime createdAt;
  final bool isDone;

  CommonNote({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
    this.isDone = false,
  });

  factory CommonNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final ts = data['createdAt'];
    return CommonNote(
      id: doc.id,
      text: data['text'] ?? '',
      author: data['author'] ?? 'Someone',
      isDone: data['isDone'] ?? false,
      // serverTimestamp() is null locally until the write reaches the server.
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
