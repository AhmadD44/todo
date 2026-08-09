import 'dart:math';

/// Helpers for the couple-code pairing used by the shared "Common" feed.
///
/// The code itself is stored per account in Firestore (see [UserRepository]);
/// this class only builds and normalises codes.
class CoupleService {
  CoupleService._();

  /// Builds a friendly, easy-to-share code such as `SISI-4X7Q`.
  static String generateCode() {
    // No confusable characters (0/O, 1/I) so the code is easy to read aloud.
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final suffix =
        List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    return 'SISI-$suffix';
  }

  /// Normalises user input so `sisi-4x7q` and `SISI-4X7Q` pair together.
  static String normalise(String raw) => raw.trim().toUpperCase();
}
