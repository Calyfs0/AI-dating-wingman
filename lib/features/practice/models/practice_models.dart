import 'package:equatable/equatable.dart';

enum PracticeGender { female, male }

enum PracticePersona {
  // Female
  mia,
  maya,
  elena,
  sofia,
  // Male
  jake,
  noah,
  marcus,
  dylan,
}

extension PracticePersonaCopy on PracticePersona {
  PracticeGender get gender => switch (this) {
        PracticePersona.mia ||
        PracticePersona.maya ||
        PracticePersona.elena ||
        PracticePersona.sofia =>
          PracticeGender.female,
        PracticePersona.jake ||
        PracticePersona.noah ||
        PracticePersona.marcus ||
        PracticePersona.dylan =>
          PracticeGender.male,
      };

  String get name => switch (this) {
        PracticePersona.mia => 'Mia',
        PracticePersona.maya => 'Maya',
        PracticePersona.elena => 'Elena',
        PracticePersona.sofia => 'Sofia',
        PracticePersona.jake => 'Jake',
        PracticePersona.noah => 'Noah',
        PracticePersona.marcus => 'Marcus',
        PracticePersona.dylan => 'Dylan',
      };

  /// Short archetype chip on the card.
  String get archetype => switch (this) {
        PracticePersona.mia => 'Girl',
        PracticePersona.maya => 'Woman',
        PracticePersona.elena => 'Office',
        PracticePersona.sofia => 'Gym',
        PracticePersona.jake => 'Boy',
        PracticePersona.noah => 'Man',
        PracticePersona.marcus => 'Office',
        PracticePersona.dylan => 'Gym',
      };

  String get blurb => switch (this) {
        PracticePersona.mia => 'Early twenties. Soft, curious, lots of emoji.',
        PracticePersona.maya => 'Warm, sharp, a little playful.',
        PracticePersona.elena => 'Polished. Busy calendar. Direct texts.',
        PracticePersona.sofia => 'Protein shakes & early alarms. Flirty when free.',
        PracticePersona.jake => 'Chill college energy. Short replies, memes.',
        PracticePersona.noah => 'Easy energy. Dry humor. Late-night texts.',
        PracticePersona.marcus => 'Work-day pace. Polite, measured, adult.',
        PracticePersona.dylan => 'Leg day jokes. High energy. Plans around the gym.',
      };

  /// Hint for the edge model — how this person texts.
  String get stylePrompt => switch (this) {
        PracticePersona.mia =>
          'Young woman ~22. Casual, soft, curious. Light emoji OK. Shorter texts.',
        PracticePersona.maya =>
          'Woman late 20s. Warm, sharp, lightly playful. Natural dating-app tone.',
        PracticePersona.elena =>
          'Professional woman ~30. Polished, a bit busy, clear and direct. Fewer emoji.',
        PracticePersona.sofia =>
          'Athletic woman ~26. Gym lifestyle, upbeat, fit-focused humor. Mentions workouts casually. Light emoji OK.',
        PracticePersona.jake =>
          'Young man ~22. Chill, informal, short. Occasional slang. Light emoji OK.',
        PracticePersona.noah =>
          'Man late 20s. Easy, dry humor, late-night casual. Imperfect punctuation.',
        PracticePersona.marcus =>
          'Professional man ~32. Polite, measured, adult. Complete thoughts, low emoji.',
        PracticePersona.dylan =>
          'Athletic man ~28. Gym bro energy but friendly. Short, high-energy texts. Leg-day / PR jokes OK.',
      };

  String get imageAsset => switch (this) {
        PracticePersona.mia => 'assets/images/practice/mia.jpg',
        PracticePersona.maya => 'assets/images/practice/maya.jpg',
        PracticePersona.elena => 'assets/images/practice/elena.jpg',
        PracticePersona.sofia => 'assets/images/practice/sofia.jpg',
        PracticePersona.jake => 'assets/images/practice/jake.jpg',
        PracticePersona.noah => 'assets/images/practice/noah.jpg',
        PracticePersona.marcus => 'assets/images/practice/marcus.jpg',
        PracticePersona.dylan => 'assets/images/practice/dylan.jpg',
      };

  static List<PracticePersona> forGender(PracticeGender gender) =>
      PracticePersona.values.where((p) => p.gender == gender).toList();
}

enum PracticeTopic {
  firstMessage,
  keepingAlive,
  flirting,
  askingOut,
  rejection,
  firstDate,
  confidence,
}

extension PracticeTopicCopy on PracticeTopic {
  String get title => switch (this) {
        PracticeTopic.firstMessage => 'First message',
        PracticeTopic.keepingAlive => 'Keeping it alive',
        PracticeTopic.flirting => 'Flirting',
        PracticeTopic.askingOut => 'Asking out',
        PracticeTopic.rejection => 'Handling rejection',
        PracticeTopic.firstDate => 'First date',
        PracticeTopic.confidence => 'Confidence',
      };

  String get description => switch (this) {
        PracticeTopic.firstMessage => 'Open with something specific and easy.',
        PracticeTopic.keepingAlive => 'Keep momentum without interview energy.',
        PracticeTopic.flirting => 'Playful tension that still feels like you.',
        PracticeTopic.askingOut => 'Move from chat to a real plan.',
        PracticeTopic.rejection => 'Stay grounded when interest cools.',
        PracticeTopic.firstDate => 'Show up calm, curious, and present.',
        PracticeTopic.confidence => 'Sound natural when nerves kick in.',
      };

  String get iconHint => switch (this) {
        PracticeTopic.firstMessage => 'waving_hand',
        PracticeTopic.keepingAlive => 'forum',
        PracticeTopic.flirting => 'favorite',
        PracticeTopic.askingOut => 'event',
        PracticeTopic.rejection => 'spa',
        PracticeTopic.firstDate => 'local_cafe',
        PracticeTopic.confidence => 'bolt',
      };
}

class PracticeTurn extends Equatable {
  const PracticeTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;

  @override
  List<Object?> get props => [fromUser, text];
}

class PracticeFeedback extends Equatable {
  const PracticeFeedback({
    required this.summary,
    this.confidence = 0.7,
    this.naturalness = 0.7,
    this.conversation = 0.7,
    this.tips = const [],
  });

  final String summary;
  final double confidence;
  final double naturalness;
  final double conversation;
  final List<String> tips;

  @override
  List<Object?> get props =>
      [summary, confidence, naturalness, conversation, tips];
}
