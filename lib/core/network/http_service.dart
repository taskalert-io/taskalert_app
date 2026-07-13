/// The interface that any network library (Dio, Http, etc.) must fulfill.
/// This fulfills SOLID principles and makes package upgrades friction-free.
abstract class HttpService {
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams});
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
  });
  Future<dynamic> put(String path, {dynamic body});
  Future<dynamic> patch(String path, {dynamic body});
  Future<dynamic> delete(String path, {dynamic body});
}
