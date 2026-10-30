import 'dart:async';
import 'package:flutter/foundation.dart';

enum LogLevel { info, success, warning, error, api }

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? details;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.details,
  });
}

class AppLogger {
  static final AppLogger instance = AppLogger._internal();
  AppLogger._internal();

  static const int maxLogs = 500;
  final List<LogEntry> _logs = [];

  void Function(LogEntry entry)? onLogEmitted;

  final _logStreamController = StreamController<LogEntry>.broadcast();
  Stream<LogEntry> get logStream => _logStreamController.stream;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void log({
    required LogLevel level,
    required String tag,
    required String message,
    String? details,
  }) {
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      tag: tag.toUpperCase(),
      message: message,
      details: details,
    );

    _logs.insert(0, entry); // Newest first
    if (_logs.length > maxLogs) {
      _logs.removeLast();
    }

    _logStreamController.add(entry);
    onLogEmitted?.call(entry);

    if (kDebugMode) {
      debugPrint('[${entry.tag}] ${entry.message}');
    }
  }

  void info(String tag, String message, [String? details]) {
    log(level: LogLevel.info, tag: tag, message: message, details: details);
  }

  void success(String tag, String message, [String? details]) {
    log(level: LogLevel.success, tag: tag, message: message, details: details);
  }

  void warning(String tag, String message, [String? details]) {
    log(level: LogLevel.warning, tag: tag, message: message, details: details);
  }

  void error(String tag, String message, [dynamic err, String? details]) {
    final detailStr = err != null ? '$err\n${details ?? ''}' : details;
    log(level: LogLevel.error, tag: tag, message: message, details: detailStr);
  }

  void api(String method, String endpoint, int? statusCode, String summary,
      [String? details]) {
    final statusStr = statusCode != null ? '$statusCode' : 'ERR';
    final shortMsg = '$method $endpoint -> $statusStr $summary';
    final lvl = (statusCode != null && statusCode >= 200 && statusCode < 300)
        ? LogLevel.api
        : (statusCode != null && statusCode < 500)
            ? LogLevel.warning
            : LogLevel.error;

    log(level: lvl, tag: 'API', message: shortMsg, details: details);
  }

  void clear() {
    _logs.clear();
    _logStreamController.add(LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: LogLevel.info,
      tag: 'SYSTEM',
      message: 'Logs cleared',
    ));
  }
}
