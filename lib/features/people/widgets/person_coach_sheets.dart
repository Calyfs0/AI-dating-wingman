import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../history/controllers/history_controller.dart';
import '../models/person.dart';
import '../services/people_coach_service.dart';

Future<void> showPersonBriefingSheet(
  BuildContext context, {
  required Person person,
}) async {
  final history = context.read<HistoryController>();
  final coach = context.read<PeopleCoachService>();
  final snippets = history
      .forPerson(person.id)
      .take(5)
      .map((e) => e.natural)
      .toList();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xF016101C),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return FutureBuilder(
        future: coach.briefing(
          person: person,
          historySnippets: snippets,
        ),
        builder: (ctx, snap) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: snap.connectionState != ConnectionState.done
                ? const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neonPink,
                      ),
                    ),
                  )
                : snap.hasError
                    ? Text(
                        snap.error is AppException
                            ? (snap.error as AppException).message
                            : "Couldn't build a briefing.",
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.danger,
                        ),
                      )
                    : _BriefingBody(person: person, briefing: snap.data!),
          );
        },
      );
    },
  );
}

class _BriefingBody extends StatelessWidget {
  const _BriefingBody({required this.person, required this.briefing});

  final Person person;
  final DateBriefing briefing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Briefing · ${person.name}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          _Section('What you know', briefing.whatYouKnow),
          _Section('Good topics', briefing.goodTopics),
          _Section('Maybe skip', briefing.avoid),
          if (briefing.challenge.isNotEmpty) ...[
            Text(
              'Soft challenge',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.neonPink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              briefing.challenge,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFB9AEC8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.items);
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in items)
            Text(
              '· $item',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFB9AEC8),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showPersonDebriefSheet(
  BuildContext context, {
  required Person person,
}) async {
  final notesCtrl = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xF016101C),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Debrief · ${person.name}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 4,
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'How did it go?',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF7E738F),
                ),
                filled: true,
                fillColor: const Color(0xFF22182A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.neonPink,
                minimumSize: const Size(0, 48),
              ),
              onPressed: () async {
                final notes = notesCtrl.text.trim();
                if (notes.isEmpty) return;
                final history = context.read<HistoryController>();
                final snippets = history
                    .forPerson(person.id)
                    .take(5)
                    .map((e) => e.natural)
                    .toList();
                try {
                  final result = await context.read<PeopleCoachService>().debrief(
                    person: person,
                    notes: notes,
                    historySnippets: snippets,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!context.mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (d) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1324),
                      title: Text(
                        'Next move',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.tip,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9AEC8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final m in result.nextMoves)
                            Text(
                              '· $m',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        e is AppException
                            ? e.message
                            : "Couldn't debrief. Try again.",
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Get a tip',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    },
  );
  notesCtrl.dispose();
}
