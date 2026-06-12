class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const AppException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => 'AppException: $message (status: $statusCode, code: $code)';
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.statusCode,
    super.code,
  });
}

class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
    super.code,
  });
}

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.statusCode,
    super.code,
  });
}

class ValidationException extends AppException {
  final Map<String, String>? errors;

  const ValidationException({
    required super.message,
    this.errors,
    super.statusCode,
    super.code,
  });
}
