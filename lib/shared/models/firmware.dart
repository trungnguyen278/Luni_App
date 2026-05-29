class Firmware {
  const Firmware({
    required this.id,
    required this.version,
    required this.model,
    required this.sha256,
    required this.size,
    required this.changelog,
    required this.channel,
    required this.createdAt,
  });

  final String id;
  final String version;
  final String model;
  final String sha256;
  final int size;
  final String changelog;
  final String channel;
  final DateTime createdAt;

  factory Firmware.fromJson(Map<String, Object?> json) {
    return Firmware(
      id: json['id'] as String? ?? '',
      version: json['version'] as String? ?? '',
      model: json['model'] as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      changelog: json['changelog'] as String? ?? '',
      channel: json['channel'] as String? ?? 'stable',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Firmware mockStable() {
    return Firmware(
      id: 'fw-2.1.1',
      version: '2.1.1',
      model: 'luni_v2_s3c5',
      sha256:
          'b42c9c0f7a2a64c53d0a2f6c1a12e7a94b26c8f0d1f2b0e7c1a5b33e92a0abcd',
      size: 1887436,
      changelog: 'Cải thiện reconnect WebSocket và giảm độ trễ TTS.',
      channel: 'stable',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
  }
}
