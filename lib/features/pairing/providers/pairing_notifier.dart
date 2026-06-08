import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/bluetooth/ble_connector.dart';
import '../../../core/bluetooth/ble_scanner.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

final pairingProvider = NotifierProvider<PairingNotifier, PairingState>(
  PairingNotifier.new,
);

enum PairingStage {
  scanning,
  connecting,
  readInfo,
  pinAuth,
  wifiSetup,
  writeWifi,
  serverSetup,
  naming,
  generateToken,
  writeToken,
  writeUrl,
  commit,
  restart,
  verify,
  done,
  error;

  String get label {
    switch (this) {
      case PairingStage.scanning:
        return 'Quét BLE';
      case PairingStage.connecting:
        return 'Kết nối';
      case PairingStage.readInfo:
        return 'Đọc thông tin';
      case PairingStage.pinAuth:
        return 'Xác thực PIN';
      case PairingStage.wifiSetup:
        return 'WiFi';
      case PairingStage.writeWifi:
        return 'Ghi WiFi';
      case PairingStage.serverSetup:
        return 'Server';
      case PairingStage.naming:
        return 'Đặt tên';
      case PairingStage.generateToken:
        return 'Tạo token';
      case PairingStage.writeToken:
        return 'Ghi token';
      case PairingStage.writeUrl:
        return 'Ghi URL';
      case PairingStage.commit:
        return 'Lưu cấu hình';
      case PairingStage.restart:
        return 'Restart';
      case PairingStage.verify:
        return 'Verify';
      case PairingStage.done:
        return 'Hoàn tất';
      case PairingStage.error:
        return 'Lỗi';
    }
  }
}

class PairingState {
  const PairingState({
    required this.stage,
    required this.nearbyDevices,
    this.selectedDevice,
    this.deviceInfo,
    this.ssid,
    this.serverUrl = AppConfig.defaultDeviceWsUrl,
    this.robotName = AppConfig.defaultRobotName,
    this.deviceToken,
    this.error,
    this.pinAttempts = 0,
  });

  final PairingStage stage;
  final List<BleScanDevice> nearbyDevices;
  final BleScanDevice? selectedDevice;
  final DeviceBleInfo? deviceInfo;
  final String? ssid;
  final String serverUrl;
  final String robotName;
  final String? deviceToken;
  final String? error;
  final int pinAttempts;

  bool get isBusy {
    return switch (stage) {
      PairingStage.connecting ||
      PairingStage.readInfo ||
      PairingStage.writeWifi ||
      PairingStage.generateToken ||
      PairingStage.writeToken ||
      PairingStage.writeUrl ||
      PairingStage.commit ||
      PairingStage.restart ||
      PairingStage.verify => true,
      _ => false,
    };
  }

  PairingState copyWith({
    PairingStage? stage,
    List<BleScanDevice>? nearbyDevices,
    BleScanDevice? selectedDevice,
    DeviceBleInfo? deviceInfo,
    String? ssid,
    String? serverUrl,
    String? robotName,
    String? deviceToken,
    String? error,
    int? pinAttempts,
  }) {
    return PairingState(
      stage: stage ?? this.stage,
      nearbyDevices: nearbyDevices ?? this.nearbyDevices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ssid: ssid ?? this.ssid,
      serverUrl: serverUrl ?? this.serverUrl,
      robotName: robotName ?? this.robotName,
      deviceToken: deviceToken ?? this.deviceToken,
      error: error,
      pinAttempts: pinAttempts ?? this.pinAttempts,
    );
  }
}

class PairingNotifier extends Notifier<PairingState> {
  late final BleScanner _scanner;
  late final BleConnector _connector;
  StreamSubscription<List<BleScanDevice>>? _scanSub;

  @override
  PairingState build() {
    _scanner = ref.read(bleScannerProvider);
    _connector = BleConnector();

    ref.onDispose(() {
      _scanSub?.cancel();
      _scanner.stopScan();
      _connector.disconnect();
    });

    _startScan();

    return const PairingState(
      stage: PairingStage.scanning,
      nearbyDevices: [],
    );
  }

  void _startScan() {
    _scanSub?.cancel();
    _scanSub = _scanner.scan().listen(
      (devices) {
        state = state.copyWith(nearbyDevices: devices);
      },
      onError: (Object e) {
        state = state.copyWith(
          stage: PairingStage.error,
          error: e is BleScanPermissionDenied
              ? e.toString()
              : 'Không quét được BLE: $e',
        );
      },
    );
  }

  void reset() {
    _connector.disconnect();
    _scanSub?.cancel();
    state = const PairingState(
      stage: PairingStage.scanning,
      nearbyDevices: [],
    );
    _startScan();
  }

