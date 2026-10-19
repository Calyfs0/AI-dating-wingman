import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../screenshot_reply/models/suggested_replies.dart';

enum HistoryKind { reply, opener }

class HistoryEntry extends Equatable {
  const HistoryEntry({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.natural,
    required this.playful,
    this.latestIncoming,
    this.hook,
    this.why,
    this.personId,
    this.personName,
  });

  final String id;
  final HistoryKind kind;
  final DateTime createdAt;
  final String natural;
  final String playful;
  final String? latestIncoming;
  final String? hook;
  final String? why;
  final String? personId;
  final String? personName;

  factory HistoryEntry.fromReplies({
    required HistoryKind kind,
    required SuggestedReplies replies,
    String? personId,
    String? personName,
  }) {
    return HistoryEntry(
      id: const Uuid().v4(),
      kind: kind,
      createdAt: DateTime.now(),
      natural: replies.natural,
      playful: replies.playful,
      latestIncoming: replies.latestIncoming,
      hook: replies.hook,
      why: replies.why,
      personId: personId,
      personName: personName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        'natural': natural,
        'playful': playful,
        'latestIncoming': latestIncoming,
        'hook': hook,
        'why': why,
        'personId': personId,
        'personName': personName,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String? ?? const Uuid().v4(),
      kind: HistoryKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => HistoryKind.reply,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      natural: json['natural'] as String? ?? '',
      playful: json['playful'] as String? ?? '',
      latestIncoming: json['latestIncoming'] as String?,
      hook: json['hook'] as String?,
      why: json['why'] as String?,
      personId: json['personId'] as String?,
      personName: json['personName'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        kind,
        createdAt,
        natural,
        playful,
        latestIncoming,
        hook,
        why,
        personId,
        personName,
      ];
}
