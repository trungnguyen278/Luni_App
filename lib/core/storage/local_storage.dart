import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/models/device.dart';

class LocalStorage {
  const LocalStorage._();

  static const deviceBox = 'devices';
  static const settingsBox = 'settings';
  static const cacheBox = 'cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Object?>(deviceBox);
    await Hive.openBox<Object?>(settingsBox);
    await Hive.openBox<Object?>(cacheBox);
  }

  static Box<Object?> devices() => Hive.box<Object?>(deviceBox);
  static Box<Object?> settings() => Hive.box<Object?>(settingsBox);
  static Box<Object?> cache() => Hive.box<Object?>(cacheBox);

  static Future<void> cacheDevices(List<Device> devices) async {
    final box = cache();
    final jsonList = devices.map((d) => jsonEncode(_deviceToJson(d))).toList();
    await box.put('cached_devices', jsonList);
    await box.put('cached_devices_ts', DateTime.now().toIso8601String());
  }

  static List<Device> getCachedDevices() {
    final box = cache();
    final raw = box.get('cached_devices');
    if (raw is! List) return [];
    return raw
        .whereType<String>()
        .map((s) {
          try {
            return Device.fromJson(
              jsonDecode(s) as Map<String, Object?>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<Device>()
        .toList();
  }

  static DateTime? getCachedDevicesTimestamp() {
    final box = cache();
    final ts = box.get('cached_devices_ts') as String?;
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  static Map<String, Object?> _deviceToJson(Device d) {
    return {
      'id': d.id,
      'owner_id': d.ownerId,
      'name': d.name,
      'model': d.model,
      'fw_version': d.fwVersion,
      'location': d.location,
      'timezone': d.timezone,
      'city': d.city,
      'config': {
        'volume': d.config.volume,
        'brightness': d.config.brightness,
        'log_level': d.config.logLevel,
        'auto_ota': d.config.autoOta,
      },
      'is_online': d.isOnline,
      'battery_percent': d.batteryPercent,
      'is_charging': d.isCharging,
      'rssi': d.rssi,
      'emotion': d.emotion,
      'scene': d.scene,
      'last_seen': d.lastSeen.toIso8601String(),
    };
  }
}
