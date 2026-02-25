// lib/core/errors/exceptions.dart

/// Base exception class
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Server exception
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
  });
}

/// Cache exception
class CacheException extends AppException {
  const CacheException({
    required super.message,
  });
}

/// Validation exception
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
  });
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
  });
}
