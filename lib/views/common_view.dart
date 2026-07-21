import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/common_note.dart';
import '../services/common_service.dart';
import '../services/couple_service.dart';
import '../theme/app_theme.dart';

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtWhen(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour < 12 ? 'AM' : 'PM';
  return '${_kMonths[d.month - 1]} ${d.day}, $h:$m $ap';
}

/// The shared "Common" area, embedded as a tab beside "All" on the home screen.
class CommonTab extends StatefulWidget {
  const CommonTab({super.key});

  @override
  State<CommonTab> createState() => _CommonTabState();
}

class _CommonTabState extends State<CommonTab> {
  String? _code;
  String? _name;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await CoupleService.load();
    if (!mounted) return;
    setState(() {
      _code = saved.code;
      _name = saved.name;
      _loading = false;
    });
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
    final bool paired = _code != null && _name != null;

    if (!CommonService.isReady) return _buildSetupNeeded();
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.crimson));
    }
    if (!paired) return _buildPairing();

    // Paired: the feed, a small "linked" header (replacing the old AppBar
    // action), and a floating Write button laid over it.
    return Stack(
      children: [
        Column(
          children: [
            _linkedHeader(),
            Expanded(child: _buildFeed()),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'commonWrite',
            onPressed: () => _showNoteDialog(),
            backgroundColor: AppColors.crimson,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: const Text('Write',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  /// Compact bar shown above the feed with the couple code + settings access.
  Widget _linkedHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.softPink(context).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: AppColors.crimson, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Linked · ${_code ?? ''}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.deepRose,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          InkWell(
            onTap: _showCodeSheet,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.qr_code_rounded,
                  color: AppColors.crimson, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- setup ----

  Widget _buildSetupNeeded() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 74, color: AppColors.crimson.withOpacity(0.15)),
            const SizedBox(height: 16),
            Text(
              'Common needs Firebase',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.heading(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To share notes between both phones the app needs a Firebase '
              'project. Add google-services.json (Android) and '
              'GoogleService-Info.plist (iOS), then restart the app.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ pairing ----

  Widget _buildPairing() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.favorite_rounded,
              size: 64, color: AppColors.crimson.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Link with your partner 💞',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.heading(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'One of you generates a code and shares it.\n'
            'The other types the same code here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 28),
          _field(nameCtrl, 'Your name', Icons.person_rounded),
          const SizedBox(height: 14),
          _field(codeCtrl, 'Couple code',
              Icons.vpn_key_rounded,
              caps: true),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  codeCtrl.text = CoupleService.generateCode(),
              icon: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.crimson),
              label: const Text('Generate a code',
                  style: TextStyle(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final code = CoupleService.normalise(codeCtrl.text);
              if (name.isEmpty || code.isEmpty) {
                _toast('Please enter your name and a couple code 💌');
                return;
              }
              await CoupleService.save(code: code, name: name);
              if (!mounted) return;
              setState(() {
                _name = name;
                _code = code;
              });
              _toast('Linked! You are both on $code 💞');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 1,
            ),
            child: const Text('Link us 💞',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool caps = false}) {
    return TextField(
      controller: c,
      textCapitalization:
          caps ? TextCapitalization.characters : TextCapitalization.words,
      style: TextStyle(color: AppColors.bodyText(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.crimson, size: 20),
        filled: true,
        fillColor: AppColors.pickerField(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.pink.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.crimson, width: 2),
        ),
      ),
    );
  }

  /// Shows the current code so it can be copied/shared, plus an unlink option.
  void _showCodeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dialogBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your couple code',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.heading(context))),
            const SizedBox(height: 12),
            SelectableText(
              _code ?? '',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.crimson,
              ),
            ),
            const SizedBox(height: 6),
            Text('Signed in as ${_name ?? ''}',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _code ?? ''));
                      Navigator.pop(sheetContext);
                      _toast('Code copied 📋');
                    },
                    icon: const Icon(Icons.copy_rounded,
                        size: 16, color: AppColors.crimson),
                    label: const Text('Copy',
                        style: TextStyle(
                            color: AppColors.crimson,
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.crimson),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await CoupleService.unpair();
                      if (!mounted) return;
                      setState(() {
                        _code = null;
                        _name = null;
                      });
                    },
                    icon: const Icon(Icons.link_off_rounded, size: 16),
                    label: const Text('Unlink',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- feed ----

  Widget _buildFeed() {
    return StreamBuilder<List<CommonNote>>(
      stream: CommonService.watch(_code!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Could not load the feed.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.crimson));
        }

        final notes = snapshot.data!;
        if (notes.isEmpty) return _buildEmptyFeed();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 90),
          itemCount: notes.length,
          itemBuilder: (context, i) => _buildNoteCard(notes[i]),
        );
      },
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_rounded,
              size: 84, color: AppColors.crimson.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'Nothing here yet!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.heading(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Write the first note — you\'ll both see it\ninstantly on each phone. 💌',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(CommonNote note) {
    final bool mine = note.author == _name;
    final bool done = note.isDone;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: done ? AppColors.doneCard(context) : AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: done
                ? Colors.transparent
                : (AppColors.isDark(context)
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFFF8BBD0).withOpacity(0.3)),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: done
              ? Colors.black12.withOpacity(0.04)
              : (mine
                  ? AppColors.crimson.withOpacity(0.35)
                  : AppColors.cardBorder(context)),
          width: 1.5,
        ),
      ),
      child: ListTile(
        // Tap the card to edit — both partners can edit any note here.
        onTap: () => _showNoteDialog(existing: note),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: done
                ? Colors.black12.withOpacity(0.05)
                : (mine
                    ? AppColors.leadingDates(context)
                    : AppColors.leadingPersonal(context)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              note.author.isEmpty ? '?' : note.author[0].toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: done ? AppColors.muted(context) : AppColors.crimson,
              ),
            ),
          ),
        ),
        title: Text(
          note.text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: done ? AppColors.muted(context) : AppColors.bodyText(context),
            decoration: done ? TextDecoration.lineThrough : null,
            decorationThickness: 2,
            decorationColor: const Color(0xFFE91E63).withOpacity(0.5),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${mine ? 'You' : note.author}  •  ${_fmtWhen(note.createdAt)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: done ? AppColors.muted(context) : AppColors.crimson,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mark done / undone (syncs to both phones)
            InkWell(
              onTap: () => CommonService.toggleDone(
                  code: _code!, id: note.id, isDone: !done),
              borderRadius: BorderRadius.circular(30),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: done
                    ? const Icon(Icons.favorite,
                        key: ValueKey('c_done'),
                        color: Colors.redAccent,
                        size: 28)
                    : const Icon(Icons.favorite_border,
                        key: ValueKey('c_undone'),
                        color: Color(0xFFEC407A),
                        size: 28),
              ),
            ),
            const SizedBox(width: 2),
            // Delete
            IconButton(
              tooltip: 'Delete',
              splashRadius: 20,
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppColors.muted(context), size: 22),
              onPressed: () async {
                await CommonService.delete(code: _code!, id: note.id);
                if (!mounted) return;
                _toast('Note removed.');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Write a new note, or edit one of your own when [existing] is given.
  void _showNoteDialog({CommonNote? existing}) {
    final bool isEditing = existing != null;
    final controller = TextEditingController(text: existing?.text ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.dialogBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.forum_rounded, color: AppColors.crimson),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'Edit note' : 'Write together',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.heading(context)),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppColors.bodyText(context)),
          decoration: InputDecoration(
            hintText: 'Say something to both of you… 💕',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: AppColors.pickerField(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.pink.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.crimson, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                if (isEditing) {
                  await CommonService.update(
                      code: _code!, id: existing.id, text: text);
                } else {
                  await CommonService.add(
                      code: _code!, text: text, author: _name!);
                }
              } catch (e) {
                if (!mounted) return;
                _toast('Could not save: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 1,
            ),
            child: Text(isEditing ? 'Save' : 'Post 💌',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
