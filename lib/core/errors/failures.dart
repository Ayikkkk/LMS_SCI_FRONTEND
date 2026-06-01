// lib/core/errors/failures.dart

import 'package:dio/dio.dart';
import '../constants/error_messages.dart';

/// Base class for all failures in the application
abstract class Failure {
  final String message;
  final int? statusCode;
  final dynamic error;

  const Failure({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  String toString() => message;
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
    super.error,
  });

  factory ServerFailure.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerFailure(
          message: ErrorMessages.timeoutError,
          statusCode: e.response?.statusCode,
          error: e,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return ServerFailure(
          message: ErrorMessages.fromDioException(e),
          statusCode: statusCode,
          error: e,
        );

      case DioExceptionType.connectionError:
        return const ServerFailure(
          message: ErrorMessages.networkError,
        );

      case DioExceptionType.cancel:
        return const ServerFailure(
          message: 'Permintaan dibatalkan',
        );

      default:
        return ServerFailure(
          message: ErrorMessages.fromDioException(e),
          error: e,
        );
    }
  }
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.error,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.error,
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.statusCode,
    super.error,
  });
}
