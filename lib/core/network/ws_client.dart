import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/auth_provider.dart';
import '../config/app_config.dart';

final wsClientProvider = Provider<DeviceWsClient>((ref) {
  final auth = ref.watch(authControllerProvider);
  final client = DeviceWsClient(
    baseUrl: AppConfig.wsBaseUrl,
    accessToken: auth.accessToken,
  );
  ref.onDispose(client.dispose);
  return client;
});

final activeDeviceWsProvider =
    Provider.autoDispose.family<DeviceWsClient, String>((ref, deviceId) {
  final ws = ref.watch(wsClientProvider);
  ws.connect(deviceId);
  ref.onDispose(ws.disconnect);
  return ws;
});

enum DeviceWsEventType {
  stateUpdate,
  deviceOnline,
  deviceOffline,
  otaProgress,
  error,
  battery,
  interactionResult,
  currentState,
  log,
  unknown,
}

class DeviceWsEvent {
  const DeviceWsEvent({
    required this.type,
    required this.payload,
    this.deviceId,
  });

  final DeviceWsEventType type;
  final Map<String, Object?> payload;
  final String? deviceId;

  factory DeviceWsEvent.fromJson(Map<String, Object?> json) {
    return DeviceWsEvent(
      type: _typeFromString(json['type'] as String?),
      payload: json['payload'] as Map<String, Object?>? ?? {},
      deviceId: json['device_id'] as String?,
    );
  }

  static DeviceWsEventType _typeFromString(String? value) {
    switch (value) {
      case 'state_update':
        return DeviceWsEventType.stateUpdate;
      case 'device_online':
        return DeviceWsEventType.deviceOnline;
      case 'device_offline':
        return DeviceWsEventType.deviceOffline;
      case 'ota_progress':
        return DeviceWsEventType.otaProgress;
      case 'error':
        return DeviceWsEventType.error;
      case 'battery':
        return DeviceWsEventType.battery;
      case 'interaction_result':
        return DeviceWsEventType.interactionResult;
      case 'current_state':
        return DeviceWsEventType.currentState;
      case 'log':
        return DeviceWsEventType.log;
      default:
        return DeviceWsEventType.unknown;
    }
  }
}

class DeviceWsClient {
  DeviceWsClient({required this.baseUrl, required this.accessToken});

  final String baseUrl;
  final String? accessToken;

  final _events = StreamController<DeviceWsEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  String? _currentDeviceId;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  Stream<DeviceWsEvent> get events => _events.stream;
  bool get isConnected => _channel != null;

  Stream<DeviceWsEvent> statusStream(String deviceId) {
    return events.where(
      (event) => event.deviceId == null || event.deviceId == deviceId,
    );
  }

  void connect(String deviceId) {
    _currentDeviceId = deviceId;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    _cleanup();
    if (_disposed) return;
    if (accessToken == null || accessToken!.isEmpty) return;
    if (_currentDeviceId == null) return;

    final uri = Uri.parse('$baseUrl/ws/app/$_currentDeviceId')
        .replace(queryParameters: {'token': accessToken});

    _channel = WebSocketChannel.connect(uri);
    _subscription = _channel!.stream.listen(
      _handleData,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
    );

    _startHeartbeat();
  }

  void _handleData(Object? data) {
    _reconnectAttempts = 0;
    if (data is! String) return;
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, Object?>) {
        _events.add(DeviceWsEvent.fromJson(decoded));
      }
    } on Object {
      // ignore malformed messages
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectAttempts >= 10) return;
    _reconnectAttempts++;
    final seconds = (1 << (_reconnectAttempts - 1)).clamp(1, 30);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: seconds), _doConnect);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => send({'type': 'ping', 'ts': DateTime.now().millisecondsSinceEpoch}),
    );
  }

  void send(Map<String, Object?> message) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(message));
    } on Object {
      // sink closed
    }
  }

  void sendCommand(String type, Map<String, Object?> payload) {
    send({
      'type': type,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    });
  }

  void disconnect() {
    _currentDeviceId = null;
    _cleanup();
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    _cleanup();
    _events.close();
  }
}
