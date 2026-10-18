import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/gotchu_logo.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../splash_chat_lines.dart';
import '../splash_sfx.dart';

/// Splash story:
/// 1) their message types in
/// 2) your bubble waits
/// 3) Gotchu + suggested reply slide up and land in your bubble
/// 4) Gotchu pushes the chat up / away — only Gotchu remains
class GotchuSplashScreen extends StatefulWidget {
  const GotchuSplashScreen({super.key, this.onFinished});

  /// Called once the splash beat finishes (so bootstrap can leave promptly).
  final VoidCallback? onFinished;

  @override
  State<GotchuSplashScreen> createState() => _GotchuSplashScreenState();
}

class _GotchuSplashScreenState extends State<GotchuSplashScreen>
    with SingleTickerProviderStateMixin {
  /// Post-type stages (bubble → suggest → grow → brief hold).
  static const _afterTypingMs = 4200;

  late final SplashChatPair _pair;
  late final AnimationController _controller;
  final SplashSfx _sfx = SplashSfx();

  late final List<int> _keyAtMs;
  late final int _typingDoneMs;
  late final int _totalMs;

  int _visibleChars = 0;
  bool _suggestSfx = false;
  bool _logoSfx = false;
  bool _finishedNotified = false;

  String get _theirMessage => _pair.incoming;
  String get _suggestion => _pair.suggestion;

  @override
  void initState() {
    super.initState();
    _pair = randomSplashChatPair();
    _keyAtMs = _buildKeyTimeline(_theirMessage);
    _typingDoneMs = _keyAtMs.isEmpty ? 400 : _keyAtMs.last;
    _totalMs = _typingDoneMs + _afterTypingMs;
    _sfx.init();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs),
    )..addListener(_onTick)..addStatusListener((status) {
        if (status == AnimationStatus.completed) _notifyFinished();
      })..forward();
  }

  void _notifyFinished() {
    if (_finishedNotified) return;
    _finishedNotified = true;
    widget.onFinished?.call();
  }

  static List<int> _buildKeyTimeline(String message) {
    final rng = math.Random(11);
    final times = <int>[];
    var t = 320;
    for (var i = 0; i < message.length; i++) {
      var gap = 110 + rng.nextInt(28);
      if (message[i] == ' ') gap += 36;
      t += gap;
      times.add(t);
    }
    return times;
  }

  int get _youBubbleAt => _typingDoneMs + 360;
  int get _suggestStart => _youBubbleAt + 480;
  int get _suggestLanded => _suggestStart + 780;
  int get _pushStart => _suggestLanded + 420;
  int get _logoSolo => _pushStart + 720;

  void _onTick() {
    final ms = (_controller.value * _totalMs).round();

    while (_visibleChars < _theirMessage.length &&
        ms >= _keyAtMs[_visibleChars]) {
      final ch = _theirMessage[_visibleChars];
      _visibleChars++;
      _sfx.typeKey(ch);
    }

    if (!_suggestSfx && ms >= _suggestStart) {
      _suggestSfx = true;
      _sfx.swish();
    }
    if (!_logoSfx && ms >= _logoSolo) {
      _logoSfx = true;
      _sfx.logoPop();
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    _sfx.dispose();
    super.dispose();
  }

  double _phase(double ms, double start, double end) {
    if (ms <= start) return 0;
    if (ms >= end) return 1;
    return ((ms - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ms = _controller.value * _totalMs;

    final typed = _theirMessage.substring(0, _visibleChars);
    final typing = _visibleChars < _theirMessage.length;
    final showCaret = typing && (ms / 80).floor().isEven;

    final youBubbleIn = Curves.easeOut.transform(
      _phase(ms, _youBubbleAt.toDouble(), _youBubbleAt + 280.0),
    );

    // Suggestion rises; same Gotchu grows from small → hero.
    final rise = Curves.easeOutCubic.transform(
      _phase(ms, _suggestStart.toDouble(), _suggestLanded.toDouble()),
    );
    final suggestionVisible = rise > 0.02;

    final push = Curves.easeInOutCubic.transform(
      _phase(ms, _pushStart.toDouble(), _logoSolo.toDouble()),
    );
    final grow = Curves.easeOutCubic.transform(
      _phase(ms, _pushStart.toDouble(), _logoSolo.toDouble()),
    );
    final chatSlideUp = -push * (size.height * 0.42);
    final chatFade = (1.0 - push).clamp(0.0, 1.0);

    // One Gotchu: rise from below (small) → land near bubble → grow to center.
    final gotchuOpacity = rise.clamp(0.0, 1.0);
    final gotchuAlignment = Alignment.lerp(
      const Alignment(0.55, 0.85), // below
      Alignment.lerp(
        const Alignment(0.55, 0.22), // beside your bubble
        Alignment.center, // hero
        grow,
      )!,
      rise,
    )!;
    // Ends large on screen — mini ~0.55 → hero ~1.35 on a big script size.
    final gotchuScale = 0.55 + rise * 0.05 + grow * 0.75;
    final logoFontSize = 36.0 + grow * 40.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DesireBackdrop(
        readabilityScrim: true,
        child: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Chat column (slides up & fades)
              Opacity(
                opacity: chatFade,
                child: Transform.translate(
                  offset: Offset(0, chatSlideUp),
                  child: Align(
                    alignment: const Alignment(0, -0.06),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _ChatBubble(
                              side: _BubbleSide.incoming,
                              child: Text.rich(
                                TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.35,
                                  ),
                                  children: [
                                    TextSpan(text: typed),
                                    if (showCaret)
                                      TextSpan(
                                        text: '|',
                                        style: TextStyle(
                                          color: AppColors.neonPink
                                              .withValues(alpha: 0.95),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Opacity(
                            opacity: youBubbleIn,
                            child: Transform.translate(
                              offset: Offset(0, 8 * (1 - youBubbleIn)),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _ChatBubble(
                                  side: _BubbleSide.outgoing,
                                  child: AnimatedSize(
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.centerLeft,
                                    child: suggestionVisible
                                        ? Text(
                                            _suggestion,
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                              height: 1.35,
                                            ),
                                          )
                                        : Text(
                                            '…',
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFFFD0E8)
                                                  .withValues(alpha: 0.55),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Same Gotchu mark — rises with the suggestion, then grows.
              if (gotchuOpacity > 0.01)
                Opacity(
                  opacity: gotchuOpacity,
                  child: Align(
                    alignment: gotchuAlignment,
                    child: Transform.scale(
                      scale: gotchuScale,
                      child: GotchuLogo(fontSize: logoFontSize),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BubbleSide { incoming, outgoing }

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.side,
    required this.child,
  });

  final _BubbleSide side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final incoming = side == _BubbleSide.incoming;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300, minWidth: 72),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      decoration: BoxDecoration(
        color: incoming ? const Color(0xE6282234) : const Color(0xE63A1830),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(incoming ? 6 : 18),
          bottomRight: Radius.circular(incoming ? 18 : 6),
        ),
        border: Border.all(
          color: incoming
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.neonPink.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: incoming
                ? Colors.black.withValues(alpha: 0.35)
                : AppColors.neonPink.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
