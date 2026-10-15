import 'package:uuid/uuid.dart';
import '../mock/demo_data.dart';
import '../../domain/entities/ai_generation.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/auth/auth_service.dart';

class LocalPersonRepository implements PersonRepository {
  LocalPersonRepository() : _people = [];

  final List<Person> _people;
  static const _uuid = Uuid();

  @override
  Future<List<Person>> list({PersonFilter filter = PersonFilter.all}) async {
    return switch (filter) {
      PersonFilter.all => List.unmodifiable(_people),
      PersonFilter.active => _people
          .where((p) =>
              p.status == PersonStatus.active ||
              p.status == PersonStatus.waiting)
          .toList(),
      PersonFilter.dates =>
        _people.where((p) => p.status == PersonStatus.dating).toList(),
    };
  }

  @override
  Future<Person?> getById(String id) async {
    try {
      return _people.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Person> create(Person person) async {
    final created = person.id.isEmpty
        ? person.copyWith(id: _uuid.v4())
        : person;
    _people.insert(0, created);
    return created;
  }

  @override
  Future<Person> update(Person person) async {
    final index = _people.indexWhere((p) => p.id == person.id);
    if (index >= 0) {
      _people[index] = person;
    }
    return person;
  }

  @override
  Future<void> delete(String id) async {
    _people.removeWhere((p) => p.id == id);
  }

  Future<void> seedDemoIfEmpty() async {
    if (_people.isNotEmpty) return;
    for (final person in DemoData.demoPeople) {
      _people.add(person);
    }
  }
}

class LocalConversationRepository implements ConversationRepository {
  @override
  Future<List<Conversation>> listForPerson(String personId) async => const [];

  @override
  Future<Conversation?> latestForPerson(String personId) async => null;
}

class LocalFeedbackRepository implements FeedbackRepository {
  final List<GenerationFeedback> _items = [];

  @override
  Future<void> save(GenerationFeedback feedback) async {
    _items.add(feedback);
  }

  @override
  Future<List<GenerationFeedback>> list() async => List.unmodifiable(_items);
}

class LocalUserRepository implements UserRepository {
  LocalUserRepository(this._auth);

  final AuthService _auth;

  @override
  Future<UserProfile> getProfile() => _auth.currentProfile();

  @override
  Future<UserProfile> saveProfile(UserProfile profile) =>
      _auth.updateProfile(profile);
}
