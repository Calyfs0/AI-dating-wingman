import 'package:equatable/equatable.dart';
import 'communication_style.dart';

enum DatingGoal {
  casual,
  serious,
  meetingPeople,
  confidence,
}

enum FocusArea {
  conversations,
  confidence,
  dating,
  meetPeople,
}

extension DatingGoalLabel on DatingGoal {
  String get label => switch (this) {
        DatingGoal.casual => 'Casual dating',
        DatingGoal.serious => 'Serious relationship',
        DatingGoal.meetingPeople => 'Meeting new people',
        DatingGoal.confidence => 'Just improving my confidence',
      };
}

extension FocusAreaCopy on FocusArea {
  String get title => switch (this) {
        FocusArea.conversations => 'Conversations',
        FocusArea.confidence => 'Confidence',
        FocusArea.dating => 'Dating',
        FocusArea.meetPeople => 'Meet People',
      };

  String get subtitle => switch (this) {
        FocusArea.conversations => 'Know what to say.',
        FocusArea.confidence => 'Understand what\'s happening.',
        FocusArea.dating => 'Move conversations toward real dates.',
        FocusArea.meetPeople => 'Improve my dating confidence.',
      };
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    this.displayName = 'You',
    this.focusAreas = const [],
    this.communicationStyles = const [],
    this.flirtingLevel = 0.5,
    this.datingGoal,
    this.onboardingCompleted = false,
    this.notificationsEnabled = false,
    this.isAnonymous = true,
    this.planLabel = 'Free plan',
    this.learnedStyle = const CommunicationStyle(),
    this.createdAt,
  });

  final String id;
  final String displayName;
  final List<FocusArea> focusAreas;
  final List<String> communicationStyles;
  final double flirtingLevel;
  final DatingGoal? datingGoal;
  final bool onboardingCompleted;
  final bool notificationsEnabled;
  final bool isAnonymous;
  final String planLabel;
  final CommunicationStyle learnedStyle;
  final DateTime? createdAt;

  UserProfile copyWith({
    String? id,
    String? displayName,
    List<FocusArea>? focusAreas,
    List<String>? communicationStyles,
    double? flirtingLevel,
    DatingGoal? datingGoal,
    bool? onboardingCompleted,
    bool? notificationsEnabled,
    bool? isAnonymous,
    String? planLabel,
    CommunicationStyle? learnedStyle,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      focusAreas: focusAreas ?? this.focusAreas,
      communicationStyles: communicationStyles ?? this.communicationStyles,
      flirtingLevel: flirtingLevel ?? this.flirtingLevel,
      datingGoal: datingGoal ?? this.datingGoal,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      planLabel: planLabel ?? this.planLabel,
      learnedStyle: learnedStyle ?? this.learnedStyle,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        focusAreas,
        communicationStyles,
        flirtingLevel,
        datingGoal,
        onboardingCompleted,
        notificationsEnabled,
        isAnonymous,
        planLabel,
        learnedStyle,
        createdAt,
      ];
}
