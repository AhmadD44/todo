import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/common_note.dart';

/// Real-time sync for the shared "Common" feed.
///
/// Every note lives under `couples/{coupleCode}/notes`, so both partners who
/// entered the same couple code get the same stream of notes instantly.
class CommonService {
  CommonService._();

  /// Set by `main()` once Firebase has initialised successfully. When false the
  /// Common screen shows setup instructions instead of trying to sync.
  static bool isReady = false;

  static CollectionReference<Map<String, dynamic>> _notes(String code) =>
      FirebaseFirestore.instance
          .collection('couples')
          .doc(code)
          .collection('notes');

  /// Live stream of the feed, newest first.
  static Stream<List<CommonNote>> watch(String code) => _notes(code)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(CommonNote.fromDoc).toList());

  static Future<void> add({
    required String code,
    required String text,
    required String author,
  }) =>
      _notes(code).add({
        'text': text,
        'author': author,
        'isDone': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Future<void> update({
    required String code,
    required String id,
    required String text,
  }) =>
      _notes(code).doc(id).update({'text': text});

  static Future<void> toggleDone({
    required String code,
    required String id,
    required bool isDone,
  }) =>
      _notes(code).doc(id).update({'isDone': isDone});

  static Future<void> delete({required String code, required String id}) =>
      _notes(code).doc(id).delete();
}
