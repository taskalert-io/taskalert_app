import 'sub_task_instance_model.dart';

/// SubTask (template) model — from the "Create Sub Task" response. Reuses
/// [TaskRef]/[TaskInstanceRef]/[SubTaskUserRef]/[SubTaskTime] from
/// sub_task_instance_model.dart since they already parse "populated object
/// or plain id string" defensively, which is the same convention every ref
/// field on this response follows (even though `task`/`taskInstance`/
/// `createdBy`/`assignees` all happen to be plain id strings on create —
/// reusing the same defensive parsing keeps this resilient if a future
/// endpoint, e.g. Get SubTask By Id, returns them populated instead).
class SubTaskModel {
  final String id;
  final String title;
  final String taskType;
  final String? description;
  final String status;
  final List<SubTaskUserRef> assignees;
  final SubTaskTime? reportingTime;
  final TaskRef task;
  final TaskInstanceRef taskInstance;
  final String organization;
  final SubTaskUserRef? createdBy;
  final bool isDeleted;
  final DateTime? deletedAt;
  final SubTaskUserRef? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubTaskModel({
    required this.id,
    required this.title,
    required this.taskType,
    this.description,
    required this.status,
    required this.assignees,
    this.reportingTime,
    required this.task,
    required this.taskInstance,
    required this.organization,
    this.createdBy,
    required this.isDeleted,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    return SubTaskModel(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      taskType: json['taskType'] ?? '',
      description: json['description'],
      status: json['status'] ?? '',
      assignees: json['assignees'] != null
          ? (json['assignees'] as List)
                .map((a) => SubTaskUserRef.fromDynamic(a))
                .toList()
          : [],
      reportingTime: json['reportingTime'] != null
          ? SubTaskTime.fromJson(json['reportingTime'] as Map<String, dynamic>)
          : null,
      task: TaskRef.fromDynamic(json['task']),
      taskInstance: TaskInstanceRef.fromDynamic(json['taskInstance']),
      organization: json['organization']?.toString() ?? '',
      createdBy: json['createdBy'] != null
          ? SubTaskUserRef.fromDynamic(json['createdBy'])
          : null,
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

/// Wrapper for the "Create Sub Task" response, whose `data` is
/// `{ subTask, instanceCount }` rather than the SubTask object directly —
/// `instanceCount` is how many existing task instances this subtask was
/// generated onto (relevant for repetitive tasks).
class SubTaskCreateResponse {
  final SubTaskModel subTask;
  final int instanceCount;

  SubTaskCreateResponse({required this.subTask, required this.instanceCount});

  factory SubTaskCreateResponse.fromJson(Map<String, dynamic> json) {
    return SubTaskCreateResponse(
      subTask: SubTaskModel.fromJson(json['subTask'] as Map<String, dynamic>),
      instanceCount: json['instanceCount'] is int
          ? json['instanceCount'] as int
          : int.tryParse(json['instanceCount']?.toString() ?? '') ?? 0,
    );
  }
}
