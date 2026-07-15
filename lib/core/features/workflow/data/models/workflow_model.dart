import 'package:taskalert_app/core/features/subTasks/data/models/sub_task_instance_model.dart';

/// A workflow list item — one row from `GET /workflow`. This is a task
/// instance viewed through the "workflow" lens (title/schedule/status/
/// priority/assignees), plus how many subtasks it has.
class WorkflowModel {
  final String id;
  final String instanceId;
  final String title;
  final String taskType;
  final List<String> department;
  final DateTime? scheduledDate;
  final SubTaskTime? scheduledTime;
  final String status;
  final String priority;
  final List<SubTaskUserRef> assignees;
  final int subtaskCount;

  WorkflowModel({
    required this.id,
    required this.instanceId,
    required this.title,
    required this.taskType,
    required this.department,
    this.scheduledDate,
    this.scheduledTime,
    required this.status,
    required this.priority,
    required this.assignees,
    required this.subtaskCount,
  });

  factory WorkflowModel.fromJson(Map<String, dynamic> json) {
    return WorkflowModel(
      id: json['_id']?.toString() ?? '',
      instanceId: json['instanceId']?.toString() ?? '',
      title: json['title'] ?? '',
      taskType: json['taskType'] ?? '',
      department: json['department'] != null
          ? List<String>.from(json['department'])
          : [],
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'])
          : null,
      scheduledTime: json['scheduledTime'] != null
          ? SubTaskTime.fromJson(json['scheduledTime'] as Map<String, dynamic>)
          : null,
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      assignees: json['assignees'] != null
          ? (json['assignees'] as List)
                .map((a) => SubTaskUserRef.fromDynamic(a))
                .toList()
          : [],
      subtaskCount: json['subtaskCount'] is int
          ? json['subtaskCount'] as int
          : int.tryParse(json['subtaskCount']?.toString() ?? '') ?? 0,
    );
  }
}

/// The richer `instance` object inside `GET /workflow/:workflowId` — same
/// core fields as [WorkflowModel] plus `description`, the human-readable
/// `taskId` code (e.g. "HIH0058", distinct from the Mongo `_id`s), and the
/// populated parent [TaskRef].
class WorkflowDetailInstance {
  final String id;
  final String instanceId;
  final String title;
  final String? description;
  final String taskType;
  final String? taskCode;
  final List<String> department;
  final DateTime? scheduledDate;
  final SubTaskTime? scheduledTime;
  final String status;
  final String priority;
  final List<SubTaskUserRef> assignees;
  final TaskRef? task;

  WorkflowDetailInstance({
    required this.id,
    required this.instanceId,
    required this.title,
    this.description,
    required this.taskType,
    this.taskCode,
    required this.department,
    this.scheduledDate,
    this.scheduledTime,
    required this.status,
    required this.priority,
    required this.assignees,
    this.task,
  });

  factory WorkflowDetailInstance.fromJson(Map<String, dynamic> json) {
    return WorkflowDetailInstance(
      id: json['_id']?.toString() ?? '',
      instanceId: json['instanceId']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      taskType: json['taskType'] ?? '',
      taskCode: json['taskId']?.toString(),
      department: json['department'] != null
          ? List<String>.from(json['department'])
          : [],
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'])
          : null,
      scheduledTime: json['scheduledTime'] != null
          ? SubTaskTime.fromJson(json['scheduledTime'] as Map<String, dynamic>)
          : null,
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      assignees: json['assignees'] != null
          ? (json['assignees'] as List)
                .map((a) => SubTaskUserRef.fromDynamic(a))
                .toList()
          : [],
      task: json['task'] != null ? TaskRef.fromDynamic(json['task']) : null,
    );
  }
}

/// One entry in a workflow's `timeline` — a subtask instance summary.
class WorkflowTimelineItem {
  final String subTaskInstanceId;
  final String subTaskId;
  final String title;
  final List<String> department;
  final String? taskCode;
  final String? description;
  final SubTaskTime? reportingTime;
  final String status;
  final List<SubTaskUserRef> assignees;

  WorkflowTimelineItem({
    required this.subTaskInstanceId,
    required this.subTaskId,
    required this.title,
    required this.department,
    this.taskCode,
    this.description,
    this.reportingTime,
    required this.status,
    required this.assignees,
  });

  factory WorkflowTimelineItem.fromJson(Map<String, dynamic> json) {
    return WorkflowTimelineItem(
      subTaskInstanceId: json['subTaskInstanceId']?.toString() ?? '',
      subTaskId: json['subTaskId']?.toString() ?? '',
      title: json['title'] ?? '',
      department: json['department'] != null
          ? List<String>.from(json['department'])
          : [],
      taskCode: json['taskId']?.toString(),
      description: json['description'],
      reportingTime: json['reportingTime'] != null
          ? SubTaskTime.fromJson(json['reportingTime'] as Map<String, dynamic>)
          : null,
      status: json['status'] ?? '',
      assignees: json['assignees'] != null
          ? (json['assignees'] as List)
                .map((a) => SubTaskUserRef.fromDynamic(a))
                .toList()
          : [],
    );
  }
}

/// Wrapper for `GET /workflow/:workflowId`, whose `data` is
/// `{ instance, timeline }`.
class WorkflowDetailResponse {
  final WorkflowDetailInstance instance;
  final List<WorkflowTimelineItem> timeline;

  WorkflowDetailResponse({required this.instance, required this.timeline});

  factory WorkflowDetailResponse.fromJson(Map<String, dynamic> json) {
    return WorkflowDetailResponse(
      instance: WorkflowDetailInstance.fromJson(
        json['instance'] as Map<String, dynamic>,
      ),
      timeline: json['timeline'] != null
          ? (json['timeline'] as List)
                .map(
                  (item) =>
                      WorkflowTimelineItem.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}
