import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ReplyTone { natural, playful, confident }

extension ReplyToneLabel on ReplyTone {
  String get title => switch (this) {
        ReplyTone.natural => 'Natural',
        ReplyTone.playful => 'Playful',
        ReplyTone.confident => 'Confident',
      };

  String get subtitle => switch (this) {
        ReplyTone.natural => 'Casual, warm, and easy to send.',
        ReplyTone.playful => 'Soft tease with a human beat first.',
        ReplyTone.confident => 'Direct and chill — not a speech.',
      };

  Color get accentColor => switch (this) {
        ReplyTone.natural => const Color(0xFF6FCF97),
        ReplyTone.playful => const Color(0xFFFF4EAB),
        ReplyTone.confident => const Color(0xFFF2C94C),
      };
}

class SuggestedReplies extends Equatable {
  const SuggestedReplies({
    required this.natural,
    required this.playful,
    required this.confident,
    this.latestIncoming,
  });

  final String natural;
  final String playful;
  final String confident;
  final String? latestIncoming;

  String forTone(ReplyTone tone) => switch (tone) {
        ReplyTone.natural => natural,
        ReplyTone.playful => playful,
        ReplyTone.confident => confident,
      };

  @override
  List<Object?> get props => [natural, playful, confident, latestIncoming];
}
