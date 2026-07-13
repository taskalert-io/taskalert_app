import '../../../tasks/data/models/task_model.dart'; // Reuse TaskTime, CreatedByModel

class ProofSubmissionModel {
  final DateTime? submittedAt;
  final List<ProofFileModel> files;
  final String note;
  final List<String> proofTypes;
  final String proofEnabled;
  // final String? aiValidationResult;

  ProofSubmissionModel({
    this.submittedAt,
    required this.files,
    required this.note,
    required this.proofTypes,
    required this.proofEnabled,
    // this.aiValidationResult,
  });

  factory ProofSubmissionModel.fromJson(Map<String, dynamic> json) {
    // Handle inner MongoDB style date: {"submittedAt": {"$date": "..."}}
    final dateMap = json['submittedAt'];
    DateTime? parsedDate;
    if (dateMap is Map && dateMap.containsKey('\$date')) {
      parsedDate = DateTime.tryParse(dateMap['\$date'] ?? '');
    } else if (dateMap is String) {
      parsedDate = DateTime.tryParse(dateMap);
    }

    return ProofSubmissionModel(
      submittedAt: parsedDate,
      files: json['files'] != null
          ? (json['files'] as List)
                .map((x) => ProofFileModel.fromJson(x as Map<String, dynamic>))
                .toList()
          : [],
      note: json['note'] ?? '',
      proofTypes: json['proofTypes'] != null
          ? List<String>.from(json['proofTypes'])
          : [],
      proofEnabled: json['proofEnabled'] ?? '',
      // aiValidationResult: json['aiValidationResult']?.toString(),
    );
  }
}

class ProofFileModel {
  final String id;
  final String fileType;
  final TaskFile? file; // Reuses your existing TaskFile sub-model 🚀
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProofFileModel({
    required this.id,
    required this.fileType,
    this.file,
    this.createdAt,
    this.updatedAt,
  });

  factory ProofFileModel.fromJson(Map<String, dynamic> json) {
    // Handle nested $oid string layout safely if present
    final idData = json['_id'];
    final parsedId = (idData is Map && idData.containsKey('\$oid'))
        ? idData['\$oid'].toString()
        : (idData ?? '').toString();

    DateTime? parseMongoDate(dynamic dateData) {
      if (dateData is Map && dateData.containsKey('\$date')) {
        return DateTime.tryParse(dateData['\$date'] ?? '');
      } else if (dateData is String) {
        return DateTime.tryParse(dateData);
      }
      return null;
    }

    return ProofFileModel(
      id: parsedId,
      fileType: json['fileType'] ?? '',
      file: json['file'] != null
          ? TaskFile.fromJson(json['file'] as Map<String, dynamic>)
          : null,
      createdAt: parseMongoDate(json['createdAt']),
      updatedAt: parseMongoDate(json['updatedAt']),
    );
  }
}

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
  final List<String> department;
  final String organization;
  final List<String> assignees; // Array of assignee user IDs
  // Name/id pairs for each assignee, when the backend sends populated
  // objects (not just raw ids) — lets the UI show real names without a
  // separate, possibly-incomplete employee-directory lookup.
  final List<CreatedByModel> assigneeRefs;

  final String? parentInstance;
  final CreatedByModel? completedBy;
  final DateTime? completedAt;
  // final String? proofSubmission;
  final ProofSubmissionModel?
  proofSubmission; // 🌟 Updated from String? to ProofSubmissionModel?
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
    this.assigneeRefs = const [],
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
      department: json['department'] != null
          ? List<String>.from(json['department'])
          : [],
      organization: json['organization'] ?? '',
      assignees: json['assignees'] != null
          ? (json['assignees'] as List).map((x) {
              // Handle both a populated object (`{"_id": ...}`) and a plain
              // ID string, in case the backend ever mixes shapes.
              if (x is Map<String, dynamic>) {
                return (x['_id'] ?? '').toString();
              }
              return x.toString();
            }).toList()
          : [],
      assigneeRefs: json['assignees'] != null
          ? (json['assignees'] as List)
                .whereType<Map<String, dynamic>>()
                .map((x) => CreatedByModel.fromJson(x))
                .toList()
          : [],
      parentInstance: json['parentInstance'],
      completedBy: json['completedBy'] != null
          ? CreatedByModel.fromJson(json['completedBy'] as Map<String, dynamic>)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      // proofSubmission: json['proofSubmission'],
      proofSubmission: json['proofSubmission'] != null
          ? ProofSubmissionModel.fromJson(
              json['proofSubmission'] as Map<String, dynamic>,
            )
          : null,
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
