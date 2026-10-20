import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../people/controllers/people_controller.dart';
import '../../people/models/person.dart';

/// Post-copy retention loop: confirm send → mark person Waiting.
Future<void> showSentItSheet(
  BuildContext context, {
  Person? attachedPerson,
  required String copiedText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SentItSheet(
      attachedPerson: attachedPerson,
      copiedText: copiedText,
    ),
  );
}

class _SentItSheet extends StatefulWidget {
  const _SentItSheet({
    required this.attachedPerson,
    required this.copiedText,
  });

  final Person? attachedPerson;
  final String copiedText;

  @override
  State<_SentItSheet> createState() => _SentItSheetState();
}

class _SentItSheetState extends State<_SentItSheet> {
  bool _saving = false;
  String? _pickedPersonId;
  String? _error;
  late final TextEditingController _newNameCtrl;

  @override
  void initState() {
    super.initState();
    _newNameCtrl = TextEditingController();
    _pickedPersonId = widget.attachedPerson?.id;
  }

  @override
  void dispose() {
    _newNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSent() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    final people = context.read<PeopleController>();
    var pickedId = _pickedPersonId ?? widget.attachedPerson?.id;
    Person? marked;

    if (pickedId == null) {
      final name = _newNameCtrl.text.trim();
      if (name.isEmpty) {
        setState(() {
          _saving = false;
          _error = 'Pick someone — or type a name — so we can mark Waiting.';
        });
        return;
      }
      marked = await people.addPerson(
        name: name,
        status: PersonStatus.waiting,
      );
      pickedId = marked?.id;
    } else {
      await people.markWaiting(pickedId);
      for (final p in people.people) {
        if (p.id == pickedId) {
          marked = p;
          break;
        }
      }
      marked ??= widget.attachedPerson;
    }

    if (!mounted) return;
    if (marked == null) {
      setState(() {
        _saving = false;
        _error = 'Couldn’t save who you sent it to. Try again.';
      });
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nice. ${marked.name} is on Waiting.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final people = context.watch<PeopleController>().people;
    final name = widget.attachedPerson?.name;
    final needsPick = widget.attachedPerson == null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xEE160E18),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(
                color: AppColors.neonPink.withValues(alpha: 0.28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Did you send it?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name != null
                          ? 'If you sent that line to $name, we’ll mark them Waiting so Kehlo knows it’s their move.'
                          : 'Pick who you sent it to — we’ll nudge you when it’s your move again.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFFD4C8DE),
                        height: 1.35,
                      ),
                    ),
                    if (needsPick && people.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in people.take(8))
                            ChoiceChip(
                              label: Text(p.name),
                              selected: _pickedPersonId == p.id,
                              onSelected: (_) => setState(() {
                                _pickedPersonId =
                                    _pickedPersonId == p.id ? null : p.id;
                                _error = null;
                              }),
                              selectedColor:
                                  AppColors.neonPink.withValues(alpha: 0.35),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              backgroundColor: const Color(0xFF2A1830),
                              side: BorderSide(
                                color: _pickedPersonId == p.id
                                    ? AppColors.neonPink
                                    : Colors.white24,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (needsPick && _pickedPersonId == null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        decoration: InputDecoration(
                          hintText: people.isEmpty
                              ? 'Who did you send it to?'
                              : 'Or type a new name',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF9A8FA8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2A1830),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _saving ? null : _onSent,
                          child: SizedBox(
                            height: 52,
                            child: Center(
                              child: Text(
                                'Yes — I sent it',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Not yet',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
