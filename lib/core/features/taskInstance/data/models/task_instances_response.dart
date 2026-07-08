import 'task_instance_counts_model.dart';
import 'task_instance_model.dart';

class TaskInstancesResponse {
  final List<TaskInstanceModel> instances;
  final TaskInstanceCountsModel counts;

  TaskInstancesResponse({required this.instances, required this.counts});

  factory TaskInstancesResponse.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> rootJson,
  ) {
    // 1. json here represents the "data" array key passed down from BaseApiResponse
    // 2. rootJson gives us access to the sibling "counts" object
    final dataList = json['data'] as List? ?? [];

    final instancesList = dataList
        .map((item) => TaskInstanceModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final countsObj = TaskInstanceCountsModel.fromJson(
      rootJson['counts'] as Map<String, dynamic>? ?? {},
    );

    return TaskInstancesResponse(instances: instancesList, counts: countsObj);
  }
}
