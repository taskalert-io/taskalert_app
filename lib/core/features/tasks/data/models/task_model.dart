class TaskModel {
  final String id;
  final String taskType;
  final String title;
  final String? description;
  final String? priority;
  final String? department;
  final List<String> assignees;
  final String? status;
  final List<AttachmentModel> attachments;

  TaskModel({
    required this.id,
    required this.taskType,
    required this.title,
    this.description,
    this.priority,
    this.department,
    required this.assignees,
    this.status,
    required this.attachments,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'] ?? '',
      taskType: json['taskType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      priority: json['priority'],
      department: json['department'],
      assignees: List<String>.from(json['assignees'] ?? []),
      status: json['status'],
      attachments:
          (json['attachments'] as List?)
              ?.map((x) => AttachmentModel.fromJson(x))
              .toList() ??
          [],
    );
  }
}

class AttachmentModel {
  final String url;
  final String publicId;

  AttachmentModel({required this.url, required this.publicId});

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }
}
