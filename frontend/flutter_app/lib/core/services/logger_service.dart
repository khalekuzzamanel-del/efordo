import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

class LoggerService {
  final Logger _logger;

  LoggerService()
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
        );

  void debug(String message) => _logger.d(message);
  void info(String message) => _logger.i(message);
  void warning(String message) => _logger.w(message);
  void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
