import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final bleScannerProvider = Provider<BleScanner>((ref) {
  return BleScanner();
});

class BleScanDevice {
  const BleScanDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.model,
    this.remoteDevice,
  });

  final String id;
  final String name;
  final int rssi;
  final String model;
  final BluetoothDevice? remoteDevice;
}

class DeviceBleInfo {
  const DeviceBleInfo({
    required this.mac,
    required this.model,
    required this.fwVersion,
    required this.name,
  });

  final String mac;
  final String model;
  final String fwVersion;
  final String name;
}

class BleScanner {
  BleScanner();

  StreamSubscription<List<ScanResult>>? _scanSub;

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every(
      (s) => s.isGranted || s.isLimited,
    );
  }

  Stream<List<BleScanDevice>> scan({Duration timeout = const Duration(seconds: 10)}) async* {
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      yield [];
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    final devices = <String, BleScanDevice>{};

    await FlutterBluePlus.startScan(
      withServices: [Guid('0000ff01-0000-1000-8000-00805f9b34fb')],
      timeout: timeout,
    );

    yield* FlutterBluePlus.scanResults.map((results) {
      for (final result in results) {
        final name = result.advertisementData.advName;
        if (name.isEmpty) continue;

        devices[result.device.remoteId.str] = BleScanDevice(
          id: result.device.remoteId.str,
          name: name,
          rssi: result.rssi,
          model: _extractModel(result.advertisementData),
          remoteDevice: result.device,
        );
      }
      return devices.values.toList();
    });
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  String _extractModel(AdvertisementData adv) {
    final name = adv.advName;
    if (name.toLowerCase().startsWith('luni')) {
      return 'luni_v2_s3c5';
    }
    return 'unknown';
  }
}
