import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bluetooth/ble_connector.dart';
import '../../../core/bluetooth/ble_protocol.dart';
import '../../../core/bluetooth/ble_scanner.dart';
import '../../../core/network/api_client.dart';

final adminBleProvider = NotifierProvider<AdminBleNotifier, AdminBleState>(
  AdminBleNotifier.new,
);

enum AdminBleStage {
  idle,
  scanning,
  connected,
  levelOne,
  levelTwo,
  commandSent,
  error,
}

class AdminBleState {
  const AdminBleState({required this.stage, this.message, this.diagInfo});

  final AdminBleStage stage;
  final String? message;
  final Map<String, Object?>? diagInfo;

  AdminBleState copyWith({
    AdminBleStage? stage,
    String? message,
    Map<String, Object?>? diagInfo,
  }) {
    return AdminBleState(
      stage: stage ?? this.stage,
      message: message,
      diagInfo: diagInfo ?? this.diagInfo,
    );
  }
}

class AdminBleNotifier extends Notifier<AdminBleState> {
  BleConnector? _connector;
  BleScanner? _scanner;

  @override
  AdminBleState build() {
    ref.onDispose(() {
      _connector?.disconnect();
      _scanner?.stopScan();
    });
    return const AdminBleState(stage: AdminBleStage.idle);
  }

  Future<void> connect(String deviceId) async {
    _scanner = ref.read(bleScannerProvider);
    _connector = BleConnector();

    state = const AdminBleState(
      stage: AdminBleStage.scanning,
      message: 'Đang tìm robot...',
    );

    try {
      BleScanDevice? target;
      await for (final devices in _scanner!.scan(timeout: const Duration(seconds: 15))) {
        for (final d in devices) {
          if (d.id == deviceId || d.name.contains(deviceId.substring(deviceId.length - 4))) {
            target = d;
            break;
          }
        }
        if (target != null) break;
      }
      await _scanner!.stopScan();

      if (target == null) {
        state = const AdminBleState(
          stage: AdminBleStage.error,
          message: 'Không tìm thấy robot. Đảm bảo robot đang bật và ở gần.',
        );
        return;
      }

      state = const AdminBleState(
        stage: AdminBleStage.scanning,
        message: 'Đang kết nối...',
      );

      await _connector!.connectAndReadInfo(target);

      state = const AdminBleState(
        stage: AdminBleStage.levelOne,
        message: 'Đã kết nối. Nhập PIN để xác thực Level 1.',
      );
    } on BleException catch (e) {
      state = AdminBleState(stage: AdminBleStage.error, message: e.message);
    } catch (e) {
      state = AdminBleState(
        stage: AdminBleStage.error,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<void> unlockPin(String pin) async {
    if (_connector == null) return;

    try {
      final ok = await _connector!.unlockWithPin(pin);
      if (!ok) {
        state = state.copyWith(
          stage: AdminBleStage.levelOne,
          message: 'PIN không đúng. Thử lại.',
        );
        return;
      }
      state = state.copyWith(
        stage: AdminBleStage.levelOne,
        message: 'Level 1 OK. Đang xác thực admin...',
      );
    } on BleException catch (e) {
      state = AdminBleState(stage: AdminBleStage.error, message: e.message);
    }
  }

  Future<void> authenticateAdmin(String deviceId) async {
    if (_connector == null) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post<Map<String, Object?>>(
        '/devices/$deviceId/ble-token',
      );
      final data = response.data ?? {};
      final tokenHex = data['admin_token'] as String? ?? '';

      final tokenBytes = <int>[];
      for (var i = 0; i < tokenHex.length - 1; i += 2) {
        tokenBytes.add(int.parse(tokenHex.substring(i, i + 2), radix: 16));
      }

      final ok = await _connector!.adminAuth(tokenBytes);
      if (!ok) {
        state = const AdminBleState(
          stage: AdminBleStage.error,
          message: 'Xác thực admin thất bại. Tài khoản không có quyền.',
        );
        return;
      }

      final diagInfo = await _connector!.readDiagInfo();

      state = AdminBleState(
        stage: AdminBleStage.levelTwo,
        message: 'Đã xác thực admin BLE Level 2.',
        diagInfo: diagInfo,
      );
    } on BleException catch (e) {
      state = AdminBleState(stage: AdminBleStage.error, message: e.message);
    } catch (e) {
      state = AdminBleState(
        stage: AdminBleStage.error,
        message: 'Lỗi xác thực admin: $e',
      );
    }
  }

  Future<void> sendCommand(int command) async {
    if (_connector == null) return;

    state = state.copyWith(
      stage: AdminBleStage.commandSent,
      message: 'Đang gửi command 0x${command.toRadixString(16)}...',
    );

    try {
      final result = await _connector!.sendCommand(command);
      if (result == 0x00) {
        final diagInfo = await _connector!.readDiagInfo();
        state = AdminBleState(
          stage: AdminBleStage.levelTwo,
          message: 'Robot trả ACK OK.',
          diagInfo: diagInfo,
        );
      } else if (result == 0x02) {
        state = state.copyWith(
          stage: AdminBleStage.error,
          message: 'UNAUTHORIZED — cần auth lại.',
        );
      } else {
        state = state.copyWith(
          stage: AdminBleStage.levelTwo,
          message: 'Command trả về lỗi (0x${result.toRadixString(16)}).',
        );
      }
    } on BleException catch (e) {
      state = AdminBleState(stage: AdminBleStage.error, message: e.message);
    }
  }

  Future<void> factoryReset() => sendCommand(BleProtocol.factoryResetCommand);
  Future<void> fullWipe() => sendCommand(BleProtocol.fullWipeCommand);
  Future<void> rollbackFirmware() => sendCommand(BleProtocol.rollbackFirmwareCommand);
  Future<void> enableDebug() => sendCommand(BleProtocol.enableDebugCommand);
  Future<void> disableDebug() => sendCommand(BleProtocol.disableDebugCommand);

  Future<void> disconnect() async {
    await _connector?.disconnect();
    _connector = null;
    state = const AdminBleState(stage: AdminBleStage.idle);
  }
}
