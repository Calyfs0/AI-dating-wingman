import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum PersonStatus { yourMove, waiting, quiet }

extension PersonStatusLabel on PersonStatus {
  String get label => switch (this) {
        PersonStatus.yourMove => 'Your move',
        PersonStatus.waiting => 'Waiting on them',
        PersonStatus.quiet => 'Quiet',
      };

  int get sortOrder => switch (this) {
        PersonStatus.yourMove => 0,
        PersonStatus.waiting => 1,
        PersonStatus.quiet => 2,
      };
}

class Person extends Equatable {
  const Person({
    required this.id,
    required this.name,
    required this.status,
    this.note = '',
    required this.updatedAt,
  });

  final String id;
  final String name;
  final PersonStatus status;
  final String note;
  final DateTime updatedAt;

  factory Person.create({
    required String name,
    PersonStatus status = PersonStatus.yourMove,
    String note = '',
  }) {
    return Person(
      id: const Uuid().v4(),
      name: name.trim(),
      status: status,
      note: note.trim(),
      updatedAt: DateTime.now(),
    );
  }

  Person copyWith({
    String? name,
    PersonStatus? status,
    String? note,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.name,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      status: PersonStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PersonStatus.quiet,
      ),
      note: json['note'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, status, note, updatedAt];
}
