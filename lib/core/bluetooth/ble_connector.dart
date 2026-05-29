import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_protocol.dart';
import 'ble_scanner.dart';

class BleConnector {
  BleConnector();

  BluetoothDevice? _device;
  BluetoothService? _luniService;

  BluetoothDevice? get connectedDevice => _device;
  bool get isConnected => _device?.isConnected ?? false;

  Future<DeviceBleInfo> connectAndReadInfo(BleScanDevice scanDevice) async {
    final remote = scanDevice.remoteDevice;
    if (remote == null) {
      throw BleException('Thiết bị không có thông tin Bluetooth.');
    }

    await remote.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 10),
    );
    _device = remote;

    final services = await remote.discoverServices();
    _luniService = services.firstWhere(
      (s) => s.uuid == Guid(BleProtocol.serviceUuid),
      orElse: () => throw BleException('Không tìm thấy Luni BLE service.'),
    );

    final infoChar = _findCharacteristic(BleProtocol.deviceInfo);
    final raw = await infoChar.read();
    final json = jsonDecode(utf8.decode(raw)) as Map<String, Object?>;

    return DeviceBleInfo(
      mac: json['mac'] as String? ?? scanDevice.id,
      model: json['model'] as String? ?? 'unknown',
      fwVersion: json['fw_version'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Luni',
    );
  }

  Future<bool> unlockWithPin(String pin) async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.authUnlock);
    await char.write(utf8.encode(pin), withoutResponse: false);

    await Future<void>.delayed(const Duration(milliseconds: 200));

    final response = await char.read();
    if (response.isNotEmpty && response.first == 0x00) {
      return true;
    }
    return false;
  }

  Future<void> writeWifi({
    required String ssid,
    required String password,
  }) async {
    _ensureConnected();
    final ssidChar = _findCharacteristic(BleProtocol.ssid);
    final passChar = _findCharacteristic(BleProtocol.password);

    await ssidChar.write(utf8.encode(ssid), withoutResponse: false);
    await passChar.write(utf8.encode(password), withoutResponse: false);
  }

  Future<void> writeServerUrl(String url) async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.wsUrl);
    await char.write(utf8.encode(url), withoutResponse: false);
  }

  Future<void> writeDeviceToken(String token) async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.deviceToken);
    await char.write(utf8.encode(token), withoutResponse: false);
  }

  Future<void> writeUserId(String userId) async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.userId);
    await char.write(utf8.encode(userId), withoutResponse: false);
  }

  Future<void> writeAdminSecret(List<int> secret) async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.adminSecret);
    await char.write(secret, withoutResponse: false);
  }

  Future<bool> adminAuth(List<int> hmacToken) async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.adminAuth);
    await char.write(hmacToken, withoutResponse: false);

    await Future<void>.delayed(const Duration(milliseconds: 200));
    final response = await char.read();
    return response.isNotEmpty && response.first == 0x00;
  }

  Future<Map<String, Object?>> readDiagInfo() async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.diagInfo);
    final raw = await char.read();
    return jsonDecode(utf8.decode(raw)) as Map<String, Object?>;
  }

  Future<int> sendCommand(int command) async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.command);

    await char.setNotifyValue(true);

    await char.write([command], withoutResponse: false);

    final response = await char.onValueReceived
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => [0x01]);

    await char.setNotifyValue(false);

    return response.isNotEmpty ? response.first : 0x01;
  }

  Future<void> writeLogLevel(int level) async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.logLevel);
    await char.write([level], withoutResponse: false);
  }

  Future<bool> commitConfig() async {
    _ensureConnected();
    final char = _findCharacteristic(BleProtocol.commit);

    await char.setNotifyValue(true);
    await char.write([0x01], withoutResponse: false);

    final response = await char.onValueReceived
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => [0x01]);

    await char.setNotifyValue(false);

    return response.isNotEmpty && response.first == 0x00;
  }

  Future<void> restart() async {
    await sendCommand(BleProtocol.restartCommand);
  }

  Future<void> disconnect() async {
    if (_device != null) {
      await _device!.disconnect();
      _device = null;
      _luniService = null;
    }
  }

  BluetoothCharacteristic _findCharacteristic(String uuid) {
    if (_luniService == null) {
      throw BleException('Chưa kết nối BLE service.');
    }
    return _luniService!.characteristics.firstWhere(
      (c) => c.uuid == Guid(uuid),
      orElse: () => throw BleException(
        'Không tìm thấy characteristic $uuid.',
      ),
    );
  }

  void _ensureConnected() {
    if (_device == null || !(_device!.isConnected)) {
      throw BleException('BLE chưa kết nối.');
    }
  }
}

class BleException implements Exception {
  const BleException(this.message);
  final String message;

  @override
  String toString() => 'BleException: $message';
}
