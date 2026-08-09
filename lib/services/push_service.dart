import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Registers this device for partner push notifications and shows incoming
/// messages while the app is foregrounded (the OS shows them otherwise).
///
/// A Cloud Function (see `functions/`) sends the actual notifications when a
/// note is added to the couple's Common feed.
class PushService {
  PushService._();

  static bool _wired = false;

  static Future<void> init(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) await _saveToken(uid, token);

      // Keep the saved token fresh.
      messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));

      if (!_wired) {
        _wired = true;
        FirebaseMessaging.onMessage.listen((message) {
          final n = message.notification;
          if (n != null) {
            NotificationService.instance.showNow(
              title: n.title ?? 'sisi notes',
              body: n.body ?? '',
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
  }

  static Future<void> _saveToken(String uid, String token) =>
      FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmTokens': FieldValue.arrayUnion([token])},
        SetOptions(merge: true),
      );

  /// Remove this device's token (best effort) — called on logout.
  static Future<void> removeToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'fcmTokens': FieldValue.arrayRemove([token])},
          SetOptions(merge: true),
        );
      }
    } catch (_) {/* ignore */}
  }
}
