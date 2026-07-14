class TaskModel {
  final String id;
  final String taskType;
  final String taskId;
  final bool isSubTask;
  final String? parentTask;
  final String title;
  final DepartmentModel?
  department; // 🌟 Fixed: Turned into an object structure
  final String priority;
  final String? notificationPreference; // "one_time" | "recurring" | null
  final List<ReportingUserModel>
  assignees; // 🌟 Fixed: Changed to strongly typed list matching payload
  final DateTime? reportingDate;
  final TaskTime? reportingTime;
  final String? description;
  final List<AttachmentModel> attachments;
  final String organization;
  final CreatedByModel? createdBy;
  final String completionStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ReportingUserModel> reportingTo;

  // Nested structural groupings matching payload definitions
  final RecurrenceModel?
  recurrence; // 🌟 Fixed: Extracted nested recurrence mapping block
  final ProofConfigModel?
  proofConfig; // 🌟 Fixed: Extracted nested proof configuration block

  TaskModel({
    required this.id,
    required this.taskType,
    required this.taskId,
    required this.isSubTask,
    this.parentTask,
    required this.title,
    this.department,
    required this.priority,
    this.notificationPreference,
    required this.assignees,
    this.reportingDate,
    this.reportingTime,
    this.description,
    required this.attachments,
    required this.organization,
    this.createdBy,
    required this.completionStatus,
    this.createdAt,
    this.updatedAt,
    required this.reportingTo,
    this.recurrence,
    this.proofConfig,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Extract internal nested objects securely to avoid null parsing loops
    final recurrenceJson = json['recurrence'] as Map<String, dynamic>?;
    final proofConfigJson = json['proofConfig'] as Map<String, dynamic>?;

    return TaskModel(
      id: json['_id'] ?? '',
      taskType: json['taskType'] ?? '',
      taskId: json['taskId'] ?? '',
      isSubTask: json['isSubTask'] ?? false,
      parentTask: json['parentTask'],
      title: json['title'] ?? '',
      department: json['department'] != null
          ? DepartmentModel.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      priority: json['priority'] ?? '',
      notificationPreference: json['notificationPreference'] as String?,
      assignees: json['assignees'] != null
          ? (json['assignees'] as List)
                .map(
                  (x) => ReportingUserModel.fromJson(x as Map<String, dynamic>),
                )
                .toList()
          : [],
      reportingDate: json['reportingDate'] != null
          ? DateTime.tryParse(json['reportingDate'])
          : null,
      reportingTime: json['reportingTime'] != null
          ? TaskTime.fromJson(json['reportingTime'] as Map<String, dynamic>)
          : null,
      description: json['description'],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
                .map((x) => AttachmentModel.fromJson(x as Map<String, dynamic>))
                .toList()
          : [],
      organization: json['organization'] ?? '',
      createdBy: json['createdBy'] != null
          ? CreatedByModel.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      completionStatus: json['completionStatus'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      reportingTo: json['reportingTo'] != null
          ? (json['reportingTo'] as List)
                .map(
                  (x) => ReportingUserModel.fromJson(x as Map<String, dynamic>),
                )
                .toList()
          : [],
      recurrence: recurrenceJson != null
          ? RecurrenceModel.fromJson(recurrenceJson)
          : null,
      proofConfig: proofConfigJson != null
          ? ProofConfigModel.fromJson(proofConfigJson)
          : null,
    );
  }
}

// ── New & Supporting Sub-Models ──

class DepartmentModel {
  final String id;
  final String name;

  DepartmentModel({required this.id, required this.name});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(id: json['_id'] ?? '', name: json['name'] ?? '');
  }
}

class RecurrenceModel {
  final String? timePeriod;
  final int? everyN;
  final List<String> daysOfWeek;
  final String? monthlyType;
  final int? dayOfMonth;
  final int? weekOfMonth;
  final String? dayOfWeekMonthly;
  final DateTime? rangeStart;
  final String? endType;
  final DateTime? endByDate;
  final int? endAfterCount;
  final String id;

  RecurrenceModel({
    this.timePeriod,
    this.everyN,
    required this.daysOfWeek,
    this.monthlyType,
    this.dayOfMonth,
    this.weekOfMonth,
    this.dayOfWeekMonthly,
    this.rangeStart,
    this.endType,
    this.endByDate,
    this.endAfterCount,
    required this.id,
  });

  factory RecurrenceModel.fromJson(Map<String, dynamic> json) {
    return RecurrenceModel(
      timePeriod: json['timePeriod'],
      everyN: json['everyN'] != null ? (json['everyN'] as num).toInt() : null,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<String>.from(json['daysOfWeek'])
          : [],
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
      id: json['_id'] ?? '',
    );
  }
}

class ProofConfigModel {
  final List<String> proofTypes;
  // final bool aiValidationEnabled;
  final String id;
  final String proofEnabled;

  ProofConfigModel({
    required this.proofTypes,
    // required this.aiValidationEnabled,
    required this.id,
    required this.proofEnabled,
  });

  factory ProofConfigModel.fromJson(Map<String, dynamic> json) {
    return ProofConfigModel(
      proofTypes: json['proofTypes'] != null
          ? List<String>.from(json['proofTypes'])
          : [],
      // aiValidationEnabled: json['aiValidationEnabled'] ?? false,
      id: json['_id'] ?? '',
      proofEnabled: json['proofEnabled'] ?? '',
    );
  }
}

class TaskTime {
  final String time;
  final String period;
  final String id;

  TaskTime({required this.time, required this.period, required this.id});

  factory TaskTime.fromJson(Map<String, dynamic> json) {
    return TaskTime(
      time: json['time'] ?? '',
      period: json['period'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}

class AttachmentModel {
  final String id;
  final String fileName;
  final String fileType;
  final TaskFile? file;
  final int uploadProgress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileType,
    this.file,
    required this.uploadProgress,
    this.createdAt,
    this.updatedAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['_id'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      file: json['file'] != null
          ? TaskFile.fromJson(json['file'] as Map<String, dynamic>)
          : null,
      uploadProgress: json['uploadProgress'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

class TaskFile {
  final String originalUrl;
  final String thumbnailUrl;
  final String publicId;

  TaskFile({
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.publicId,
  });

  factory TaskFile.fromJson(Map<String, dynamic> json) {
    return TaskFile(
      originalUrl: json['originalUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }
}

class CreatedByModel {
  final String id;
  final String firstName;
  final String lastName;

  String get fullName => "$firstName $lastName".trim();

  CreatedByModel({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory CreatedByModel.fromJson(Map<String, dynamic> json) {
    return CreatedByModel(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
    );
  }
}

class ReportingUserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;

  String get fullName => "$firstName $lastName".trim();

  ReportingUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
  });

  factory ReportingUserModel.fromJson(Map<String, dynamic> json) {
    return ReportingUserModel(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
    );
  }
}
