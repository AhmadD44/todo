import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import 'common_view.dart';
import 'special_dates_view.dart';

/// Main screen: the tabbed list of romantic plans / to-dos.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Task> _tasks = [];
  bool _isLoading = true;

  // Tabs: All · Common · Dates · Personal  (Common sits beside All).
  late final TabController _tabController;
  static const int _commonTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      // Rebuild so the FAB hides while the Common tab is active.
      ..addListener(() => setState(() {}));
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      _tasks = await Task.loadAll();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveTasks() => Task.saveAll(_tasks);

  void _addTask(String title, String category) {
    final newTask = Task(
      id: DateTime.now().toIso8601String(),
      title: title,
      category: category,
      createdAt: DateTime.now(),
    );
    setState(() => _tasks.insert(0, newTask));
    _saveTasks();
  }

  /// Apply edits from the edit dialog, keeping id/createdAt/done state intact.
  void _updateTask(String id, String title, String category) {
    setState(() {
      _tasks = _tasks.map((task) {
        if (task.id == id) {
          return task.copyWith(title: title, category: category);
        }
        return task;
      }).toList();
    });
    _saveTasks();
  }

  void _toggleTask(String id) {
    setState(() {
      _tasks = _tasks.map((task) {
        if (task.id == id) return task.copyWith(isDone: !task.isDone);
        return task;
      }).toList();
    });
    _saveTasks();
  }

  void _deleteTask(String id) {
    final removedTask = _tasks.firstWhere((task) => task.id == id);
    setState(() => _tasks.removeWhere((task) => task.id == id));
    _saveTasks();

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
        controller;

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
        behavior: SnackBarBehavior.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 6),
        content: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.snackPlum,
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

    // Force auto-dismiss after 6s even if the mouse is hovering over it.
    Future.delayed(const Duration(seconds: 6), () => controller.close());
  }

  /// Shows the add dialog, or the edit dialog when [existing] is provided.
  void _showTaskDialog(BuildContext context, {Task? existing}) {
    final bool isEditing = existing != null;
    final controller = TextEditingController(text: existing?.title ?? '');
    String taskTitle = existing?.title ?? '';
    String selectedCategory = existing?.category ?? 'Dates';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.dialogBg(context),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.favorite, color: AppColors.crimson),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit Memory' : 'Add New Memory',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.heading(context),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: AppColors.bodyText(context)),
                      decoration: InputDecoration(
                        hintText: 'What is your romantic plan? ...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: AppColors.pickerField(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.pink.shade100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.crimson, width: 2),
                        ),
                      ),
                      onChanged: (val) => taskTitle = val,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose Category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.heading(context),
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
                            selectedColor: AppColors.softPink(context),
                            checkmarkColor: AppColors.crimson,
                            labelStyle: TextStyle(
                              color: selectedCategory == 'Dates'
                                  ? AppColors.crimson
                                  : AppColors.bodyText(context),
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
                            selectedColor: AppColors.softPink(context),
                            checkmarkColor: AppColors.deepRose,
                            labelStyle: TextStyle(
                              color: selectedCategory == 'Personal'
                                  ? AppColors.deepRose
                                  : AppColors.bodyText(context),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(
                                    () => selectedCategory = 'Personal');
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
                    if (taskTitle.trim().isNotEmpty) {
                      if (isEditing) {
                        _updateTask(
                            existing.id, taskTitle.trim(), selectedCategory);
                      } else {
                        _addTask(taskTitle.trim(), selectedCategory);
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Add Plan',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
              color: AppColors.crimson.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            Text(
              'No memories planned here!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.heading(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the floating pink button below\nto add your next romantic goal.',
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
                Text('Remove Plan',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.delete_forever_rounded,
                    color: Colors.white, size: 28),
              ],
            ),
          ),
          child: TaskTile(
            task: task,
            onToggle: () => _toggleTask(task.id),
            onDelete: () => _deleteTask(task.id),
            onEdit: () => _showTaskDialog(context, existing: task),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = AppColors.isDark(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.scaffold(context),
          elevation: 0,
          actionsPadding: const EdgeInsets.only(right: 4),
          actions: [
            IconButton(
              tooltip: dark ? 'Light mode' : 'Dark mode',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: AppColors.crimson,
              ),
              onPressed: toggleThemeMode,
            ),
            IconButton(
              tooltip: 'Special Dates',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.celebration_rounded,
                  color: AppColors.crimson),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SpecialDatesScreen()),
                );
              },
            ),
          ],
          // FittedBox keeps the title from overflowing next to the actions.
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: AppColors.crimson, size: 22),
                const SizedBox(width: 8),
                Text(
                  'SiSi - NOTES',
                  style: TextStyle(
                    color: AppColors.heading(context),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.favorite, color: AppColors.crimson, size: 22),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.softPink(context).withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                // Scrollable so the four tabs never get squeezed.
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: const BoxDecoration(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.deepRose,
                labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(child: Text('All ✨')),
                  Tab(child: Text('Common 💞')),
                  Tab(child: Text('Dates 🌹')),
                  Tab(child: Text('Personal 👤')),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.crimson))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList('All'),
                  const CommonTab(),
                  _buildTaskList('Dates'),
                  _buildTaskList('Personal'),
                ],
              ),
        // Hide the "Add Plan" FAB on the Common tab (it has its own Write button).
        floatingActionButton: _tabController.index == _commonTabIndex
            ? null
            : FloatingActionButton.extended(
                heroTag: 'homeAdd',
                onPressed: () => _showTaskDialog(context),
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add_circle_rounded, size: 22),
                label: const Text('Add Plan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
      );
  }
}
