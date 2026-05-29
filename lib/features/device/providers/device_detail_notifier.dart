import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/device.dart';
import 'device_list_notifier.dart';

final deviceDetailProvider = Provider.family<Device?, String>((ref, deviceId) {
  final devices = switch (ref.watch(deviceListProvider)) {
    AsyncData(:final value) => value,
    _ => <Device>[],
  };
  for (final device in devices) {
    if (device.id == deviceId) {
      return device;
    }
  }
  return null;
});
