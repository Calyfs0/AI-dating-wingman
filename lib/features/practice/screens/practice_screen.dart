import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../../screenshot_reply/widgets/mockup_components.dart';
import '../controllers/practice_controller.dart';
import '../models/practice_models.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<PracticeController>();
  }

  @override
  void dispose() {
    // Keep resumable session on pop — only clear a stuck in-flight turn.
    _controller.abandonInFlight();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PracticeController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        child: SafeArea(
          child: switch (c.phase) {
            PracticePhase.personas => const _PersonasView(),
            PracticePhase.topics => const _TopicsView(),
            PracticePhase.session => const _SessionView(),
            PracticePhase.feedback => const _FeedbackView(),
          },
        ),
      ),
    );
  }
}

class _PersonasView extends StatelessWidget {
  const _PersonasView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PracticeController>();
    final personas = c.visiblePersonas;
    final canPop = context.canPop();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        if (canPop)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => context.pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        Text(
          'Practice',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick who you’re texting. Low-stakes rehearsal — not a grade.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFFB9AEC8),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        _GenderToggle(
          value: c.genderFilter,
          onChanged: (g) {
            HapticFeedback.selectionClick();
            c.setGenderFilter(g);
          },
        ),
        const SizedBox(height: 20),
        for (var row = 0; row < personas.length; row += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = row; i < row + 2 && i < personas.length; i++) ...[
                Expanded(
                  child: _PersonaCard(
                    persona: personas[i],
                    selected: c.persona == personas[i],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      c.selectPersona(personas[i]);
                    },
                  ),
                ),
                if (i == row && i + 1 < personas.length)
                  const SizedBox(width: 10),
              ],
              if (row + 1 >= personas.length) const Expanded(child: SizedBox()),
            ],
          ),
          if (row + 2 < personas.length) const SizedBox(height: 10),
        ],
        const SizedBox(height: 28),
        NeonGenerateButton(
          label: c.persona == null
              ? 'Choose someone first'
              : 'Start chatting with ${c.persona!.name}',
          onPressed: c.persona == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  c.startWithPersona();
                },
        ),
      ],
    );
  }
}

class _GenderToggle extends StatelessWidget {
  const _GenderToggle({required this.value, required this.onChanged});

  final PracticeGender value;
  final ValueChanged<PracticeGender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xCC1A1016),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          for (final g in PracticeGender.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: value == g ? AppColors.accentGradient : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    g == PracticeGender.female ? 'Female' : 'Male',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: value == g
                          ? Colors.white
                          : const Color(0xFF9A8FA8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.persona,
    required this.selected,
    required this.onTap,
  });

  final PracticePersona persona;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? AppColors.neonPink
                  : Colors.white.withValues(alpha: 0.12),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.neonPink.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 0.78,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        persona.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF2A1F30),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  persona.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  persona.archetype,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neonPink
                                        .withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.neonPink,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xF01A1016),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Text(
                    persona.blurb,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.35,
                      color: const Color(0xFFB9AEC8),
                    ),
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

class _TopicsView extends StatelessWidget {
  const _TopicsView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PracticeController>();
    final name = c.partnerName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: c.backToPersonas,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Text(
                'Scene with $name',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: c.resetToIdle,
              child: Text(
                'New',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFB9AEC8),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pick a situation. Type like you would in the real chat.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFFB9AEC8),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        for (final topic in PracticeTopic.values) ...[
          _TopicCard(
            topic: topic,
            onTap: () {
              HapticFeedback.selectionClick();
              c.pickTopic(topic);
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.onTap});

  final PracticeTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xCC1A1016),
            border: Border.all(
              color: AppColors.neonPink.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topic.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF9A8FA8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.neonPink.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionView extends StatefulWidget {
  const _SessionView();

  @override
  State<_SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<_SessionView> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PracticeController>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: c.backToTopics,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      c.topic?.title ?? 'Practice',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'with ${c.partnerName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF9A8FA8),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: c.isBusy
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        c.endSession();
                      },
                child: Text(
                  'End',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFB9AEC8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (c.sceneHint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              c.sceneHint!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF9A8FA8),
              ),
            ),
          ),
        Expanded(
          child: c.turns.isEmpty
              ? Center(
                  child: Text(
                    'Type like you would in the real chat.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFB9AEC8),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  itemCount: c.turns.length,
                  itemBuilder: (context, i) {
                    final turn = c.turns[i];
                    return Align(
                      alignment: turn.fromUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: const BoxConstraints(maxWidth: 300),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: turn.fromUser
                              ? const Color(0xE63A1830)
                              : const Color(0xE6282234),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: turn.fromUser
                                ? AppColors.neonPink.withValues(alpha: 0.5)
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          turn.text,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (c.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              c.errorMessage!,
              style: GoogleFonts.plusJakartaSans(color: AppColors.danger),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: !c.isBusy,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Your reply…',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF7E738F),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF22182A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _send(c),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: c.isBusy ? null : () => _send(c),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.neonPink,
                  foregroundColor: Colors.white,
                ),
                icon: c.isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _send(PracticeController c) {
    final text = _ctrl.text;
    _ctrl.clear();
    c.send(text);
  }
}

class _FeedbackView extends StatelessWidget {
  const _FeedbackView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PracticeController>();
    final fb = c.feedback!;
    final name = c.partnerName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          'Session wrap',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'One possible read of this rehearsal — not proof you’ll crush the real chat.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF9A8FA8),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          fb.summary,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: const Color(0xFFD4C8DE),
            height: 1.4,
          ),
        ),
        if (fb.tips.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Notices',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          for (final tip in fb.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '· $tip',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFB9AEC8),
                  height: 1.35,
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          '$name isn’t every person. Use this for reps, not as a guarantee.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF7E738F),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        NeonGenerateButton(
          label: 'Done — new session',
          onPressed: () {
            HapticFeedback.mediumImpact();
            c.resetToIdle();
          },
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: c.backToTopics,
          child: Text(
            'Try another scene',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFB9AEC8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: c.backToPersonas,
          child: Text(
            'Switch person',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFB9AEC8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
