part of 'task.dart';

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: json['id'] as String,
  title: json['title'] as String,
  completed: json['completed'] as bool,
  updatedAt: json['updated_at'] as String,
  deleted: json['deleted'] as bool? ?? false,
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'completed': instance.completed,
  'updated_at': instance.updatedAt,
  'deleted': instance.deleted,
};

QueuedOperation _$QueuedOperationFromJson(Map<String, dynamic> json) =>
    QueuedOperation(
      id: json['id'] as String,
      entity: json['entity'] as String,
      entityId: json['entity_id'] as String,
      op: json['op'] as String,
      payload: json['payload'] as String,
      createdAt: json['created_at'] as int,
      attemptCount: json['attempt_count'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );

Map<String, dynamic> _$QueuedOperationToJson(QueuedOperation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entity': instance.entity,
      'entity_id': instance.entityId,
      'op': instance.op,
      'payload': instance.payload,
      'created_at': instance.createdAt,
      'attempt_count': instance.attemptCount,
      'last_error': instance.lastError,
    };
