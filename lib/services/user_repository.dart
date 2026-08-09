import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/special_date.dart';
import '../models/task.dart';

/// Outcome of trying to join a couple feed by code.
enum JoinResult { joined, full, error }

/// Reads/writes a user's private data as individual Firestore documents, so
/// edits are per-note (no whole-list overwrites) and screens update live.
///
///   users/{uid}/tasks/{taskId}
///   users/{uid}/specialDates/{dateId}
///   users/{uid}            → profile + coupleCode
///   couples/{code}         → { members: [uid, ...] }  (max 2)
class UserRepository {
  UserRepository._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  // ---------------------------------------------------------------- tasks --
  static CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _userDoc(uid).collection('tasks');

  static Stream<List<Task>> tasksStream(String uid) => _tasks(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Task.fromJson(d.data())).toList());

  static Future<void> upsertTask(String uid, Task task) =>
      _tasks(uid).doc(task.id).set(task.toJson());

  static Future<void> deleteTask(String uid, String id) =>
      _tasks(uid).doc(id).delete();

  // -------------------------------------------------------- special dates --
  static CollectionReference<Map<String, dynamic>> _dates(String uid) =>
      _userDoc(uid).collection('specialDates');

  static Stream<List<SpecialDate>> specialDatesStream(String uid) =>
      _dates(uid).snapshots().map(
            (s) => s.docs.map((d) => SpecialDate.fromJson(d.data())).toList(),
          );

  /// One-off read used at startup to (re)schedule reminders.
  static Future<List<SpecialDate>> loadSpecialDates(String uid) async {
    final snap = await _dates(uid).get();
    return snap.docs.map((d) => SpecialDate.fromJson(d.data())).toList();
  }

  static Future<void> upsertSpecialDate(String uid, SpecialDate date) =>
      _dates(uid).doc(date.id).set(date.toJson());

  static Future<void> deleteSpecialDate(String uid, String id) =>
      _dates(uid).doc(id).delete();

  // ------------------------------------------------ shared special dates ---
  // Shared dates live under the couple so both partners see them and both
  // devices schedule reminders locally.
  static CollectionReference<Map<String, dynamic>> _sharedDates(String code) =>
      _db.collection('couples').doc(code).collection('specialDates');

  static Stream<List<SpecialDate>> sharedSpecialDatesStream(String code) =>
      _sharedDates(code).snapshots().map((s) => s.docs
          .map((d) => SpecialDate.fromJson(d.data(), shared: true))
          .toList());

  static Future<List<SpecialDate>> loadSharedSpecialDates(String code) async {
    final snap = await _sharedDates(code).get();
    return snap.docs
        .map((d) => SpecialDate.fromJson(d.data(), shared: true))
        .toList();
  }

  static Future<void> upsertSharedSpecialDate(String code, SpecialDate d) =>
      _sharedDates(code).doc(d.id).set(d.toJson());

  static Future<void> deleteSharedSpecialDate(String code, String id) =>
      _sharedDates(code).doc(id).delete();

  // ------------------------------------------------------- couple linking --
  static Future<String?> loadCoupleCode(String uid) async {
    final data = (await _userDoc(uid).get()).data();
    return data?['coupleCode'] as String?;
  }

  /// Join (or create) the couple feed for [code]. A code holds at most two
  /// members, so a leaked code can't let a third person in.
  static Future<JoinResult> joinCouple(String uid, String code) async {
    final coupleRef = _db.collection('couples').doc(code);
    try {
      final result = await _db.runTransaction<JoinResult>((tx) async {
        final snap = await tx.get(coupleRef);
        if (!snap.exists) {
          tx.set(coupleRef, {
            'members': [uid],
            'createdAt': FieldValue.serverTimestamp(),
          });
          return JoinResult.joined;
        }
        final members =
            List<String>.from((snap.data()?['members'] as List?) ?? const []);
        if (members.contains(uid)) return JoinResult.joined;
        if (members.length >= 2) return JoinResult.full;
        members.add(uid);
        tx.update(coupleRef, {'members': members});
        return JoinResult.joined;
      });
      if (result == JoinResult.joined) {
        await _userDoc(uid).set(
            {'coupleCode': code}, SetOptions(merge: true));
      }
      return result;
    } catch (_) {
      return JoinResult.error;
    }
  }

  static Future<void> leaveCouple(String uid, String code) async {
    final coupleRef = _db.collection('couples').doc(code);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(coupleRef);
        if (snap.exists) {
          final members = List<String>.from(
              (snap.data()?['members'] as List?) ?? const []);
          members.remove(uid);
          tx.update(coupleRef, {'members': members});
        }
      });
    } catch (_) {/* best effort */}
    await _userDoc(uid).set(
        {'coupleCode': FieldValue.delete()}, SetOptions(merge: true));
  }

  /// Permanently remove all of a user's data (used on account deletion).
  static Future<void> deleteAllUserData(String uid) async {
    for (final coll in [_tasks(uid), _dates(uid)]) {
      final docs = await coll.get();
      for (final d in docs.docs) {
        await d.reference.delete();
      }
    }
    final code = await loadCoupleCode(uid);
    if (code != null) await leaveCouple(uid, code);
    await _userDoc(uid).delete();
  }
}
