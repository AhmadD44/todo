import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Triggers a partner push by calling a tiny serverless endpoint (hosted free
/// on Vercel — no billing card needed). The endpoint verifies the caller and
/// sends the FCM message; see `push_server/`.
///
/// After deploying, paste your Vercel URL below (e.g.
/// https://your-app.vercel.app/api/notify). While it's empty, this is a no-op,
/// so the app works fine without push configured.
class PushSender {
  PushSender._();

  static const String _endpoint = ''; // ← paste your Vercel /api/notify URL

  /// Ask the server to notify the other partner about a new Common note.
  static Future<void> notifyPartner(String coupleCode) async {
    if (_endpoint.isEmpty) return; // not configured yet
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final idToken = await user.getIdToken();

      await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken, 'code': coupleCode}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      // Never let a push failure affect posting.
      debugPrint('Push send failed: $e');
    }
  }
}
