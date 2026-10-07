import '../entities/ai_generation.dart';
import '../entities/conversation.dart';
import '../entities/person.dart';
import '../entities/user_profile.dart';

abstract class PersonRepository {
  Future<List<Person>> list({PersonFilter filter = PersonFilter.all});
  Future<Person?> getById(String id);
  Future<Person> create(Person person);
  Future<Person> update(Person person);
  Future<void> delete(String id);
}

abstract class ConversationRepository {
  Future<List<Conversation>> listForPerson(String personId);
  Future<Conversation?> latestForPerson(String personId);
}

abstract class FeedbackRepository {
  Future<void> save(GenerationFeedback feedback);
  Future<List<GenerationFeedback>> list();
}

abstract class UserRepository {
  Future<UserProfile> getProfile();
  Future<UserProfile> saveProfile(UserProfile profile);
}
