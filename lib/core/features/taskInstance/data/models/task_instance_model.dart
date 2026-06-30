import '../../../tasks/data/models/task_model.dart'; // Reuse ReportingUserModel, TaskTime, CreatedByModel

class TaskInstanceModel {
  final String id;
  final String taskDocId;
  final String instanceId; // 🌟 Added to match list payload
  final TaskTime? scheduledTime;
  final DateTime? scheduledDate;
  final String taskType;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String taskId;
  final String department;
  final String organization;
  final List<ReportingUserModel>
  assignees; // 🌟 Updated from String to Model to match list payload safely

  final String? parentInstance;
  final CreatedByModel? completedBy;
  final DateTime? completedAt;
  final String? proofSubmission;
  final CreatedByModel? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final CreatedByModel? createdBy;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Recurrence metrics
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

  TaskInstanceModel({
    required this.id,
    required this.taskDocId,
    required this.instanceId,
    this.scheduledTime,
    this.scheduledDate,
    required this.taskType,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.taskId,
    required this.department,
    required this.organization,
    required this.assignees,
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
  });

  factory TaskInstanceModel.fromJson(Map<String, dynamic> json) {
    return TaskInstanceModel(
      id: json['_id'] ?? '',
      taskDocId: json['taskDocId'] ?? json['_id'] ?? '', // Fallback handle
      instanceId: json['instanceId'] ?? json['_id'] ?? '', // Fallback handle
      scheduledTime: json['scheduledTime'] != null
          ? TaskTime.fromJson(json['scheduledTime'] as Map<String, dynamic>)
          : null,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'])
          : null,
      taskType: json['taskType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      priority: json['priority'] ?? '',
      status: json['status'] ?? '',
      taskId: json['taskId'] ?? '',
      department: json['department'] ?? '',
      organization: json['organization'] ?? '',
      assignees: json['assignees'] != null
          ? (json['assignees'] as List).map((x) {
              if (x is Map<String, dynamic>) {
                return ReportingUserModel.fromJson(x);
              }
              // Handle fallback string variants gracefully if mixed
              return ReportingUserModel(
                id: x.toString(),
                firstName: '',
                lastName: '',
              );
            }).toList()
          : [],
      parentInstance: json['parentInstance'],
      completedBy: json['completedBy'] != null
          ? CreatedByModel.fromJson(json['completedBy'] as Map<String, dynamic>)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      proofSubmission: json['proofSubmission'],
      reviewedBy: json['reviewedBy'] != null
          ? CreatedByModel.fromJson(json['reviewedBy'] as Map<String, dynamic>)
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'])
          : null,
      reviewNote: json['reviewNote'],
      createdBy: json['createdBy'] != null
          ? CreatedByModel.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      timePeriod: json['timePeriod'],
      everyN: json['everyN'] != null ? (json['everyN'] as num).toInt() : null,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<String>.from(json['daysOfWeek'])
          : null,
      monthlyType: json['monthlyType'],
      dayOfMonth: json['dayOfMonth'] != null
          ? (json['dayOfMonth'] as num).toInt()
          : null,
      weekOfMonth: json['weekOfMonth'] != null
          ? (json['weekOfMonth'] as num).toInt()
          : null,
      dayOfWeekMonthly: json['dayOfWeekMonthly'],
      rangeStart: json['rangeStart'] != null
          ? DateTime.tryParse(json['rangeStart'])
          : null,
      endType: json['endType'],
      endByDate: json['endByDate'] != null
          ? DateTime.tryParse(json['endByDate'])
          : null,
      endAfterCount: json['endAfterCount'] != null
          ? (json['endAfterCount'] as num).toInt()
          : null,
    );
  }
}
