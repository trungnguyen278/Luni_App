enum LogLevel {
  debug,
  info,
  warn,
  error;

  String get label => name.toUpperCase();
}

class LogEntry {
  const LogEntry({
    required this.id,
    required this.deviceId,
    required this.level,
    required this.tag,
    required this.message,
    required this.createdAt,
    this.source = 'device',
  });

  final int id;
  final String deviceId;
  final LogLevel level;
  final String tag;
  final String message;
  final DateTime createdAt;
  final String source;

  factory LogEntry.fromJson(Map<String, Object?> json) {
    return LogEntry(
      id: json['id'] as int? ?? 0,
      deviceId: json['device_id'] as String? ?? '',
      level: _levelFromString(json['level'] as String?),
      tag: json['tag'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      source: json['source'] as String? ?? 'device',
    );
  }

  static LogLevel _levelFromString(String? value) {
    switch (value) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warn':
        return LogLevel.warn;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  static List<LogEntry> mockForDevice(String deviceId) {
    final now = DateTime.now();

    return [
      LogEntry(
        id: 1,
        deviceId: deviceId,
        level: LogLevel.info,
        tag: 'WS',
        message: 'Heartbeat OK, free heap 45280 bytes',
        createdAt: now.subtract(const Duration(seconds: 18)),
      ),
      LogEntry(
        id: 2,
        deviceId: deviceId,
        level: LogLevel.warn,
        tag: 'WiFi',
        message: 'RSSI dropped below -65 dBm',
        createdAt: now.subtract(const Duration(minutes: 3)),
      ),
      LogEntry(
        id: 3,
        deviceId: deviceId,
        level: LogLevel.debug,
        tag: 'Audio',
        message: 'Opus frame queue depth: 2',
        createdAt: now.subtract(const Duration(minutes: 7)),
      ),
    ];
  }
}
