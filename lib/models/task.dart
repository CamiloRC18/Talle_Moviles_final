import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String id;
  final String title;
  final bool completed;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final bool deleted;

  Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.updatedAt,
    this.deleted = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  Task copyWith({
    String? id,
    String? title,
    bool? completed,
    String? updatedAt,
    bool? deleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
      'updated_at': updatedAt,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      completed: (map['completed'] as int) == 1,
      updatedAt: map['updated_at'] as String,
      deleted: (map['deleted'] as int?) == 1,
    );
  }
}

enum QueueOperation { create, update, delete }

@JsonSerializable()
class QueuedOperation {
  final String id;
  final String entity;
  @JsonKey(name: 'entity_id')
  final String entityId;
  final String op;
  final String payload;
  @JsonKey(name: 'created_at')
  final int createdAt;
  @JsonKey(name: 'attempt_count')
  final int attemptCount;
  @JsonKey(name: 'last_error')
  final String? lastError;

  QueuedOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
  });

  factory QueuedOperation.fromJson(Map<String, dynamic> json) =>
      _$QueuedOperationFromJson(json);

  Map<String, dynamic> toJson() => _$QueuedOperationToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity': entity,
      'entity_id': entityId,
      'op': op,
      'payload': payload,
      'created_at': createdAt,
      'attempt_count': attemptCount,
      'last_error': lastError,
    };
  }

  factory QueuedOperation.fromMap(Map<String, dynamic> map) {
    return QueuedOperation(
      id: map['id'] as String,
      entity: map['entity'] as String,
      entityId: map['entity_id'] as String,
      op: map['op'] as String,
      payload: map['payload'] as String,
      createdAt: map['created_at'] as int,
      attemptCount: map['attempt_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }
}
