class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'LUNI_API_BASE_URL',
    defaultValue: 'https://lunirobot.io.vn/api/v1',
  );

  static const wsBaseUrl = String.fromEnvironment(
    'LUNI_WS_BASE_URL',
    defaultValue: 'wss://lunirobot.io.vn',
  );

  static const defaultDeviceWsUrl = String.fromEnvironment(
    'LUNI_DEVICE_WS_URL',
    defaultValue: 'wss://lunirobot.io.vn/ws/device',
  );

  static const defaultTimezone = 'Asia/Ho_Chi_Minh';
  static const defaultRobotName = 'Luni';
}
