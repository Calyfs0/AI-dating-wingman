import 'package:equatable/equatable.dart';

class ProfileAuditResult extends Equatable {
  const ProfileAuditResult({
    required this.overall,
    required this.clarity,
    required this.personality,
    required this.approachability,
    required this.conversationPotential,
    required this.photoNotes,
    required this.bioLikeMe,
    required this.bioFunnier,
    required this.bioShorter,
    this.hook,
    this.currentBio = '',
  });

  final double overall;
  final double clarity;
  final double personality;
  final double approachability;
  final double conversationPotential;
  final List<String> photoNotes;
  final String bioLikeMe;
  final String bioFunnier;
  final String bioShorter;
  final String? hook;
  final String currentBio;

  @override
  List<Object?> get props => [
        overall,
        clarity,
        personality,
        approachability,
        conversationPotential,
        photoNotes,
        bioLikeMe,
        bioFunnier,
        bioShorter,
        hook,
        currentBio,
      ];
}
