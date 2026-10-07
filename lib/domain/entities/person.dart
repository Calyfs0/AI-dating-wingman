import 'package:equatable/equatable.dart';

enum PersonStatus { active, waiting, quiet, dating }

enum PersonFilter { all, active, dates }

extension PersonStatusLabel on PersonStatus {
  String get label => switch (this) {
        PersonStatus.active => 'Active',
        PersonStatus.waiting => 'Waiting for reply',
        PersonStatus.quiet => 'No recent activity',
        PersonStatus.dating => 'Date planned',
      };

  String get momentumLabel => switch (this) {
        PersonStatus.active => 'Good momentum',
        PersonStatus.waiting => 'Waiting for reply',
        PersonStatus.quiet => 'No recent activity',
        PersonStatus.dating => 'Date planned',
      };
}

class Person extends Equatable {
  const Person({
    required this.id,
    required this.name,
    this.platform = 'Hinge',
    this.status = PersonStatus.active,
    this.avatarUrl,
    this.latestContext,
    this.keyFacts = const [],
    this.timeline = const [],
    this.lastActivityAt,
    this.relationshipStatus,
  });

  final String id;
  final String name;
  final String platform;
  final PersonStatus status;
  final String? avatarUrl;
  final String? latestContext;
  final List<String> keyFacts;
  final List<PersonTimelineEvent> timeline;
  final DateTime? lastActivityAt;
  final String? relationshipStatus;

  Person copyWith({
    String? id,
    String? name,
    String? platform,
    PersonStatus? status,
    String? avatarUrl,
    String? latestContext,
    List<String>? keyFacts,
    List<PersonTimelineEvent>? timeline,
    DateTime? lastActivityAt,
    String? relationshipStatus,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      latestContext: latestContext ?? this.latestContext,
      keyFacts: keyFacts ?? this.keyFacts,
      timeline: timeline ?? this.timeline,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        platform,
        status,
        avatarUrl,
        latestContext,
        keyFacts,
        timeline,
        lastActivityAt,
        relationshipStatus,
      ];
}

class PersonTimelineEvent extends Equatable {
  const PersonTimelineEvent({
    required this.id,
    required this.label,
    this.at,
  });

  final String id;
  final String label;
  final DateTime? at;

  @override
  List<Object?> get props => [id, label, at];
}
