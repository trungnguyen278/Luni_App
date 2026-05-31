import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Server-sourced weather + lunar calendar for a device.
///
/// Wraps `GET /data/sync/{deviceId}` (SyncDataService.build_sync_payload),
/// which assembles time + weather + calendar + location server-side using the
/// device's stored coordinates. `weather` is null when the device has no
/// coordinates or the server has no OpenWeather key configured.
class SyncData {
  const SyncData({this.weather, this.lunar, this.city});

  final SyncWeather? weather;
  final SyncLunar? lunar;
  final String? city;

  factory SyncData.fromJson(Map<String, Object?> json) {
    final weather = json['weather'];
    final calendar = json['calendar'];
    final location = json['location'];
    final lunar = calendar is Map ? calendar['lunar'] : null;

    return SyncData(
      weather: weather is Map
          ? SyncWeather.fromJson(weather.cast<String, Object?>())
          : null,
      lunar: lunar is Map
          ? SyncLunar.fromJson(lunar.cast<String, Object?>())
          : null,
      city: location is Map ? location['city'] as String? : null,
    );
  }
}

class SyncWeather {
  const SyncWeather({
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.condition,
    this.aqi,
  });

  final double temp;
  final double feelsLike;
  final int humidity;
  final String condition;
  final int? aqi;

  factory SyncWeather.fromJson(Map<String, Object?> json) {
    return SyncWeather(
      temp: (json['temp'] as num?)?.toDouble() ?? 0,
      feelsLike: (json['feels_like'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      condition: json['condition'] as String? ?? 'unknown',
      aqi: (json['aqi'] as num?)?.toInt(),
    );
  }

  /// Vietnamese label for the server's normalised condition code.
  String get conditionLabel {
    switch (condition) {
      case 'clear':
        return 'Quang đãng';
      case 'few_clouds':
        return 'Ít mây';
      case 'partly_cloudy':
        return 'Có mây';
      case 'overcast':
        return 'Nhiều mây';
      case 'rain':
        return 'Mưa';
      case 'drizzle':
        return 'Mưa phùn';
      case 'thunderstorm':
        return 'Dông';
      case 'snow':
        return 'Tuyết';
      case 'fog':
        return 'Sương mù';
      default:
        return 'Không rõ';
    }
  }
}

class SyncLunar {
  const SyncLunar({
    required this.day,
    required this.month,
    required this.year,
    this.isLeapMonth = false,
  });

  final int day;
  final int month;
  final String year;
  final bool isLeapMonth;

  factory SyncLunar.fromJson(Map<String, Object?> json) {
    return SyncLunar(
      day: (json['day'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: json['year'] as String? ?? '',
      isLeapMonth: json['is_leap_month'] as bool? ?? false,
    );
  }
}

/// Fetches sync data for a device. Auto-disposed; refresh via `ref.invalidate`.
final syncDataProvider =
    FutureProvider.autoDispose.family<SyncData, String>((ref, deviceId) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get<Map<String, Object?>>('/data/sync/$deviceId');
  return SyncData.fromJson(res.data ?? const {});
});