  Future<void> selectDevice(BleScanDevice device) async {
    await _scanner.stopScan();
    _scanSub?.cancel();

    state = state.copyWith(
      stage: PairingStage.connecting,
      selectedDevice: device,
      error: null,
    );

    try {
      final info = await _connector.connectAndReadInfo(device);
      state = state.copyWith(
        stage: PairingStage.pinAuth,
        deviceInfo: info,
        robotName: info.name,
      );
    } on BleException catch (e) {
      state = state.copyWith(stage: PairingStage.error, error: e.message);
    } catch (_) {
      state = state.copyWith(
        stage: PairingStage.error,
        error: 'Không kết nối được BLE. Hãy thử lại gần robot hơn.',
      );
    }
  }

  Future<void> submitPin(String pin) async {
    state = state.copyWith(stage: PairingStage.readInfo, error: null);

    try {
      final unlocked = await _connector.unlockWithPin(pin);
      if (!unlocked) {
        state = state.copyWith(
          stage: PairingStage.pinAuth,
          pinAttempts: state.pinAttempts + 1,
          error: 'PIN chưa đúng. Kiểm tra mã trên màn hình robot.',
        );
        return;
      }
      state = state.copyWith(stage: PairingStage.wifiSetup, pinAttempts: 0);
    } on BleException catch (e) {
      state = state.copyWith(stage: PairingStage.error, error: e.message);
    }
  }

  Future<void> submitWifi({
    required String ssid,
    required String password,
  }) async {
    if (ssid.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(
        stage: PairingStage.wifiSetup,
        error: 'Nhập SSID và mật khẩu WiFi.',
      );
      return;
    }

    state = state.copyWith(
      stage: PairingStage.writeWifi,
      ssid: ssid.trim(),
      error: null,
    );

    try {
      await _connector.writeWifi(ssid: ssid.trim(), password: password);
      state = state.copyWith(stage: PairingStage.serverSetup);
    } on BleException catch (e) {
      state = state.copyWith(stage: PairingStage.error, error: e.message);
    }
  }

  void submitServerUrl(String serverUrl) {
    state = state.copyWith(
      stage: PairingStage.naming,
      serverUrl: serverUrl.trim().isEmpty
          ? AppConfig.defaultDeviceWsUrl
          : serverUrl.trim(),
      error: null,
    );
  }

  Future<void> submitRobotName(String name) async {
    final robotName = name.trim().isEmpty ? AppConfig.defaultRobotName : name.trim();

    state = state.copyWith(
      stage: PairingStage.generateToken,
      robotName: robotName,
      error: null,
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final auth = ref.read(authControllerProvider);
      final info = state.deviceInfo!;

      final response = await apiClient.post<Map<String, Object?>>(
        '/devices',
        data: {
          'mac': info.mac,
          'name': robotName,
          'model': info.model,
          'owner_id': auth.user?.id,
        },
      );

      final data = response.data ?? {};
      final deviceToken = data['device_token'] as String? ?? '';
      final adminSecret = data['admin_secret'] as String?;

      state = state.copyWith(stage: PairingStage.writeToken, deviceToken: deviceToken);

      await _connector.writeDeviceToken(deviceToken);
      if (auth.user != null) {
        await _connector.writeUserId(auth.user!.id);
      }
      if (adminSecret != null) {
        await _connector.writeAdminSecret(adminSecret.codeUnits);
      }

      state = state.copyWith(stage: PairingStage.writeUrl);
      await _connector.writeServerUrl(state.serverUrl);

      state = state.copyWith(stage: PairingStage.commit);
      final committed = await _connector.commitConfig();
      if (!committed) {
        state = state.copyWith(
          stage: PairingStage.error,
          error: 'Robot không lưu được cấu hình. Hãy thử lại.',
        );
        return;
      }

      state = state.copyWith(stage: PairingStage.restart);
      await _connector.restart();
      await _connector.disconnect();

      state = state.copyWith(stage: PairingStage.verify);
      await _verifyDeviceOnline(data['id'] as String? ?? info.mac, apiClient);

      state = state.copyWith(stage: PairingStage.done);
    } on BleException catch (e) {
      state = state.copyWith(stage: PairingStage.error, error: e.message);
    } catch (e) {
      state = state.copyWith(
        stage: PairingStage.error,
        error: 'Provisioning thất bại: $e',
      );
    }
  }

  Future<void> _verifyDeviceOnline(String deviceId, ApiClient apiClient) async {
    for (var i = 0; i < 15; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        final response = await apiClient.get<Map<String, Object?>>(
          '/devices/$deviceId/status',
        );
        final isOnline = (response.data ?? {})['is_online'] as bool? ?? false;
        if (isOnline) return;
      } catch (_) {
        // device not ready yet
      }
    }
  }
}
