import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/ai_generation.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/auth/auth_service.dart';
import '../mappers/conversation_mapper.dart';

class SupabasePersonRepository implements PersonRepository {
  SupabasePersonRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Not authenticated');
    }
    return id;
  }

  @override
  Future<List<Person>> list({PersonFilter filter = PersonFilter.all}) async {
    final rows = await _client
        .from('people')
        .select()
        .eq('user_id', _uid)
        .order('last_activity_at', ascending: false);
    final people = (rows as List)
        .map((r) => ConversationMapper.fromRow(Map<String, dynamic>.from(r)))
        .toList();
    return switch (filter) {
      PersonFilter.all => people,
      PersonFilter.active => people
          .where(
            (p) =>
                p.status == PersonStatus.active ||
                p.status == PersonStatus.waiting,
          )
          .toList(),
      PersonFilter.dates =>
        people.where((p) => p.status == PersonStatus.dating).toList(),
    };
  }

  @override
  Future<Person?> getById(String id) async {
    final row = await _client
        .from('people')
        .select()
        .eq('user_id', _uid)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ConversationMapper.fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<Person> create(Person person) async {
    final payload = ConversationMapper.personToRow(
      person.id.isEmpty ? person.copyWith(id: _uuid.v4()) : person,
      _uid,
    );
    final row =
        await _client.from('people').insert(payload).select().single();
    return ConversationMapper.fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<Person> update(Person person) async {
    final payload = ConversationMapper.personToRow(person, _uid)..remove('id');
    final row = await _client
        .from('people')
        .update(payload)
        .eq('id', person.id)
        .eq('user_id', _uid)
        .select()
        .single();
    return ConversationMapper.fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('people').delete().eq('id', id).eq('user_id', _uid);
  }

  Future<void> linkConversation({
    required String conversationId,
    required String personId,
  }) async {
    await _client
        .from('conversations')
        .update({'person_id': personId})
        .eq('id', conversationId)
        .eq('user_id', _uid);
  }
}

class SupabaseConversationRepository implements ConversationRepository {
  SupabaseConversationRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Not authenticated');
    }
    return id;
  }

  @override
  Future<List<Conversation>> listForPerson(String personId) async {
    final rows = await _client
        .from('conversations')
        .select()
        .eq('user_id', _uid)
        .eq('person_id', personId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ConversationMapper.fromDbRow(Map<String, dynamic>.from(r)))
        .toList();
  }

  @override
  Future<Conversation?> latestForPerson(String personId) async {
    final list = await listForPerson(personId);
    return list.isEmpty ? null : list.first;
  }
}

class SupabaseFeedbackRepository implements FeedbackRepository {
  SupabaseFeedbackRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> save(GenerationFeedback feedback) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('generation_feedback').insert({
      'user_id': uid,
      'generation_id': feedback.generationId,
      'is_positive': feedback.isPositive,
      'issues': feedback.issues.map((e) => e.name).toList(),
    });
  }

  @override
  Future<List<GenerationFeedback>> list() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    final rows = await _client
        .from('generation_feedback')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return GenerationFeedback(
        generationId: row['generation_id'] as String,
        isPositive: row['is_positive'] as bool? ?? false,
        issues: (row['issues'] as List?)
                ?.map((e) {
                  try {
                    return FeedbackIssue.values.byName(e.toString());
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<FeedbackIssue>()
                .toList() ??
            const [],
      );
    }).toList();
  }
}

class SupabaseUserRepository implements UserRepository {
  SupabaseUserRepository(this._auth);

  final AuthService _auth;

  @override
  Future<UserProfile> getProfile() => _auth.currentProfile();

  @override
  Future<UserProfile> saveProfile(UserProfile profile) =>
      _auth.updateProfile(profile);
}
