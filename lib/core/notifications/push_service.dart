import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(apiClient: ref.watch(apiClientProvider));
  ref.onDispose(service.dispose);
  return service;
});

class DevicePushEvent {
  const DevicePushEvent({required this.type, required this.deviceId, this.data});

  final String type;
  final String deviceId;
  final Map<String, Object?>? data;
}

class PushService {
  PushService({required this.apiClient});

  final ApiClient apiClient;

  final _deviceEvents = StreamController<DevicePushEvent>.broadcast();
  Stream<DevicePushEvent> get deviceEvents => _deviceEvents.stream;

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleForeground);
  }

  Future<void> _registerToken(String token) async {
    try {
      await apiClient.post<Map<String, Object?>>(
        '/push/register',
        data: {'token': token, 'platform': 'fcm'},
      );
    } catch (_) {
      // server might not be reachable yet
    }
  }

  void _handleForeground(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final deviceId = data['device_id'] as String?;

    if (type != null && deviceId != null) {
      _deviceEvents.add(DevicePushEvent(
        type: type,
        deviceId: deviceId,
        data: data.cast<String, Object?>(),
      ));
    }
  }

  void dispose() {
    _deviceEvents.close();
  }
}
