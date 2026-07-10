import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/job_role_model.dart';

abstract class JobRoleRepository {
  Future<ApiResult<BaseApiResponse<List<JobRoleModel>>>> getJobRoles();

  Future<ApiResult<BaseApiResponse<JobRoleModel>>> createJobRole({
    required String title,
  });
}
