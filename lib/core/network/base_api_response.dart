class BaseApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>?
  validationErrors; // Added to catch validation fields

  BaseApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.validationErrors,
  });

  factory BaseApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return BaseApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      validationErrors: json['validationErrors'] != null
          ? Map<String, dynamic>.from(json['validationErrors'])
          : null,
    );
  }
}
