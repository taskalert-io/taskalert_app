import 'task_instance_counts_model.dart';
import 'task_instance_model.dart';

class TaskInstancesResponse {
  final List<TaskInstanceModel> instances;
  final TaskInstanceCountsModel counts;

  TaskInstancesResponse({required this.instances, required this.counts});

  // Named exactly 'fromJson' to satisfy the architecture constraints
  factory TaskInstancesResponse.fromJson(Map<String, dynamic> json) {
    // 1. Parse the "data" array safely from the root map
    final dataList = json['data'] as List? ?? [];
    final instancesList = dataList
        .map((item) => TaskInstanceModel.fromJson(item as Map<String, dynamic>))
        .toList();

    // 2. Parse the sibling "counts" object safely from the root map
    final countsObj = TaskInstanceCountsModel.fromJson(
      json['counts'] as Map<String, dynamic>? ?? {},
    );

    return TaskInstancesResponse(instances: instancesList, counts: countsObj);
  }
}
