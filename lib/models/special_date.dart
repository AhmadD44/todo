import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// The selectable reminder types and their matching emoji.
const List<Map<String, String>> kSpecialDateTypes = [
  {'type': 'First Date', 'emoji': '💞'},
  {'type': 'Birthday', 'emoji': '🎂'},
  {'type': 'Anniversary', 'emoji': '💍'},
  {'type': 'Other', 'emoji': '🌟'},
];

String emojiForType(String type) => kSpecialDateTypes.firstWhere(
      (e) => e['type'] == type,
      orElse: () => kSpecialDateTypes.last,
    )['emoji']!;

/// An important date the user wants to be reminded about.
///
/// When [repeatYearly] is true the reminder rolls forward to the next
/// anniversary automatically (birthdays, first dates, …).
class SpecialDate {
  final String id;
  final String title;
  final String type;
  final DateTime dateTime;
  final int notifId; // base id; the 3 reminders use notifId, +1, +2
  final bool repeatYearly;

  SpecialDate({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.notifId,
    this.repeatYearly = false,
  });

  String get emoji => emojiForType(type);

  /// The next moment this date should fire.
  ///
  /// For one-off dates this is simply [dateTime]. For yearly ones it is the
  /// upcoming anniversary (this year's if still ahead, otherwise next year's).
  DateTime nextOccurrence() {
    if (!repeatYearly) return dateTime;
    final now = DateTime.now();
    var occ = dateTime;
    while (occ.isBefore(now)) {
      occ = DateTime(
          occ.year + 1, occ.month, occ.day, occ.hour, occ.minute);
    }
    return occ;
  }

  /// A one-off date whose moment has already passed (yearly ones never "pass").
  bool get isPast => !repeatYearly && dateTime.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'dateTime': dateTime.toIso8601String(),
        'notifId': notifId,
        'repeatYearly': repeatYearly,
      };

  factory SpecialDate.fromJson(Map<String, dynamic> json) => SpecialDate(
        id: json['id'],
        title: json['title'],
        type: json['type'] ?? 'Other',
        dateTime: DateTime.parse(json['dateTime']),
        notifId: json['notifId'] ?? 0,
        repeatYearly: json['repeatYearly'] ?? false,
      );

  // --- Persistence (SharedPreferences JSON) ---
  static const String _prefsKey = 'special_dates';

  static Future<List<SpecialDate>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => SpecialDate.fromJson(e)).toList();
  }

  static Future<void> saveAll(List<SpecialDate> dates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(dates.map((d) => d.toJson()).toList()),
    );
  }
}
