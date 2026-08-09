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

  /// True when this date lives in the couple's shared collection (both partners
  /// see it and get reminded). Not persisted for personal dates.
  final bool shared;

  SpecialDate({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.notifId,
    this.repeatYearly = false,
    this.shared = false,
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

  factory SpecialDate.fromJson(Map<String, dynamic> json,
          {bool shared = false}) =>
      SpecialDate(
        id: json['id'],
        title: json['title'],
        type: json['type'] ?? 'Other',
        dateTime: DateTime.parse(json['dateTime']),
        notifId: json['notifId'] ?? 0,
        repeatYearly: json['repeatYearly'] ?? false,
        shared: shared,
      );
}
