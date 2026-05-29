import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/ws_client.dart';
import '../../../core/notifications/push_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/device.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(apiClient: ref.watch(apiClientProvider));
});

final deviceListProvider =
    AsyncNotifierProvider<DeviceListNotifier, List<Device>>(
      DeviceListNotifier.new,
    );

enum DeviceCommand {
  setVolume,
  setBrightness,
  setEmotion,
  setScene,
  reboot,
  mute,
  ttsPlay,
}

class DeviceRepository {
  DeviceRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<Device>> fetchDevices() async {
    final response = await apiClient.get<List<dynamic>>('/devices');
    final data = response.data ?? [];
    return data
        .whereType<Map<String, Object?>>()
        .map(Device.fromJson)
        .toList(growable: false);
  }

  Future<Device?> fetchDevice(String id) async {
    try {
      final response = await apiClient.get<Map<String, Object?>>('/devices/$id');
      final data = response.data;
      if (data == null) return null;
      return Device.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<Device> updateDevice(Device updated) async {
    final response = await apiClient.patch<Map<String, Object?>>(
      '/devices/${updated.id}',
      data: {
        'name': updated.name,
        'location': updated.location,
        'timezone': updated.timezone,
        'city': updated.city,
        'config': {
          'volume': updated.config.volume,
          'brightness': updated.config.brightness,
          'log_level': updated.config.logLevel,
          'auto_ota': updated.config.autoOta,
        },
      },
    );
    return Device.fromJson(response.data ?? {});
  }

  Future<Device> sendCommand(
    String deviceId,
    DeviceCommand command, {
    Object? value,
  }) async {
    await apiClient.post<Map<String, Object?>>(
      '/devices/$deviceId/command',
      data: _commandPayload(command, value),
    );
    final refreshed = await fetchDevice(deviceId);
    if (refreshed == null) {
      throw StateError('Device $deviceId not found after command');
    }
    return refreshed;
  }

  Map<String, Object?> _commandPayload(DeviceCommand command, Object? value) {
    switch (command) {
      case DeviceCommand.setVolume:
        return {
          'type': 'set_volume',
          'payload': {'value': value},
        };
      case DeviceCommand.setBrightness:
        return {
          'type': 'set_brightness',
          'payload': {'value': value},
        };
      case DeviceCommand.setEmotion:
        return {
          'type': 'set_emotion',
          'payload': {'emotion': value},
        };
      case DeviceCommand.setScene:
        return {
          'type': 'set_scene',
          'payload': {'scene': value, 'data': {}},
        };
      case DeviceCommand.reboot:
        return {'type': 'reboot', 'payload': <String, Object?>{}};
      case DeviceCommand.mute:
        return {
          'type': 'set_volume',
          'payload': {'value': 0},
        };
      case DeviceCommand.ttsPlay:
        return {
          'type': 'tts_play',
          'payload': {'text': value},
        };
    }
  }
}

class DeviceListNotifier extends AsyncNotifier<List<Device>> {
  StreamSubscription<DeviceWsEvent>? _wsSub;
  StreamSubscription<DevicePushEvent>? _fcmSub;

  @override
  Future<List<Device>> build() async {
    ref.onDispose(() {
      _wsSub?.cancel();
      _fcmSub?.cancel();
    });

    List<Device> devices;
    try {
      devices = await ref.watch(deviceRepositoryProvider).fetchDevices();
      LocalStorage.cacheDevices(devices);
    } catch (_) {
      devices = LocalStorage.getCachedDevices();
    }

    _listenWsUpdates(devices);
    _listenFcmUpdates();

    return devices;
  }

  void _listenFcmUpdates() {
    _fcmSub?.cancel();
    final push = ref.read(pushServiceProvider);
    _fcmSub = push.deviceEvents.listen((_) {
      refreshDevices();
    });
  }

  void _listenWsUpdates(List<Device> initial) {
    _wsSub?.cancel();
    final ws = ref.read(wsClientProvider);
    _wsSub = ws.events.listen((event) {
      final current = switch (state) {
        AsyncData(:final value) => value,
        _ => <Device>[],
      };

      switch (event.type) {
        case DeviceWsEventType.deviceOnline:
          _updateDeviceField(current, event.deviceId, (d) => d.copyWith(isOnline: true));
        case DeviceWsEventType.deviceOffline:
          _updateDeviceField(current, event.deviceId, (d) => d.copyWith(isOnline: false));
        case DeviceWsEventType.battery:
          _updateDeviceField(current, event.deviceId, (d) => d.copyWith(
            batteryPercent: event.payload['percent'] as int? ?? d.batteryPercent,
            isCharging: event.payload['charging'] as bool? ?? d.isCharging,
          ));
        case DeviceWsEventType.stateUpdate:
          _handleStateUpdate(current, event);
        default:
          break;
      }
    });
  }

  void _updateDeviceField(
    List<Device> current,
    String? deviceId,
    Device Function(Device) updater,
  ) {
    if (deviceId == null) return;
    state = AsyncData([
      for (final device in current)
        if (device.id == deviceId) updater(device) else device,
    ]);
  }

  void _handleStateUpdate(List<Device> current, DeviceWsEvent event) {
    final deviceId = event.deviceId;
    if (deviceId == null) return;

    final category = event.payload['category'] as String?;
    final newValue = event.payload['new'];

    _updateDeviceField(current, deviceId, (d) {
      switch (category) {
        case 'emotion':
          return d.copyWith(emotion: newValue as String? ?? d.emotion);
        case 'power':
          return d.copyWith(batteryPercent: newValue as int? ?? d.batteryPercent);
        default:
          return d;
      }
    });
  }

  Future<void> refreshDevices() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(deviceRepositoryProvider).fetchDevices(),
    );
  }

  Future<void> sendCommand(
    String deviceId,
    DeviceCommand command, {
    Object? value,
  }) async {
    final current = switch (state) {
      AsyncData(:final value) => value,
      _ => <Device>[],
    };
    final updated = await ref
        .read(deviceRepositoryProvider)
        .sendCommand(deviceId, command, value: value);

    state = AsyncData([
      for (final device in current)
        if (device.id == deviceId) updated else device,
    ]);
  }
}
