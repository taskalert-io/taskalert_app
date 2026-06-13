import 'package:taskalert_app/core/features/pagination/models/pagination_model.dart';

class BaseApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>?
  validationErrors; // Added to catch validation fields
  final PaginationModel? pagination; // Added to handle pagination info

  BaseApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.validationErrors,
    this.pagination,
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
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}
