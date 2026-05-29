import '../../core/config/app_config.dart';

class DeviceConfig {
  const DeviceConfig({
    required this.volume,
    required this.brightness,
    required this.logLevel,
    required this.autoOta,
  });

  final int volume;
  final int brightness;
  final String logLevel;
  final bool autoOta;

  DeviceConfig copyWith({
    int? volume,
    int? brightness,
    String? logLevel,
    bool? autoOta,
  }) {
    return DeviceConfig(
      volume: volume ?? this.volume,
      brightness: brightness ?? this.brightness,
      logLevel: logLevel ?? this.logLevel,
      autoOta: autoOta ?? this.autoOta,
    );
  }
}

class Device {
  const Device({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.model,
    required this.fwVersion,
    required this.location,
    required this.timezone,
    required this.city,
    required this.config,
    required this.isOnline,
    required this.batteryPercent,
    required this.isCharging,
    required this.rssi,
    required this.emotion,
    required this.scene,
    required this.lastSeen,
  });

  final String id;
  final String ownerId;
  final String name;
  final String model;
  final String fwVersion;
  final String location;
  final String timezone;
  final String city;
  final DeviceConfig config;
  final bool isOnline;
  final int batteryPercent;
  final bool isCharging;
  final int rssi;
  final String emotion;
  final String scene;
  final DateTime lastSeen;

  bool get isBatteryLow => batteryPercent <= 15;

  Device copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? model,
    String? fwVersion,
    String? location,
    String? timezone,
    String? city,
    DeviceConfig? config,
    bool? isOnline,
    int? batteryPercent,
    bool? isCharging,
    int? rssi,
    String? emotion,
    String? scene,
    DateTime? lastSeen,
  }) {
    return Device(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      model: model ?? this.model,
      fwVersion: fwVersion ?? this.fwVersion,
      location: location ?? this.location,
      timezone: timezone ?? this.timezone,
      city: city ?? this.city,
      config: config ?? this.config,
      isOnline: isOnline ?? this.isOnline,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isCharging: isCharging ?? this.isCharging,
      rssi: rssi ?? this.rssi,
      emotion: emotion ?? this.emotion,
      scene: scene ?? this.scene,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  factory Device.fromJson(Map<String, Object?> json) {
    final config = json['config'] as Map<String, Object?>? ?? {};

    return Device(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      name: json['name'] as String? ?? AppConfig.defaultRobotName,
      model: json['model'] as String? ?? 'luni_v2_s3c5',
      fwVersion: json['fw_version'] as String? ?? 'unknown',
      location: json['location'] as String? ?? '',
      timezone: json['timezone'] as String? ?? AppConfig.defaultTimezone,
      city: json['city'] as String? ?? '',
      config: DeviceConfig(
        volume: config['volume'] as int? ?? 60,
        brightness: config['brightness'] as int? ?? 100,
        logLevel: config['log_level'] as String? ?? 'info',
        autoOta: config['auto_ota'] as bool? ?? false,
      ),
      isOnline: json['is_online'] as bool? ?? false,
      batteryPercent: json['battery_percent'] as int? ?? 0,
      isCharging: json['is_charging'] as bool? ?? false,
      rssi: json['rssi'] as int? ?? 0,
      emotion: json['emotion'] as String? ?? 'idle',
      scene: json['scene'] as String? ?? 'home',
      lastSeen:
          DateTime.tryParse(json['last_seen'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static List<Device> mockList() {
    final now = DateTime.now();

    return [
      Device(
        id: 'AA:BB:CC:DD:EE:01',
        ownerId: 'demo-user',
        name: 'Luni Phòng khách',
        model: 'luni_v2_s3c5',
        fwVersion: '2.1.0',
        location: 'Phòng khách',
        timezone: AppConfig.defaultTimezone,
        city: 'Hà Nội',
        config: const DeviceConfig(
          volume: 62,
          brightness: 92,
          logLevel: 'info',
          autoOta: false,
        ),
        isOnline: true,
        batteryPercent: 84,
        isCharging: false,
        rssi: -42,
        emotion: 'happy',
        scene: 'weather',
        lastSeen: now.subtract(const Duration(seconds: 20)),
      ),
      Device(
        id: 'AA:BB:CC:DD:EE:02',
        ownerId: 'demo-user',
        name: 'Luni Bàn làm việc',
        model: 'luni_v2_s3c5',
        fwVersion: '2.0.4',
        location: 'Góc làm việc',
        timezone: AppConfig.defaultTimezone,
        city: 'Hồ Chí Minh',
        config: const DeviceConfig(
          volume: 45,
          brightness: 70,
          logLevel: 'warn',
          autoOta: true,
        ),
        isOnline: false,
        batteryPercent: 31,
        isCharging: true,
        rssi: -67,
        emotion: 'sleepy',
        scene: 'clock',
        lastSeen: now.subtract(const Duration(minutes: 18)),
      ),
    ];
  }
}
