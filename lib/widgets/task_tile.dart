import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

/// Interactive romantic task card with a done-toggle and a delete button.
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  /// Tapping the card body edits the note — keeps the design clean by
  /// avoiding an extra edit icon on every tile.
  final VoidCallback onEdit;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = AppColors.isDark(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: task.isDone ? AppColors.doneCard(context) : AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: task.isDone
                ? Colors.transparent
                : (dark
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFFF8BBD0).withOpacity(0.3)),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: task.isDone
              ? Colors.black12.withOpacity(0.04)
              : AppColors.cardBorder(context),
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onEdit,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: task.isDone
                ? Colors.black12.withOpacity(0.05)
                : (task.category == 'Dates'
                    ? AppColors.leadingDates(context)
                    : AppColors.leadingPersonal(context)),
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
            color: task.isDone ? AppColors.muted(context) : AppColors.bodyText(context),
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
                task.category == 'Dates'
                    ? Icons.favorite_border
                    : Icons.person_outline_rounded,
                size: 12,
                color: task.isDone ? AppColors.muted(context) : AppColors.crimson,
              ),
              const SizedBox(width: 4),
              Text(
                task.category,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: task.isDone ? AppColors.muted(context) : AppColors.crimson,
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
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: task.isDone
                    ? const Icon(
                        Icons.favorite,
                        key: ValueKey('done_icon'),
                        color: Colors.redAccent,
                        size: 32,
                      )
                    : const Icon(
                        Icons.favorite_border,
                        key: ValueKey('undone_icon'),
                        color: Color(0xFFEC407A),
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
                color: AppColors.muted(context),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
