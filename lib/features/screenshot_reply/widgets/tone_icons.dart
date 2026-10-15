import 'package:flutter/material.dart';

import '../models/suggested_replies.dart';

/// Tone icons from design assets (leaf / flame).
class ToneIcon extends StatelessWidget {
  const ToneIcon({super.key, required this.tone, this.size = 20});

  final ReplyTone tone;
  final double size;

  String get _asset => switch (tone) {
        ReplyTone.natural => 'assets/icons/icon_leaf.png',
        ReplyTone.playful => 'assets/icons/icon_flame.png',
      };

  Widget _assetImage() {
    return Image.asset(
      _asset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        switch (tone) {
          ReplyTone.natural => Icons.eco_rounded,
          ReplyTone.playful => Icons.local_fire_department_rounded,
        },
        size: size * 0.7,
        color: tone.accentColor,
      ),
    );
  }

  Widget _tintBloom({
    required Color color,
    required double scale,
    required double opacity,
  }) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ColorFilter.mode(
          color.withValues(alpha: 0.9),
          BlendMode.srcIn,
        ),
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: _assetImage(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fire: yellow glow inside, pink glow outside.
    if (tone == ReplyTone.playful) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _tintBloom(
              color: const Color(0xFFFF4EAB),
              scale: 1.2,
              opacity: 0.4,
            ),
            _tintBloom(
              color: const Color(0xFFFF7AC2),
              scale: 1.1,
              opacity: 0.35,
            ),
            _tintBloom(
              color: const Color(0xFFFFDC50),
              scale: 0.95,
              opacity: 0.5,
            ),
            _tintBloom(
              color: const Color(0xFFFFF2B0),
              scale: 0.88,
              opacity: 0.3,
            ),
            _assetImage(),
          ],
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: _assetImage(),
    );
  }
}
