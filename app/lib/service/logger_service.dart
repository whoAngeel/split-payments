import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class AppLogger {
  final Logger _logger;

  AppLogger._(this._logger);

  factory AppLogger({
    bool enableColors = true,
    bool printEmojis = true,
    Level level = Level.debug,
  }) {
    return AppLogger._(
      Logger(
        filter: AppLogFilter(level),
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: enableColors,
          printEmojis: printEmojis,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      ),
    );
  }

  void t(String message) => _logger.t(message);
  void d(String message) => _logger.d(message);
  void i(String message) => _logger.i(message);
  void w(String message) => _logger.w(message);

  void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  void f(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);

  void log(Level level, String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.log(level, message, error: error, stackTrace: stackTrace);
}

class AppLogFilter extends LogFilter {
  final Level _level;
  AppLogFilter(this._level);

  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= _level.index;
  }
}

final loggerProvider = Provider<AppLogger>((ref) {
  return AppLogger(
    level: kDebugMode ? Level.debug : Level.warning,
    enableColors: kDebugMode,
    printEmojis: kDebugMode,
  );
});
