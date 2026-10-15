import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ReplyTone { natural, playful }

extension ReplyToneLabel on ReplyTone {
  String get title => switch (this) {
        ReplyTone.natural => 'Natural',
        ReplyTone.playful => 'Playful',
      };

  String get subtitle => switch (this) {
        ReplyTone.natural => 'Casual, warm, and easy to send.',
        ReplyTone.playful => 'Soft tease with a human beat first.',
      };

  Color get accentColor => switch (this) {
        ReplyTone.natural => const Color(0xFF6FCF97),
        ReplyTone.playful => const Color(0xFFFF4EAB),
      };
}

class SuggestedReplies extends Equatable {
  const SuggestedReplies({
    required this.natural,
    required this.playful,
    this.latestIncoming,
  });

  final String natural;
  final String playful;
  final String? latestIncoming;

  String forTone(ReplyTone tone) => switch (tone) {
        ReplyTone.natural => natural,
        ReplyTone.playful => playful,
      };

  @override
  List<Object?> get props => [natural, playful, latestIncoming];
}
