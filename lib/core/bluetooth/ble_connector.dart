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
    final authChar = _findCharacteristic(BleProtocol.authUnlock);
    final resultChar = _findCharacteristic(BleProtocol.command);

    // Firmware delivers the PIN result via notifyCommandResult(), which notifies
    // on the COMMAND characteristic (0x0011) — NOT the auth char we write to.
    // Subscribe there before writing the PIN to avoid missing the notify.
    await resultChar.setNotifyValue(true);
    final result = resultChar.onValueReceived
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => [0x01]);

    await authChar.write(utf8.encode(pin), withoutResponse: false);

    final response = await result;
    await resultChar.setNotifyValue(false);

    return response.isNotEmpty && response.first == 0x00;
  }

  /// Reads the WiFi networks the robot scanned at boot. Requires Level 1
  /// (call after [unlockWithPin]). Returns an empty list if the firmware
  /// predates the wifi-scan characteristic or the read fails, so the UI can
  /// fall back to manual SSID entry.
  Future<List<WifiNetwork>> readWifiNetworks() async {
    _ensureConnected();
    try {
      final char = _findCharacteristic(BleProtocol.wifiScan);
      final raw = await char.read();
      if (raw.isEmpty) return const [];
      final decoded = jsonDecode(utf8.decode(raw));
      if (decoded is! List) return const [];
      final seen = <String>{};
      final result = <WifiNetwork>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final ssid = (entry['ssid'] as String? ?? '').trim();
        if (ssid.isEmpty || !seen.add(ssid)) continue;
        result.add(WifiNetwork(
          ssid: ssid,
          rssi: (entry['rssi'] as num?)?.toInt() ?? -99,
        ));
      }
      return result;
    } catch (_) {
      return const [];
    }
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
    final adminChar = _findCharacteristic(BleProtocol.adminAuth);
    final resultChar = _findCharacteristic(BleProtocol.command);

    // Result delivered via notifyCommandResult() on the COMMAND characteristic.
    await resultChar.setNotifyValue(true);
    final result = resultChar.onValueReceived
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => [0x01]);

    await adminChar.write(hmacToken, withoutResponse: false);

    final response = await result;
    await resultChar.setNotifyValue(false);

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

    // Subscribe BEFORE writing: the firmware notifies the result before it
    // returns the write response, so a listener attached after the write can
    // miss the notification and time out.
    final result = char.onValueReceived
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => <int>[]);

    await char.write([command], withoutResponse: false);

    var response = await result;
    // Fallback: if the stream raced, the notify value is still buffered here.
    if (response.isEmpty && char.lastValue.isNotEmpty) response = char.lastValue;
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

    // Subscribe BEFORE writing — the firmware sends the commit-result notify
    // before returning the write response, so attaching the listener after the
    // write races and can miss the 0x00 result (shows "robot không lưu được").
    final result = char.onValueReceived
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => <int>[]);

    await char.write([0x01], withoutResponse: false);

    var response = await result;
    // Fallback: if the stream raced, the notify value is still buffered here.
    if (response.isEmpty && char.lastValue.isNotEmpty) response = char.lastValue;
    await char.setNotifyValue(false);

    return response.isNotEmpty && response.first == 0x00;
  }

  Future<void> restart() async {
    // The firmware reboots inside the RESTART command handler (esp_restart never
    // returns), so the write never gets a response and the link drops mid-call.
    // The command IS delivered and acted on — swallow the resulting GATT error.
    try {
      await sendCommand(BleProtocol.restartCommand);
    } catch (_) {
      // Expected: device rebooted and dropped the BLE link.
    }
  }

  Future<void> disconnect() async {
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {
        // Link may already be gone (e.g. after a device reboot) — ignore.
      }
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

class WifiNetwork {
  const WifiNetwork({required this.ssid, required this.rssi});

  final String ssid;
  final int rssi;
}
