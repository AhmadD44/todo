import 'package:cloud_firestore/cloud_firestore.dart';

/// A note in the shared "Common" feed that both partners can read and write.
///
/// Stored at `couples/{coupleCode}/notes/{noteId}`.
class CommonNote {
  final String id;
  final String text;
  final String author;
  final String? authorUid;
  final DateTime createdAt;
  final bool isDone;

  /// Id of the image doc (couples/{code}/images/{imageId}), if any.
  final String? imageId;

  /// Reactions keyed by the reacting user's uid → emoji (one per user).
  final Map<String, String> reactions;

  CommonNote({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
    this.authorUid,
    this.isDone = false,
    this.imageId,
    this.reactions = const {},
  });

  factory CommonNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final ts = data['createdAt'];
    return CommonNote(
      id: doc.id,
      text: data['text'] ?? '',
      author: data['author'] ?? 'Someone',
      authorUid: data['authorUid'] as String?,
      isDone: data['isDone'] ?? false,
      imageId: data['imageId'] as String?,
      reactions: Map<String, String>.from(data['reactions'] ?? const {}),
      // serverTimestamp() is null locally until the write reaches the server.
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
