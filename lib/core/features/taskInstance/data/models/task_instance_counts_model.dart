class TaskInstanceCountsModel {
  final int today;
  final int tomorrow;
  final int thisWeek;
  final int nextWeek;

  TaskInstanceCountsModel({
    required this.today,
    required this.tomorrow,
    required this.thisWeek,
    required this.nextWeek,
  });

  factory TaskInstanceCountsModel.fromJson(Map<String, dynamic> json) {
    return TaskInstanceCountsModel(
      today: json['today'] ?? 0,
      tomorrow: json['tomorrow'] ?? 0,
      thisWeek: json['thisWeek'] ?? 0,
      nextWeek: json['nextWeek'] ?? 0,
    );
  }
}
