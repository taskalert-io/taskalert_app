// import '../../../../../tasks/data/models/task_model.dart'; // Reuses your TaskFile or similar model for image urls if available
// import '../../../tasks/data/models/task_model.dart';

class ActivityLogResponse {
  final List<ActivityLogModel> logs;
  final ActivityLogInstanceMeta? instanceMeta;
  final int total;

  ActivityLogResponse({
    required this.logs,
    this.instanceMeta,
    required this.total,
  });

  factory ActivityLogResponse.fromJson(
    dynamic dataJson,
    Map<String, dynamic> rootJson,
  ) {
    return ActivityLogResponse(
      logs: dataJson is List
          ? dataJson
                .map(
                  (item) =>
                      ActivityLogModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : [],
      instanceMeta: rootJson['instance'] != null
          ? ActivityLogInstanceMeta.fromJson(
              rootJson['instance'] as Map<String, dynamic>,
            )
          : null,
      total: (rootJson['total'] as num ?? 0).toInt(),
    );
  }
}

class ActivityLogInstanceMeta {
  final String id;
  final String taskId;

  ActivityLogInstanceMeta({required this.id, required this.taskId});

  factory ActivityLogInstanceMeta.fromJson(Map<String, dynamic> json) {
    return ActivityLogInstanceMeta(
      id: json['_id'] ?? '',
      taskId: json['taskId'] ?? '',
    );
  }
}

class ActivityLogModel {
  final String id;
  final String userId;
  final ActivityUserSnapshot? userSnapshot;
  final String action;
  final String entity;
  final String entityId;
  final String? entityInstanceId;
  final String entityName;
  final List<dynamic> changes;
  final String? scope;
  final String description;
  final String timeLabel;
  final DateTime? createdAt;

  ActivityLogModel({
    required this.id,
    required this.userId,
    this.userSnapshot,
    required this.action,
    required this.entity,
    required this.entityId,
    this.entityInstanceId,
    required this.entityName,
    required this.changes,
    this.scope,
    required this.description,
    required this.timeLabel,
    this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      userSnapshot: json['userSnapshot'] != null
          ? ActivityUserSnapshot.fromJson(
              json['userSnapshot'] as Map<String, dynamic>,
            )
          : null,
      action: json['action'] ?? '',
      entity: json['entity'] ?? '',
      entityId: json['entityId'] ?? '',
      entityInstanceId: json['entityInstanceId'],
      entityName: json['entityName'] ?? '',
      changes: json['changes'] ?? [],
      scope: json['scope'],
      description: json['description'] ?? '',
      timeLabel: json['timeLabel'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class ActivityUserSnapshot {
  final String name;
  final String email;
  final ActivityAvatar? avatar;

  ActivityUserSnapshot({required this.name, required this.email, this.avatar});

  factory ActivityUserSnapshot.fromJson(Map<String, dynamic> json) {
    return ActivityUserSnapshot(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] != null
          ? ActivityAvatar.fromJson(json['avatar'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ActivityAvatar {
  final String originalUrl;
  final String thumbnailUrl;
  final String publicId;

  ActivityAvatar({
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.publicId,
  });

  factory ActivityAvatar.fromJson(Map<String, dynamic> json) {
    return ActivityAvatar(
      originalUrl: json['originalUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }
}
