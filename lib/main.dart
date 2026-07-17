import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const LoveNotesApp());
}

/// The Root Application containing romantic and cozy theme configurations
class LoveNotesApp extends StatelessWidget {
  const LoveNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sisi notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Theme Colors: Pastel Pinks, Soft Roses, Cozy Crimson
        primaryColor: const Color(0xFFAD1457),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC2185B),
          primary: const Color(0xFFAD1457), // Deep Rose/Crimson
          secondary: const Color(0xFFEC407A), // Medium Soft Pink
          background: const Color(0xFFFFF8F9), // Cozy Pinkish-White Warm Background
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F9),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Task model containing state specifications and JSON serializations
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

  // Convert Task into Map for SharedPreferences JSON storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  // Build Task from JSON Decoded map
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        isDone: json['isDone'] ?? false,
        category: json['category'] ?? 'Dates',
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  /// Load tasks from local Storage using SharedPreferences
  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tasksJson = prefs.getString('love_tasks');
      if (tasksJson != null) {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        setState(() {
          _tasks = decoded.map((item) => Task.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        // First execution dummy data setup to look beautiful out-of-the-box
        _initSampleData();
      }
    } catch (e) {
      debugPrint("Error loading tasks: $e");
      setState(() => _isLoading = false);
    }
  }

  /// Initialize curated list of tasks for high-fidelity first impression
  void _initSampleData() {
    setState(() {
      _tasks = [
        // Task(
        //   id: '1',
        //   title: 'Plan a magical candlelit rooftop dinner 🕯️',
        //   category: 'Dates',
        //   isDone: false,
        //   createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        // ),
        // Task(
        //   id: '2',
        //   title: 'Write a tiny cute love note and hide it in their bag 📝',
        //   category: 'Personal',
        //   isDone: true,
        //   createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        // ),
        // Task(
        //   id: '3',
        //   title: 'Have a scenic picnic at the sunset park 🧺🌹',
        //   category: 'Dates',
        //   isDone: true,
        //   createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        // ),
        // Task(
        //   id: '4',
        //   title: 'Prepare breakfast in bed for them this weekend 🥞☕',
        //   category: 'Personal',
        //   isDone: false,
        //   createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        // ),
      ];
      _isLoading = false;
    });
    _saveTasks();
  }

  /// Write state list updates to local database cache
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString('love_tasks', encoded);
    } catch (e) {
      debugPrint("Error saving tasks: $e");
    }
  }

  /// Add a new task item and persist state
  void _addTask(String title, String category) {
    final newTask = Task(
      id: DateTime.now().toIso8601String(), // Simple unique ID generation
      title: title,
      category: category,
      createdAt: DateTime.now(),
    );
    setState(() {
      _tasks.insert(0, newTask); // Inserts on top
    });
    _saveTasks();
  }

  /// Toggle task completion state
  void _toggleTask(String id) {
    setState(() {
      _tasks = _tasks.map((task) {
        if (task.id == id) {
          return task.copyWith(isDone: !task.isDone);
        }
        return task;
      }).toList();
    });
    _saveTasks();
  }

  /// Remove task permanently on Swipe Actions
  void _deleteTask(String id) {
    final removedTask = _tasks.firstWhere((task) => task.id == id);
    setState(() {
      _tasks.removeWhere((task) => task.id == id);
    });
    _saveTasks();

    // Show undo snackbar with custom sweet styling
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;

    void undo() {
      setState(() {
        _tasks.add(removedTask);
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
      _saveTasks();
      controller.close();
    }

    controller = messenger.showSnackBar(
      SnackBar(
        // Fixed behavior makes the bar slide DOWN off-screen when it exits.
        // We keep the floating rounded-card look by styling the content
        // inside a transparent SnackBar.
        behavior: SnackBarBehavior.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        content: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4A148C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '"${removedTask.title}" has been deleted.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: undo,
                child: Text(
                  'Undo ↩️',
                  style: TextStyle(
                    color: Colors.pinkAccent.shade100,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Force auto-dismiss after 6s even if the mouse is hovering over it
    // (on desktop/web Flutter pauses the built-in timer while hovered).
    Future.delayed(const Duration(seconds: 6), () => controller.close());
  }

  /// Opens highly styled Dialog for Task Creation input
  void _showAddTaskDialog(BuildContext context) {
    String taskTitle = '';
    String selectedCategory = 'Dates'; // Defaults selection to 'Dates'

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFF5F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              title: const Row(
                children: [
                  Icon(Icons.favorite, color: Color(0xFFC2185B)),
                  SizedBox(width: 8),
                  Text(
                    'Add New Memory',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'What is your romantic plan? ...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.pink.shade100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFC2185B), width: 2),
                        ),
                      ),
                      onChanged: (val) => taskTitle = val,
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose Category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF880E4F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Date Ideas 🌹'),
                            selected: selectedCategory == 'Dates',
                            selectedColor: const Color(0xFFFCE4EC),
                            checkmarkColor: const Color(0xFFC2185B),
                            labelStyle: TextStyle(
                              color: selectedCategory == 'Dates'
                                  ? const Color(0xFFC2185B)
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => selectedCategory = 'Dates');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Personal 👤'),
                            selected: selectedCategory == 'Personal',
                            selectedColor: const Color(0xFFFFF1F3),
                            checkmarkColor: const Color(0xFFAD1457),
                            labelStyle: TextStyle(
                              color: selectedCategory == 'Personal'
                                  ? const Color(0xFFAD1457)
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => selectedCategory = 'Personal');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (taskTitle.trim().isNotEmpty) {
                      _addTask(taskTitle.trim(), selectedCategory);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2185B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  child: const Text('Add Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Builds curated List view based on Category configuration
  Widget _buildTaskList(String filter) {
    final filteredList = _tasks.where((task) {
      if (filter == 'All') return true;
      return task.category == filter;
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 84,
              color: const Color(0xFFC2185B).withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            const Text(
              'No memories planned here!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF880E4F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the floating pink button below\nto add your next goal.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90, top: 12),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final task = filteredList[index];
        return Dismissible(
          key: Key(task.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteTask(task.id),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFEF9A9A), Colors.redAccent.shade200],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Remove Plan',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
              ],
            ),
          ),
          child: TaskTile(
            task: task,
            onToggle: () => _toggleTask(task.id),
            onDelete: () => _deleteTask(task.id),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF8F9),
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                tooltip: 'Special Dates',
                icon: const Icon(Icons.celebration_rounded, color: Color(0xFFC2185B)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SpecialDatesScreen()),
                  );
                },
              ),
            ),
          ],
          title: const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Color(0xFFC2185B), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'SiSi - NOTES',
                    style: TextStyle(
                      color: Color(0xFF880E4F),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.favorite, color: Color(0xFFC2185B), size: 22),
                ],
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC).withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const TabBar(
                indicator: BoxDecoration(
                  color: Color(0xFFC2185B),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Color(0xFFAD1457),
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.all_inclusive, size: 16),
                        SizedBox(width: 4),
                        Text('All'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Dates 🌹'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Personal 👤'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFC2185B)),
              )
            : TabBarView(
                children: [
                  _buildTaskList('All'),
                  _buildTaskList('Dates'),
                  _buildTaskList('Personal'),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTaskDialog(context),
          backgroundColor: const Color(0xFFC2185B),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_circle_rounded, size: 22),
          label: const Text('Add Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

/// Custom Interactive Task Card displaying romantic styled components
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskTile({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dynamic styles corresponding to the Task completion status
    final activeBg = Colors.white;
    final doneBg = const Color(0xFFF5ECEF); // Soft, faded pinkish-grey
    final primaryCrimson = const Color(0xFFC2185B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: task.isDone ? doneBg : activeBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: task.isDone
                ? Colors.transparent
                : const Color(0xFFF8BBD0).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: task.isDone
              ? Colors.black12.withOpacity(0.04)
              : const Color(0xFFFCE4EC),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: task.isDone
                ? Colors.black12.withOpacity(0.05)
                : (task.category == 'Dates' ? const Color(0xFFFFF1F3) : const Color(0xFFE8EAF6)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              task.category == 'Dates' ? '🌹' : '👤',
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: task.isDone ? Colors.grey.shade500 : const Color(0xFF2C3E50),
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            decorationThickness: 2,
            decorationColor: const Color(0xFFE91E63).withOpacity(0.5),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(
                task.category == 'Dates' ? Icons.favorite_border : Icons.person_outline_rounded,
                size: 12,
                color: task.isDone ? Colors.grey.shade400 : primaryCrimson,
              ),
              const SizedBox(width: 4),
              Text(
                task.category,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: task.isDone ? Colors.grey.shade400 : primaryCrimson,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mark as done / undone
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(30),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: task.isDone
                    ? const Icon(
                        Icons.favorite,
                        key: ValueKey('done_icon'),
                        color: Colors.redAccent,
                        size: 32,
                      )
                    : Icon(
                        Icons.favorite_border,
                        key: const ValueKey('undone_icon'),
                        color: const Color(0xFFEC407A),
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(width: 4),
            // Delete this plan
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete',
              splashRadius: 22,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
//  SPECIAL DATES — reminders for important moments (birthday, first date …)
//  Schedules 3 local notifications per date: 1 day before, 6 hours before,
//  and at the exact moment. Persisted with SharedPreferences like tasks.
// ===========================================================================

/// The selectable reminder types and their matching emoji.
const List<Map<String, String>> kSpecialDateTypes = [
  {'type': 'First Date', 'emoji': '💞'},
  {'type': 'Birthday', 'emoji': '🎂'},
  {'type': 'Anniversary', 'emoji': '💍'},
  {'type': 'Other', 'emoji': '🌟'},
];

String _emojiForType(String type) => kSpecialDateTypes.firstWhere(
      (e) => e['type'] == type,
      orElse: () => kSpecialDateTypes.last,
    )['emoji']!;

/// Model describing one important date the user wants to be reminded about.
class SpecialDate {
  final String id;
  final String title;
  final String type;
  final DateTime dateTime;
  final int notifId; // base id; the 3 reminders use notifId, +1, +2

  SpecialDate({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.notifId,
  });

  String get emoji => _emojiForType(type);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'dateTime': dateTime.toIso8601String(),
        'notifId': notifId,
      };

  factory SpecialDate.fromJson(Map<String, dynamic> json) => SpecialDate(
        id: json['id'],
        title: json['title'],
        type: json['type'] ?? 'Other',
        dateTime: DateTime.parse(json['dateTime']),
        notifId: json['notifId'] ?? 0,
      );
}

/// Thin wrapper around flutter_local_notifications for scheduling reminders.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'special_dates_channel';
  static const String _channelName = 'Special Date Reminders';
  static const String _channelDesc = 'Reminders for your important dates 💖';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Load the timezone database and point tz.local at the device's zone so
    // scheduled times fire at the wall-clock moment the user picked.
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // If the platform can't report a zone we fall back to the default (UTC).
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: settings);

    // Pre-create the Android channel so reminders have the right importance.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Ask for the runtime notification + exact-alarm permissions (Android 13+/12+).
  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );

  /// Schedule the three reminders for [d] (skipping any that are already past).
  Future<void> schedule(SpecialDate d) async {
    await cancel(d);

    final target = tz.TZDateTime.from(d.dateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    final reminders = <(int, tz.TZDateTime, String, String)>[
      (
        d.notifId,
        target.subtract(const Duration(days: 1)),
        '${d.emoji} Tomorrow: ${d.title}',
        'Just 1 day left until ${d.title}! 💕',
      ),
      (
        d.notifId + 1,
        target.subtract(const Duration(hours: 6)),
        '${d.emoji} In 6 hours: ${d.title}',
        '${d.title} is coming up in 6 hours! 🥰',
      ),
      (
        d.notifId + 2,
        target,
        '${d.emoji} Today: ${d.title}',
        'The big moment is here — ${d.title}! 💖',
      ),
    ];

    for (final (id, fireAt, title, body) in reminders) {
      if (fireAt.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: fireAt,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  Future<void> cancel(SpecialDate d) async {
    await _plugin.cancel(id: d.notifId);
    await _plugin.cancel(id: d.notifId + 1);
    await _plugin.cancel(id: d.notifId + 2);
  }
}

// ---- Small date/time formatting helpers (avoids the intl dependency) -------

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtDate(DateTime d) => '${_kMonths[d.month - 1]} ${d.day}, ${d.year}';

String _fmtTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $ap';
}

String _countdownLabel(DateTime d) {
  final diff = d.difference(DateTime.now());
  if (diff.isNegative) return 'Passed';
  if (diff.inDays >= 1) return 'in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
  if (diff.inHours >= 1) return 'in ${diff.inHours} hr${diff.inHours == 1 ? '' : 's'}';
  if (diff.inMinutes >= 1) return 'in ${diff.inMinutes} min';
  return 'Now';
}

/// Full screen that lists the user's special dates and lets them add/remove them.
class SpecialDatesScreen extends StatefulWidget {
  const SpecialDatesScreen({super.key});

  @override
  State<SpecialDatesScreen> createState() => _SpecialDatesScreenState();
}

class _SpecialDatesScreenState extends State<SpecialDatesScreen> {
  static const _prefsKey = 'special_dates';
  List<SpecialDate> _dates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // Ask for permission the first time the user opens this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermissions();
    });
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw);
        _dates = decoded.map((e) => SpecialDate.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading special dates: $e');
    }
    _sort();
    setState(() => _loading = false);
  }

  void _sort() => _dates.sort((a, b) => a.dateTime.compareTo(b.dateTime));

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_dates.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> _addDate(String title, String type, DateTime dateTime) async {
    final date = SpecialDate(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      type: type,
      dateTime: dateTime,
      notifId: DateTime.now().microsecondsSinceEpoch.remainder(1 << 30),
    );
    setState(() {
      _dates.add(date);
      _sort();
    });
    await _save();
    await NotificationService.instance.schedule(date);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4A148C),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('${date.emoji} Reminder set for "${date.title}" 💖'),
        ),
      );
  }

  Future<void> _deleteDate(SpecialDate date) async {
    await NotificationService.instance.cancel(date);
    setState(() => _dates.removeWhere((d) => d.id == date.id));
    await _save();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4A148C),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('"${date.title}" reminder removed.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFC2185B)),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration_rounded, color: Color(0xFFC2185B), size: 22),
            SizedBox(width: 8),
            Text(
              'Special Dates',
              style: TextStyle(
                color: Color(0xFF880E4F),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC2185B)),
            )
          : _dates.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 90),
                  itemCount: _dates.length,
                  itemBuilder: (context, index) =>
                      _buildDateCard(_dates[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDateDialog,
        backgroundColor: const Color(0xFFC2185B),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_alert_rounded, size: 22),
        label: const Text('Add Date',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 84,
            color: const Color(0xFFC2185B).withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          const Text(
            'No special dates yet!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF880E4F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add birthdays, your first date, anniversaries…\nand we\'ll remind you before they arrive. 💌',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(SpecialDate date) {
    final passed = date.dateTime.isBefore(DateTime.now());
    final primaryCrimson = const Color(0xFFC2185B);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFF5ECEF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: passed
                ? Colors.transparent
                : const Color(0xFFF8BBD0).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: passed
              ? Colors.black12.withOpacity(0.04)
              : const Color(0xFFFCE4EC),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: passed
                ? Colors.black12.withOpacity(0.05)
                : const Color(0xFFFFF1F3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(date.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          date.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: passed ? Colors.grey.shade500 : const Color(0xFF2C3E50),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 12,
                  color: passed ? Colors.grey.shade400 : primaryCrimson),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${_fmtDate(date.dateTime)}  •  ${_fmtTime(date.dateTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.grey.shade400 : primaryCrimson,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: passed
                    ? Colors.grey.shade200
                    : const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _countdownLabel(date.dateTime),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.grey.shade500 : const Color(0xFFAD1457),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _deleteDate(date),
              tooltip: 'Delete',
              splashRadius: 20,
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.grey.shade400, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  /// Themed builder so the native date/time pickers match the romantic palette.
  Widget _pinkPicker(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFC2185B),
          onPrimary: Colors.white,
          onSurface: Color(0xFF880E4F),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFC2185B)),
        ),
      ),
      child: child!,
    );
  }

  void _showAddDateDialog() {
    String title = '';
    String selectedType = 'First Date';
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String dateLabel = pickedDate == null
                ? 'Pick a date'
                : _fmtDate(pickedDate!);
            String timeLabel = pickedTime == null
                ? 'Pick a time'
                : _fmtTime(DateTime(0, 1, 1, pickedTime!.hour, pickedTime!.minute));

            return AlertDialog(
              backgroundColor: const Color(0xFFFFF5F6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.celebration_rounded, color: Color(0xFFC2185B)),
                  SizedBox(width: 8),
                  Text(
                    'Add Special Date',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF880E4F)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'e.g. Our first date 💞',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.pink.shade100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFFC2185B), width: 2),
                        ),
                      ),
                      onChanged: (v) => title = v,
                    ),
                    const SizedBox(height: 18),
                    const Text('Type',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF880E4F))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: kSpecialDateTypes.map((t) {
                        final label = '${t['type']} ${t['emoji']}';
                        final selected = selectedType == t['type'];
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          selectedColor: const Color(0xFFFCE4EC),
                          checkmarkColor: const Color(0xFFC2185B),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFFC2185B)
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (v) {
                            if (v) {
                              setDialogState(() => selectedType = t['type']!);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.calendar_month_rounded,
                            label: dateLabel,
                            chosen: pickedDate != null,
                            onTap: () async {
                              final now = DateTime.now();
                              final d = await showDatePicker(
                                context: context,
                                initialDate: pickedDate ?? now,
                                firstDate: now,
                                lastDate: DateTime(now.year + 10),
                                builder: _pinkPicker,
                              );
                              if (d != null) {
                                setDialogState(() => pickedDate = d);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.access_time_rounded,
                            label: timeLabel,
                            chosen: pickedTime != null,
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime:
                                    pickedTime ?? TimeOfDay.now(),
                                builder: _pinkPicker,
                              );
                              if (t != null) {
                                setDialogState(() => pickedTime = t);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (title.trim().isEmpty ||
                        pickedDate == null ||
                        pickedTime == null) {
                      _toast('Please add a title, date and time 💌');
                      return;
                    }
                    final dt = DateTime(
                      pickedDate!.year,
                      pickedDate!.month,
                      pickedDate!.day,
                      pickedTime!.hour,
                      pickedTime!.minute,
                    );
                    if (!dt.isAfter(DateTime.now())) {
                      _toast('Please pick a moment in the future ⏰');
                      return;
                    }
                    Navigator.pop(context);
                    _addDate(title.trim(), selectedType, dt);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2185B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  child: const Text('Set Reminder',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4A148C),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(message),
        ),
      );
  }
}

/// Small pill button used inside the add-date dialog for date/time selection.
class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool chosen;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.chosen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: chosen ? const Color(0xFFC2185B) : Colors.pink.shade100,
            width: chosen ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFC2185B)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: chosen
                      ? const Color(0xFF880E4F)
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}