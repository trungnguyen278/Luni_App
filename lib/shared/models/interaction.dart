enum InteractionSource { app, web, voice, button }

class Interaction {
  const Interaction({
    required this.id,
    required this.deviceId,
    required this.source,
    required this.inputText,
    required this.outputText,
    required this.emotion,
    required this.createdAt,
    this.latencyMs,
  });

  final int id;
  final String deviceId;
  final InteractionSource source;
  final String inputText;
  final String outputText;
  final String emotion;
  final DateTime createdAt;
  final int? latencyMs;

  factory Interaction.fromJson(Map<String, Object?> json) {
    return Interaction(
      id: json['id'] as int? ?? 0,
      deviceId: json['device_id'] as String? ?? '',
      source: _sourceFromString(json['source'] as String?),
      inputText: json['input_text'] as String? ?? '',
      outputText: json['output_text'] as String? ?? '',
      emotion: json['emotion'] as String? ?? 'neutral',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      latencyMs: json['latency_ms'] as int?,
    );
  }

  static InteractionSource _sourceFromString(String? value) {
    switch (value) {
      case 'app':
        return InteractionSource.app;
      case 'web':
        return InteractionSource.web;
      case 'voice':
        return InteractionSource.voice;
      case 'button':
        return InteractionSource.button;
      default:
        return InteractionSource.app;
    }
  }

  static List<Interaction> mockForDevice(String deviceId) {
    return [
      Interaction(
        id: 1,
        deviceId: deviceId,
        source: InteractionSource.app,
        inputText: 'Hôm nay thời tiết thế nào?',
        outputText: 'Trời đang dễ chịu, có thể có mưa nhẹ vào chiều tối.',
        emotion: 'curious',
        createdAt: DateTime.now().subtract(const Duration(minutes: 9)),
        latencyMs: 860,
      ),
    ];
  }
}
