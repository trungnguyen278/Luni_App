class BleProtocol {
  const BleProtocol._();

  static const serviceUuid = '0000ff01-0000-1000-8000-00805f9b34fb';

  static const ssid = '00000001-0000-1000-8000-00805f9b34fb';
  static const password = '00000002-0000-1000-8000-00805f9b34fb';
  static const wsUrl = '00000003-0000-1000-8000-00805f9b34fb';
  static const commit = '00000004-0000-1000-8000-00805f9b34fb';
  static const deviceToken = '00000008-0000-1000-8000-00805f9b34fb';
  static const wifiScan = '00000009-0000-1000-8000-00805f9b34fb';
  static const userId = '00000005-0000-1000-8000-00805f9b34fb';
  static const deviceInfo = '00000006-0000-1000-8000-00805f9b34fb';
  static const diagInfo = '00000007-0000-1000-8000-00805f9b34fb';
  static const authUnlock = '00000010-0000-1000-8000-00805f9b34fb';
  static const command = '00000011-0000-1000-8000-00805f9b34fb';
  static const adminAuth = '00000012-0000-1000-8000-00805f9b34fb';
  static const logLevel = '00000013-0000-1000-8000-00805f9b34fb';
  static const adminSecret = '00000014-0000-1000-8000-00805f9b34fb';

  static const restartCommand = 0x01;
  static const factoryResetCommand = 0x10;
  static const fullWipeCommand = 0x11;
  static const rollbackFirmwareCommand = 0x12;
  static const enableDebugCommand = 0x13;
  static const disableDebugCommand = 0x14;
  static const clearUsersCommand = 0x15;
  static const enterDfuCommand = 0x16;
}
