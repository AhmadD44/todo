import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single romantic plan / to-do item.
class Task {
  final String id;
  final String title;
  final bool isDone;
  final String category; // 'Dates' or 'Personal'
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.category,
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? isDone,
    String? category,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        isDone: json['isDone'] ?? false,
        category: json['category'] ?? 'Dates',
        createdAt: DateTime.parse(json['createdAt']),
      );

  // --- Persistence (SharedPreferences JSON) ---
  static const String _prefsKey = 'love_tasks';

  static Future<List<Task>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => Task.fromJson(e)).toList();
  }

  static Future<void> saveAll(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }
}
