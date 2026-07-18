import 'package:flutter/material.dart';

import '../models/special_date.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

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

/// Screen listing the user's special dates with add/remove + reminder scheduling.
class SpecialDatesScreen extends StatefulWidget {
  const SpecialDatesScreen({super.key});

  @override
  State<SpecialDatesScreen> createState() => _SpecialDatesScreenState();
}

class _SpecialDatesScreenState extends State<SpecialDatesScreen> {
  List<SpecialDate> _dates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermissions();
    });
  }

  Future<void> _load() async {
    try {
      _dates = await SpecialDate.loadAll();
    } catch (e) {
      debugPrint('Error loading special dates: $e');
    }
    _sort();
    setState(() => _loading = false);
  }

  void _sort() =>
      _dates.sort((a, b) => a.nextOccurrence().compareTo(b.nextOccurrence()));

  Future<void> _save() => SpecialDate.saveAll(_dates);

  Future<void> _addDate(
      String title, String type, DateTime dateTime, bool repeatYearly) async {
    final date = SpecialDate(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      type: type,
      dateTime: dateTime,
      notifId: DateTime.now().microsecondsSinceEpoch.remainder(1 << 30),
      repeatYearly: repeatYearly,
    );
    setState(() {
      _dates.add(date);
      _sort();
    });
    await _save();
    await NotificationService.instance.schedule(date);

    if (!mounted) return;
    _toast('${date.emoji} Reminder set for "${date.title}" 💖');
  }

  Future<void> _deleteDate(SpecialDate date) async {
    await NotificationService.instance.cancel(date);
    setState(() => _dates.removeWhere((d) => d.id == date.id));
    await _save();

    if (!mounted) return;
    _toast('"${date.title}" reminder removed.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.snackPlum,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.crimson),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded,
                color: AppColors.crimson, size: 22),
            const SizedBox(width: 8),
            Text(
              'Special Dates',
              style: TextStyle(
                color: AppColors.heading(context),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.crimson))
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
        backgroundColor: AppColors.crimson,
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
            color: AppColors.crimson.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No special dates yet!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.heading(context),
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
    final bool passed = date.isPast;
    final DateTime effective = date.nextOccurrence();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: passed ? AppColors.doneCard(context) : AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: passed
                ? Colors.transparent
                : (AppColors.isDark(context)
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFFF8BBD0).withOpacity(0.3)),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: passed
              ? Colors.black12.withOpacity(0.04)
              : AppColors.cardBorder(context),
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
                : AppColors.leadingDates(context),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(date.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                date.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: passed
                      ? AppColors.muted(context)
                      : AppColors.bodyText(context),
                ),
              ),
            ),
            if (date.repeatYearly)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.autorenew_rounded,
                    size: 15, color: AppColors.crimson.withOpacity(0.8)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 12,
                  color: passed ? AppColors.muted(context) : AppColors.crimson),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${_fmtDate(effective)}  •  ${_fmtTime(effective)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        passed ? AppColors.muted(context) : AppColors.crimson,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: passed
                    ? Colors.grey.withOpacity(0.2)
                    : AppColors.softPink(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _countdownLabel(effective),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      passed ? AppColors.muted(context) : AppColors.deepRose,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _deleteDate(date),
              tooltip: 'Delete',
              splashRadius: 20,
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppColors.muted(context), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  /// Themed builder so the native date/time pickers match the palette.
  Widget _picker(BuildContext context, Widget? child) {
    final bool dark = AppColors.isDark(context);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: (dark
                ? const ColorScheme.dark(
                    primary: AppColors.crimson,
                    onPrimary: Colors.white,
                    surface: Color(0xFF241820),
                  )
                : const ColorScheme.light(
                    primary: AppColors.crimson,
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF880E4F),
                  ))
            ,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.crimson),
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
    bool repeatYearly = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final String dateLabel =
                pickedDate == null ? 'Pick a date' : _fmtDate(pickedDate!);
            final String timeLabel = pickedTime == null
                ? 'Pick a time'
                : _fmtTime(DateTime(
                    0, 1, 1, pickedTime!.hour, pickedTime!.minute));

            return AlertDialog(
              backgroundColor: AppColors.dialogBg(context),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.celebration_rounded,
                      color: AppColors.crimson),
                  const SizedBox(width: 8),
                  Text(
                    'Add Special Date',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.heading(context)),
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
                      style: TextStyle(color: AppColors.bodyText(context)),
                      decoration: InputDecoration(
                        hintText: 'e.g. Our first date 💞',
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
                      onChanged: (v) => title = v,
                    ),
                    const SizedBox(height: 18),
                    Text('Type',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.heading(context))),
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
                          selectedColor: AppColors.softPink(context),
                          checkmarkColor: AppColors.crimson,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.crimson
                                : AppColors.bodyText(context),
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
                                // Yearly dates (birthdays) may be in the past.
                                firstDate: repeatYearly
                                    ? DateTime(1900)
                                    : now,
                                lastDate: DateTime(now.year + 10),
                                builder: _picker,
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
                                initialTime: pickedTime ?? TimeOfDay.now(),
                                builder: _picker,
                              );
                              if (t != null) {
                                setDialogState(() => pickedTime = t);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: AppColors.crimson,
                      title: Text(
                        'Repeat every year 🔁',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.heading(context),
                        ),
                      ),
                      subtitle: Text(
                        'For birthdays & anniversaries',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                      value: repeatYearly,
                      onChanged: (v) =>
                          setDialogState(() => repeatYearly = v),
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
                    // One-off dates must be in the future; yearly ones roll
                    // forward on their own, so a past birthday is fine.
                    if (!repeatYearly && !dt.isAfter(DateTime.now())) {
                      _toast('Please pick a moment in the future ⏰');
                      return;
                    }
                    Navigator.pop(context);
                    _addDate(title.trim(), selectedType, dt, repeatYearly);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
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
          color: AppColors.pickerField(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: chosen ? AppColors.crimson : Colors.pink.shade100,
            width: chosen ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.crimson),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: chosen
                      ? AppColors.heading(context)
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
