class NotificationModel {
  final String? id;
  final String? user;
  final NotificationOrganization? organization;
  final String? title;
  final String? description;
  final String? type;
  final DateTime? notificationDate;
  final String? severity;
  final bool? isRead;
  final DateTime? sendAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final NotificationTaskInstance? taskInstance;
  final NotificationTask? task;

  NotificationModel({
    this.id,
    this.user,
    this.organization,
    this.title,
    this.description,
    this.type,
    this.notificationDate,
    this.severity,
    this.isRead,
    this.sendAt,
    this.createdAt,
    this.updatedAt,
    this.taskInstance,
    this.task,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] as String?,
      user: _extractRefId(json['user']),
      organization: _parseOrganization(json['organization']),
      title: json['title'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      notificationDate: json['notificationDate'] != null
          ? DateTime.tryParse(json['notificationDate'] as String)
          : null,
      severity: json['severity'] as String?,
      isRead: json['isRead'] as bool?,
      sendAt: json['sendAt'] != null
          ? DateTime.tryParse(json['sendAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      taskInstance: json['taskInstance'] != null
          ? NotificationTaskInstance.fromJson(
              json['taskInstance'] as Map<String, dynamic>,
            )
          : null,
      task: json['task'] != null
          ? NotificationTask.fromJson(json['task'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (user != null) 'user': user,
      if (organization != null) 'organization': organization?.toJson(),
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (notificationDate != null)
        'notificationDate': notificationDate?.toIso8601String(),
      if (severity != null) 'severity': severity,
      if (isRead != null) 'isRead': isRead,
      if (sendAt != null) 'sendAt': sendAt?.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
      if (taskInstance != null) 'taskInstance': taskInstance?.toJson(),
      if (task != null) 'task': task?.toJson(),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      user: user,
      organization: organization,
      title: title,
      description: description,
      type: type,
      notificationDate: notificationDate,
      severity: severity,
      isRead: isRead ?? this.isRead,
      sendAt: sendAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      taskInstance: taskInstance,
      task: task,
    );
  }

  /// Some refs come back as a plain id string on some endpoints but as a
  /// populated object on others — handle both so a shape mismatch doesn't
  /// throw and break the whole parse.
  static String? _extractRefId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString();
    return null;
  }

  static NotificationOrganization? _parseOrganization(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return NotificationOrganization.fromJson(value);
    }
    if (value is String) return NotificationOrganization(id: value);
    return null;
  }
}

class NotificationOrganization {
  final String? id;
  final String? name;

  NotificationOrganization({this.id, this.name});

  factory NotificationOrganization.fromJson(Map<String, dynamic> json) {
    return NotificationOrganization(
      id: json['_id'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {if (id != null) '_id': id, if (name != null) 'name': name};
  }
}

class NotificationScheduledTime {
  final String? time;
  final String? period;

  NotificationScheduledTime({this.time, this.period});

  factory NotificationScheduledTime.fromJson(Map<String, dynamic> json) {
    return NotificationScheduledTime(
      time: json['time'] as String?,
      period: json['period'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (time != null) 'time': time,
      if (period != null) 'period': period,
    };
  }
}

class NotificationTaskInstance {
  final String? id;
  final DateTime? scheduledDate;
  final NotificationScheduledTime? scheduledTime;
  final String? status;

  NotificationTaskInstance({
    this.id,
    this.scheduledDate,
    this.scheduledTime,
    this.status,
  });

  factory NotificationTaskInstance.fromJson(Map<String, dynamic> json) {
    return NotificationTaskInstance(
      id: json['_id'] as String?,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'] as String)
          : null,
      scheduledTime: json['scheduledTime'] != null
          ? NotificationScheduledTime.fromJson(
              json['scheduledTime'] as Map<String, dynamic>,
            )
          : null,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (scheduledDate != null)
        'scheduledDate': scheduledDate?.toIso8601String(),
      if (scheduledTime != null) 'scheduledTime': scheduledTime?.toJson(),
      if (status != null) 'status': status,
    };
  }
}

class NotificationCreatedBy {
  final String? id;
  final String? firstName;
  final String? lastName;

  NotificationCreatedBy({this.id, this.firstName, this.lastName});

  String get fullName => '${firstName ?? ""} ${lastName ?? ""}'.trim();

  factory NotificationCreatedBy.fromJson(Map<String, dynamic> json) {
    return NotificationCreatedBy(
      id: json['_id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    };
  }
}

class NotificationTask {
  final String? id;
  final String? taskType;
  final String? title;
  final NotificationOrganization? organization;
  final NotificationCreatedBy? createdBy;

  NotificationTask({
    this.id,
    this.taskType,
    this.title,
    this.organization,
    this.createdBy,
  });

  factory NotificationTask.fromJson(Map<String, dynamic> json) {
    return NotificationTask(
      id: json['_id'] as String?,
      taskType: json['taskType'] as String?,
      title: json['title'] as String?,
      organization: NotificationModel._parseOrganization(
        json['organization'],
      ),
      createdBy: json['createdBy'] != null
          ? NotificationCreatedBy.fromJson(
              json['createdBy'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (taskType != null) 'taskType': taskType,
      if (title != null) 'title': title,
      if (organization != null) 'organization': organization?.toJson(),
      if (createdBy != null) 'createdBy': createdBy?.toJson(),
    };
  }
}
