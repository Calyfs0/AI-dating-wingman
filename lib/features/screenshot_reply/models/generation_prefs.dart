import 'suggested_replies.dart';

/// User style preferences sent with each generate-replies request.
class GenerationPrefs {
  const GenerationPrefs({
    this.preferredVibe = ReplyTone.natural,
    this.keepCasual = true,
    this.matchLanguage = true,
    this.personName,
    this.personNote,
  });

  final ReplyTone preferredVibe;
  final bool keepCasual;
  final bool matchLanguage;
  final String? personName;
  final String? personNote;

  GenerationPrefs withPerson({String? name, String? note}) {
    return GenerationPrefs(
      preferredVibe: preferredVibe,
      keepCasual: keepCasual,
      matchLanguage: matchLanguage,
      personName: name,
      personNote: note,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'preferredVibe': preferredVibe.name,
      'keepCasual': keepCasual,
      'matchLanguage': matchLanguage,
    };
    final name = personName?.trim();
    final note = personNote?.trim();
    if (name != null && name.isNotEmpty) map['personName'] = name;
    if (note != null && note.isNotEmpty) map['personNote'] = note;
    return map;
  }
}
