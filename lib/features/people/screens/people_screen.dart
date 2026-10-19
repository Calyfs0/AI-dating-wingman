import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../controllers/people_controller.dart';
import '../models/person.dart';
import '../widgets/person_coach_sheets.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PeopleController>();
    final people = controller.people;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'People',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Light reminders — name + status, on this device only.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFFB9AEC8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: !controller.loaded
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.neonPink,
                            ),
                          )
                        : people.isEmpty
                            ? _EmptyPeople(
                                onAdd: () => _showPersonSheet(context),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  88,
                                ),
                                itemCount: people.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final person = people[index];
                                  return _PersonCard(
                                    person: person,
                                    onTap: () => _showPersonSheet(
                                      context,
                                      person: person,
                                    ),
                                    onLongPress: () =>
                                        _confirmDelete(context, person),
                                  );
                                },
                              ),
                  ),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 16,
                child: _NewPersonFab(
                  onPressed: () => _showPersonSheet(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Person person) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1324),
        title: Text(
          'Remove ${person.name}?',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        content: Text(
          'This only clears them from your local list.',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFFB9AEC8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: GoogleFonts.plusJakartaSans(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<PeopleController>().removePerson(person.id);
    }
  }

  Future<void> _showPersonSheet(
    BuildContext context, {
    Person? person,
  }) async {
    final nameCtrl = TextEditingController(text: person?.name ?? '');
    final noteCtrl = TextEditingController(text: person?.note ?? '');
    var status = person?.status ?? PersonStatus.yourMove;
    final isEdit = person != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xF016101C),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.neonPink.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isEdit ? 'Edit' : 'Add someone',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Just for you — not shared with Reply or Openers unless you attach them.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF9A8FA8),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Field(
                            controller: nameCtrl,
                            hint: 'Name',
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: noteCtrl,
                            hint: 'Optional note (private)',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Status',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB9AEC8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: PersonStatus.values.map((s) {
                              final selected = status == s;
                              return ChoiceChip(
                                label: Text(s.label),
                                selected: selected,
                                onSelected: (_) => setModal(() => status = s),
                                selectedColor:
                                    AppColors.neonPink.withValues(alpha: 0.28),
                                backgroundColor: const Color(0xFF22182A),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFFB9AEC8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.neonPink
                                      : Colors.white12,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () async {
                                  final name = nameCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  HapticFeedback.lightImpact();
                                  final people =
                                      context.read<PeopleController>();
                                  if (isEdit) {
                                    await people.updatePerson(
                                      person.copyWith(
                                        name: name,
                                        note: noteCtrl.text.trim(),
                                        status: status,
                                      ),
                                    );
                                  } else {
                                    await people.addPerson(
                                      name: name,
                                      status: status,
                                      note: noteCtrl.text.trim(),
                                    );
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: SizedBox(
                                  height: 52,
                                  child: Center(
                                    child: Text(
                                      isEdit ? 'Save' : 'Add person',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isEdit) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                showPersonBriefingSheet(
                                  context,
                                  person: person,
                                );
                              },
                              child: Text(
                                'Quick tip (optional)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFB9AEC8),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                if (context.mounted) {
                                  await _confirmDelete(context, person);
                                }
                              },
                              child: Text(
                                'Remove',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    noteCtrl.dispose();
  }
}

class _EmptyPeople extends StatelessWidget {
  const _EmptyPeople({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 40,
              color: AppColors.neonPink.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            Text(
              'Nobody here yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a name when it helps you remember whose turn it is. Totally optional — Reply works without it.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFB9AEC8),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onAdd,
              child: Text(
                'Add someone',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonPink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.person,
    required this.onTap,
    required this.onLongPress,
  });

  final Person person;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  Color get _statusColor => switch (person.status) {
        PersonStatus.yourMove => AppColors.neonPink,
        PersonStatus.waiting => const Color(0xFFF2C94C),
        PersonStatus.quiet => const Color(0xFF7E738F),
      };

  @override
  Widget build(BuildContext context) {
    final initial = person.name.trim().isEmpty
        ? '?'
        : String.fromCharCode(person.name.trim().runes.first).toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xCC1A1016),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonPink.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppColors.neonPink.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        person.status.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7E738F),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewPersonFab extends StatelessWidget {
  const _NewPersonFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPink.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Add',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: GoogleFonts.plusJakartaSans(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF7E738F)),
        filled: true,
        fillColor: const Color(0xFF22182A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.neonPink.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.neonPink.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neonPink),
        ),
      ),
    );
  }
}
