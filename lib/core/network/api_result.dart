import '../errors/network_exceptions.dart';

/// A generic union class representing the ultimate state of an API transaction.
abstract class ApiResult<T> {
  const ApiResult();

  factory ApiResult.success(T data) = Success<T>;
  factory ApiResult.failure(NetworkException exception) = Failure<T>;
}

class Success<T> extends ApiResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends ApiResult<T> {
  final NetworkException exception;
  const Failure(this.exception);
}
