/// SubTaskInstance models — cover all 3 confirmed response shapes (Get All
/// SubTask Instances, Get SubTask Instance By Id, Update SubTask Instance)
/// with one set of models. The backend is inconsistent about which ref
/// fields (`subTask`, `taskInstance`, `task`, `assignees`, `completedBy`,
/// `deletedBy`) come back populated vs as plain id strings — it varies
/// *per endpoint*, not per field, so every ref below is parsed defensively
/// via `fromDynamic` (same convention as `CreatedByModel.fromDynamic`
/// elsewhere in this app): populated object → real fields + id; plain
/// string → just the id, other fields null.
library;

class SubTaskTime {
  final String? time;
  final String? period;

  SubTaskTime({this.time, this.period});

  factory SubTaskTime.fromJson(Map<String, dynamic> json) {
    return SubTaskTime(time: json['time'], period: json['period']);
  }
}

/// A location ref (only ever seen nested inside a populated
/// [TaskInstanceRef], but parsed defensively the same way regardless).
class LocationRef {
  final String id;
  final String? name;

  LocationRef({required this.id, this.name});

  factory LocationRef.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return LocationRef(id: value['_id']?.toString() ?? '', name: value['name']);
    }
    return LocationRef(id: value?.toString() ?? '');
  }
}

/// The SubTask "template" this instance was generated from.
class SubTaskRef {
  final String id;
  final String? title;
  final String? taskType;
  final String? description;
  final SubTaskTime? reportingTime;
  final String? taskId;
  final String? taskInstanceId;
  final String? createdBy;

  SubTaskRef({
    required this.id,
    this.title,
    this.taskType,
    this.description,
    this.reportingTime,
    this.taskId,
    this.taskInstanceId,
    this.createdBy,
  });

  factory SubTaskRef.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return SubTaskRef(
        id: value['_id']?.toString() ?? '',
        title: value['title'],
        taskType: value['taskType'],
        description: value['description'],
        reportingTime: value['reportingTime'] != null
            ? SubTaskTime.fromJson(value['reportingTime'] as Map<String, dynamic>)
            : null,
        taskId: value['task']?.toString(),
        taskInstanceId: value['taskInstance']?.toString(),
        createdBy: value['createdBy']?.toString(),
      );
    }
    return SubTaskRef(id: value?.toString() ?? '');
  }
}

/// The parent TaskInstance this subtask instance belongs to.
class TaskInstanceRef {
  final String id;
  final String? title;
  final List<String>? department;
  final LocationRef? location;
  final DateTime? scheduledDate;
  final SubTaskTime? scheduledTime;
  final String? status;

  TaskInstanceRef({
    required this.id,
    this.title,
    this.department,
    this.location,
    this.scheduledDate,
    this.scheduledTime,
    this.status,
  });

  factory TaskInstanceRef.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return TaskInstanceRef(
        id: value['_id']?.toString() ?? '',
        title: value['title'],
        department: value['department'] != null
            ? List<String>.from(value['department'])
            : null,
        location: value['location'] != null
            ? LocationRef.fromDynamic(value['location'])
            : null,
        scheduledDate: value['scheduledDate'] != null
            ? DateTime.tryParse(value['scheduledDate'])
            : null,
        scheduledTime: value['scheduledTime'] != null
            ? SubTaskTime.fromJson(value['scheduledTime'] as Map<String, dynamic>)
            : null,
        status: value['status'],
      );
    }
    return TaskInstanceRef(id: value?.toString() ?? '');
  }
}

/// The parent Task (template).
class TaskRef {
  final String id;
  final String? taskType;
  final String? title;

  TaskRef({required this.id, this.taskType, this.title});

  factory TaskRef.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return TaskRef(
        id: value['_id']?.toString() ?? '',
        taskType: value['taskType'],
        title: value['title'],
      );
    }
    return TaskRef(id: value?.toString() ?? '');
  }
}

/// An assignee (also reused for `completedBy`/`deletedBy` — same
/// "populated user object or plain id" shape).
class SubTaskUserRef {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? thumbnailUrl;

  String get fullName => [
    firstName,
    lastName,
  ].where((s) => s != null && s.isNotEmpty).join(' ');

  SubTaskUserRef({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.thumbnailUrl,
  });

  factory SubTaskUserRef.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      final image = value['image'] as Map<String, dynamic>?;
      return SubTaskUserRef(
        id: value['_id']?.toString() ?? '',
        firstName: value['firstName'],
        lastName: value['lastName'],
        email: value['email'],
        thumbnailUrl: image?['thumbnailUrl'] as String?,
      );
    }
    return SubTaskUserRef(id: value?.toString() ?? '');
  }
}

class SubTaskInstanceModel {
  final String id;
  final SubTaskRef subTask;
  final TaskInstanceRef taskInstance;
  final TaskRef task;
  final String taskType;
  final String title;
  final String? description;
  final List<SubTaskUserRef> assignees;
  final SubTaskTime? reportingTime;
  final String status;
  final SubTaskUserRef? completedBy;
  final DateTime? completedAt;
  final String organization;
  final bool isDeleted;
  final DateTime? deletedAt;
  final SubTaskUserRef? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubTaskInstanceModel({
    required this.id,
    required this.subTask,
    required this.taskInstance,
    required this.task,
    required this.taskType,
    required this.title,
    this.description,
    required this.assignees,
    this.reportingTime,
    required this.status,
    this.completedBy,
    this.completedAt,
    required this.organization,
    required this.isDeleted,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory SubTaskInstanceModel.fromJson(Map<String, dynamic> json) {
    return SubTaskInstanceModel(
      id: json['_id']?.toString() ?? '',
      subTask: SubTaskRef.fromDynamic(json['subTask']),
      taskInstance: TaskInstanceRef.fromDynamic(json['taskInstance']),
      task: TaskRef.fromDynamic(json['task']),
      taskType: json['taskType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      assignees: json['assignees'] != null
          ? (json['assignees'] as List)
                .map((a) => SubTaskUserRef.fromDynamic(a))
                .toList()
          : [],
      reportingTime: json['reportingTime'] != null
          ? SubTaskTime.fromJson(json['reportingTime'] as Map<String, dynamic>)
          : null,
      status: json['status'] ?? '',
      completedBy: json['completedBy'] != null
          ? SubTaskUserRef.fromDynamic(json['completedBy'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      organization: json['organization']?.toString() ?? '',
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'])
          : null,
      deletedBy: json['deletedBy'] != null
          ? SubTaskUserRef.fromDynamic(json['deletedBy'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

/// Wrapper for the "Get All SubTask Instances" response, whose `data` is
/// `{ taskInstance, subTaskInstances }` rather than a bare list — mirrors
/// `TaskInstancesResponse`'s wrapper pattern for the analogous
/// `getAllInstances` endpoint.
class SubTaskInstancesResponse {
  final TaskInstanceRef? taskInstance;
  final List<SubTaskInstanceModel> subTaskInstances;

  SubTaskInstancesResponse({this.taskInstance, required this.subTaskInstances});

  factory SubTaskInstancesResponse.fromJson(Map<String, dynamic> json) {
    return SubTaskInstancesResponse(
      taskInstance: json['taskInstance'] != null
          ? TaskInstanceRef.fromDynamic(json['taskInstance'])
          : null,
      subTaskInstances: json['subTaskInstances'] != null
          ? (json['subTaskInstances'] as List)
                .map(
                  (item) =>
                      SubTaskInstanceModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}
