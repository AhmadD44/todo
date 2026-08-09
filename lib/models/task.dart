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
}
