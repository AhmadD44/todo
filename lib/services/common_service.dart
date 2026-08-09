import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/common_note.dart';

/// Real-time sync for the shared "Common" feed.
///
/// Every note lives under `couples/{coupleCode}/notes`, so both partners who
/// entered the same couple code get the same stream of notes instantly.
class CommonService {
  CommonService._();

  /// Set by `main()` once Firebase has initialised successfully.
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
    required String authorUid,
    String? imageId,
  }) =>
      _notes(code).add({
        'text': text,
        'author': author,
        'authorUid': authorUid,
        'isDone': false,
        if (imageId != null) 'imageId': imageId,
        'reactions': <String, String>{},
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

  /// Sets or clears the current user's reaction (one emoji per user).
  static Future<void> setReaction({
    required String code,
    required String id,
    required String uid,
    required String? emoji,
  }) =>
      _notes(code).doc(id).update({
        'reactions.$uid':
            emoji == null ? FieldValue.delete() : emoji,
      });

  static Future<void> delete({required String code, required String id}) =>
      _notes(code).doc(id).delete();

  // --- Free image storage: compressed base64 kept in its own Firestore doc ---
  //
  // Images live at couples/{code}/images/{id} (separate from the note) so the
  // feed stream stays light; a note only references the image id and loads the
  // bytes lazily. This works entirely on the free Spark plan (no Storage/Blaze).

  static CollectionReference<Map<String, dynamic>> _images(String code) =>
      FirebaseFirestore.instance
          .collection('couples')
          .doc(code)
          .collection('images');

  /// In-memory cache so scrolling doesn't re-fetch/re-decode images.
  static final Map<String, Uint8List> _imageCache = {};

  /// Store already-compressed [bytes] and return the new image id.
  /// Firestore docs cap at ~1MB, so the caller must compress first.
  static Future<String> storeImage({
    required String code,
    required Uint8List bytes,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _imageCache[id] = bytes;
    await _images(code).doc(id).set({'data': base64Encode(bytes)});
    return id;
  }

  /// Load an image's bytes (cached after first fetch).
  static Future<Uint8List?> loadImage({
    required String code,
    required String id,
  }) async {
    final cached = _imageCache[id];
    if (cached != null) return cached;
    final snap = await _images(code).doc(id).get();
    final data = snap.data()?['data'] as String?;
    if (data == null) return null;
    final bytes = base64Decode(data);
    _imageCache[id] = bytes;
    return bytes;
  }
}
