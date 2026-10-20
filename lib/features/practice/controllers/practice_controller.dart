import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../models/practice_models.dart';
import '../services/practice_service.dart';

enum PracticePhase { personas, topics, session, feedback }

class PracticeController extends ChangeNotifier {
  PracticeController(this._service);

  final PracticeService _service;

  PracticePhase phase = PracticePhase.personas;
  PracticeGender genderFilter = PracticeGender.female;
  PracticePersona? persona;
  PracticeTopic? topic;
  final List<PracticeTurn> turns = [];
  PracticeFeedback? feedback;
  bool isBusy = false;
  String? errorMessage;
  int _turnToken = 0;

  List<PracticePersona> get visiblePersonas =>
      PracticePersonaCopy.forGender(genderFilter);

  /// True when returning to /practice would resume mid-flow (not idle personas).
  bool get hasResumableSession =>
      phase == PracticePhase.session ||
      phase == PracticePhase.feedback ||
      (phase == PracticePhase.topics && persona != null);

  void setGenderFilter(PracticeGender gender) {
    if (genderFilter == gender) return;
    genderFilter = gender;
    if (persona != null && persona!.gender != gender) {
      persona = null;
    }
    notifyListeners();
  }

  /// In-character openers. Null = user speaks first.
  static const Map<PracticeTopic, String?> _openers = {
    PracticeTopic.firstMessage: null,
    PracticeTopic.keepingAlive: 'wait how was your weekend though',
    PracticeTopic.flirting: 'you always this charming or just with me',
    PracticeTopic.askingOut: "we've been talking forever lol",
    PracticeTopic.rejection: "tbh I've been kinda busy lately",
    PracticeTopic.firstDate: 'just got here — you find the place ok?',
    PracticeTopic.confidence: 'so your profile said you\'re funny…',
  };

  String get partnerName => persona?.name ?? 'them';

  String? get sceneHint {
    if (topic == null) return null;
    final name = partnerName;
    return switch (topic!) {
      PracticeTopic.firstMessage => 'You matched with $name. Send the first text.',
      PracticeTopic.keepingAlive =>
        'Keep the chat with $name going — reply like you would.',
      PracticeTopic.flirting => 'Soft flirt back — stay you.',
      PracticeTopic.askingOut =>
        '$name left the door open. Move it forward.',
      PracticeTopic.rejection =>
        '$name is pulling back. Respond like a human.',
      PracticeTopic.firstDate => 'You’re at the table with $name. Keep it easy.',
      PracticeTopic.confidence => 'Light pressure. Stay natural.',
    };
  }

  void selectPersona(PracticePersona p) {
    persona = p;
    notifyListeners();
  }

  void startWithPersona() {
    if (persona == null) return;
    topic = null;
    turns.clear();
    feedback = null;
    errorMessage = null;
    phase = PracticePhase.topics;
    notifyListeners();
  }

  void backToPersonas() {
    _turnToken++;
    persona = null;
    topic = null;
    turns.clear();
    feedback = null;
    errorMessage = null;
    isBusy = false;
    phase = PracticePhase.personas;
    notifyListeners();
  }

  /// Full reset to Practice entry. Does not write gender filter.
  void resetToIdle() {
    _turnToken++;
    persona = null;
    topic = null;
    turns.clear();
    feedback = null;
    errorMessage = null;
    isBusy = false;
    phase = PracticePhase.personas;
    notifyListeners();
  }

  /// Drop an in-flight turn without wiping a resumable session (e.g. route pop).
  void abandonInFlight() {
    if (!isBusy) return;
    _turnToken++;
    isBusy = false;
    notifyListeners();
  }

  void pickTopic(PracticeTopic t) {
    if (persona == null) {
      phase = PracticePhase.personas;
      notifyListeners();
      return;
    }
    topic = t;
    turns.clear();
    final opener = _openers[t];
    if (opener != null && opener.isNotEmpty) {
      turns.add(PracticeTurn(fromUser: false, text: opener));
    }
    feedback = null;
    errorMessage = null;
    phase = PracticePhase.session;
    notifyListeners();
  }

  /// Back into the same person, topic, and thread after a paid hour.
  void continueScene() {
    feedback = null;
    errorMessage = null;
    phase = PracticePhase.session;
    notifyListeners();
  }

  void backToTopics() {
    _turnToken++;
    topic = null;
    turns.clear();
    feedback = null;
    errorMessage = null;
    isBusy = false;
    phase = PracticePhase.topics;
    notifyListeners();
  }

  Future<void> send(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || topic == null || persona == null || isBusy) return;

    // Practice is rehearsal — it does not burn the Free Reply/Openers quota.
    turns.add(PracticeTurn(fromUser: true, text: trimmed));
    final token = ++_turnToken;
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prior = turns.length <= 1
          ? const <PracticeTurn>[]
          : turns.sublist(0, turns.length - 1);
      final result = await _service.turn(
        topic: topic!,
        personaName: persona!.name,
        personaStyle: persona!.stylePrompt,
        history: List.unmodifiable(prior),
        userMessage: trimmed,
      );
      if (token != _turnToken) return;
      if (result.personaLine.isNotEmpty) {
        turns.add(PracticeTurn(fromUser: false, text: result.personaLine));
      }
      if (result.feedback != null || result.done) {
        feedback = result.feedback ??
            PracticeFeedback(
              summary:
                  'That was one rehearsal with ${persona!.name} — real chats can go differently.',
              tips: const [
                'This isn’t a prediction of how someone will respond',
                'Use it for reps, not reassurance',
              ],
            );
        phase = PracticePhase.feedback;
      }
    } on AppException catch (e) {
      if (token != _turnToken) return;
      errorMessage = e.message;
      if (turns.isNotEmpty && turns.last.fromUser) turns.removeLast();
    } catch (e) {
      if (token != _turnToken) return;
      errorMessage = AppExceptionMapper.map(e).message;
      if (turns.isNotEmpty && turns.last.fromUser) turns.removeLast();
    } finally {
      if (token == _turnToken) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  /// Soft wrap → feedback when the user has spoken; otherwise back to topics.
  void endEarly() {
    if (turns.where((t) => t.fromUser).isEmpty) {
      backToTopics();
      return;
    }
    _turnToken++;
    isBusy = false;
    feedback ??= PracticeFeedback(
      summary:
          'Session ended early — one practice chat with $partnerName, not a verdict on you.',
      tips: const [
        'This isn’t a prediction of how someone will respond',
        'Try another scene if you want more reps',
      ],
    );
    phase = PracticePhase.feedback;
    notifyListeners();
  }

  /// One-tap exit: clear ephemeral session and return to Practice entry.
  void endSession() => resetToIdle();
}
