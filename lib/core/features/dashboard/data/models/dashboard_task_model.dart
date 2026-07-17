import 'package:taskalert_app/core/features/subTasks/data/models/sub_task_instance_model.dart';
import 'package:taskalert_app/core/features/taskInstance/data/models/task_instance_model.dart'
    show ProofSubmissionModel;

/// A task instance as returned by the Dashboard's "All Tasks" endpoint
/// (`GET /tasks/all-tasks`). Looks a lot like `TaskInstanceModel` but isn't
/// reused as one: here `organization` comes back as a populated
/// `{_id, name}` object (not the plain id string `TaskInstanceModel`
/// expects) and there's an extra populated `location` ref — reusing
/// `TaskInstanceModel.fromJson` as-is would throw trying to assign that
/// object into a `String` field. Reuses [LocationRef] (an `{id, name}`
/// ref, despite the name generic enough to fit both `organization` and
/// `location` here) and [SubTaskUserRef]/[SubTaskTime] from the SubTasks
/// feature, and [ProofSubmissionModel] from TaskInstance, since those
/// shapes match exactly.
class DashboardTaskModel {
  final String id;
  final SubTaskTime? scheduledTime;
  final DateTime? scheduledDate;
  final String instanceId;
  final String taskType;
  final String title;
  final String? description;
  final String priority;

  // Recurrence metrics (all null for one-time tasks)
  final String? timePeriod;
  final int? everyN;
  final List<String>? daysOfWeek;
  final String? monthlyType;
  final int? dayOfMonth;
  final int? weekOfMonth;
  final String? dayOfWeekMonthly;
  final DateTime? rangeStart;
  final String? endType;
  final DateTime? endByDate;
  final int? endAfterCount;

  final List<SubTaskUserRef> assignees;
  final String taskId; // human-readable code, e.g. "HIH0056"
  final List<String> department;
  final LocationRef? organization;
  final LocationRef? location;
  final String status;
  final String? parentInstance;
  final SubTaskUserRef? completedBy;
  final DateTime? completedAt;
  final ProofSubmissionModel? proofSubmission;
  final SubTaskUserRef? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final SubTaskUserRef? createdBy;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DashboardTaskModel({
    required this.id,
    this.scheduledTime,
    this.scheduledDate,
    required this.instanceId,
    required this.taskType,
    required this.title,
    this.description,
    required this.priority,
    this.timePeriod,
    this.everyN,
    this.daysOfWeek,
    this.monthlyType,
    this.dayOfMonth,
    this.weekOfMonth,
    this.dayOfWeekMonthly,
    this.rangeStart,
    this.endType,
    this.endByDate,
    this.endAfterCount,
    required this.assignees,
    required this.taskId,
    required this.department,
    this.organization,
    this.location,
    required this.status,
    this.parentInstance,
    this.completedBy,
    this.completedAt,
    this.proofSubmission,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    this.createdBy,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory DashboardTaskModel.fromJson(Map<String, dynamic> json) {
    return DashboardTaskModel(
      id: json['_id']?.toString() ?? '',
      scheduledTime: json['scheduledTime'] != null
          ? SubTaskTime.fromJson(json['scheduledTime'] as Map<String, dynamic>)
          : null,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'])
          : null,
      instanceId: json['instanceId']?.toString() ?? '',
      taskType: json['taskType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      priority: json['priority'] ?? '',
      timePeriod: json['timePeriod'],
      everyN: json['everyN'] is int ? json['everyN'] as int : null,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<String>.from(json['daysOfWeek'])
          : null,
      monthlyType: json['monthlyType'],
      dayOfMonth: json['dayOfMonth'] is int ? json['dayOfMonth'] as int : null,
      weekOfMonth: json['weekOfMonth'] is int
          ? json['weekOfMonth'] as int
          : null,
      dayOfWeekMonthly: json['dayOfWeekMonthly'],
      rangeStart: json['rangeStart'] != null
          ? DateTime.tryParse(json['rangeStart'])
          : null,
      endType: json['endType'],
      endByDate: json['endByDate'] != null
          ? DateTime.tryParse(json['endByDate'])
          : null,
      endAfterCount: json['endAfterCount'] is int
          ? json['endAfterCount'] as int
          : null,
      assignees: json['assignees'] != null
          ? (json['assignees'] as List)
                .map((a) => SubTaskUserRef.fromDynamic(a))
                .toList()
          : [],
      taskId: json['taskId']?.toString() ?? '',
      department: json['department'] != null
          ? List<String>.from(json['department'])
          : [],
      organization: json['organization'] != null
          ? LocationRef.fromDynamic(json['organization'])
          : null,
      location: json['location'] != null
          ? LocationRef.fromDynamic(json['location'])
          : null,
      status: json['status'] ?? '',
      parentInstance: json['parentInstance']?.toString(),
      completedBy: json['completedBy'] != null
          ? SubTaskUserRef.fromDynamic(json['completedBy'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      proofSubmission: json['proofSubmission'] != null
          ? ProofSubmissionModel.fromJson(
              json['proofSubmission'] as Map<String, dynamic>,
            )
          : null,
      reviewedBy: json['reviewedBy'] != null
          ? SubTaskUserRef.fromDynamic(json['reviewedBy'])
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'])
          : null,
      reviewNote: json['reviewNote'],
      createdBy: json['createdBy'] != null
          ? SubTaskUserRef.fromDynamic(json['createdBy'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}
