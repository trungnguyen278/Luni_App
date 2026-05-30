import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/ws_client.dart';
import '../../../shared/models/interaction.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<Interaction> _messages = [];
  bool _loading = true;
  bool _sending = false;
  StreamSubscription<DeviceWsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<List<dynamic>>(
        '/devices/${widget.deviceId}/interactions',
        queryParameters: {'limit': 50},
      );
      final data = response.data ?? [];
      final interactions = data
          .whereType<Map<String, Object?>>()
          .map(_interactionFromJson)
          .toList();
      if (mounted) {
        setState(() {
          _messages.addAll(interactions);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    _wsSub = ref.read(wsClientProvider).events
        .where((e) => e.type == DeviceWsEventType.interactionResult)
        .listen((event) {
      if (!mounted) return;
      final payload = event.payload;
      setState(() {
        _messages.add(Interaction(
          id: _messages.length + 1,
          deviceId: widget.deviceId,
          source: InteractionSource.app,
          inputText: payload['input'] as String? ?? '',
          outputText: payload['output'] as String? ?? '',
          emotion: payload['emotion'] as String? ?? 'neutral',
          createdAt: DateTime.now(),
          latencyMs: payload['latency_ms'] as int?,
        ));
      });
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: LuniColors.cyan));
    }

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      LuniFace(emotion: 'curious', size: 110),
                      SizedBox(height: 18),
                      Text('Chưa có cuộc trò chuyện nào.',
                          style: LuniTextStyles.body),
                      SizedBox(height: 4),
                      Text('Hãy nhắn gì đó cho Luni nhé!',
                          style: LuniTextStyles.sub),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - 1 - index];
                    return Column(
                      children: [
                        if (message.inputText.isNotEmpty)
                          ChatBubble(text: message.inputText, isUser: true),
                        if (message.inputText.isNotEmpty && message.outputText.isNotEmpty)
                          const SizedBox(height: 8),
                        if (message.outputText.isNotEmpty)
                          ChatBubble(
                            text: message.outputText,
                            isUser: false,
                            emotion: message.emotion,
                          ),
                      ],
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemCount: _messages.length,
                ),
        ),
        ChatInput(onSend: (text) => _send(text)),
      ],
    );
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add(Interaction(
        id: _messages.length + 1,
        deviceId: widget.deviceId,
        source: InteractionSource.app,
        inputText: text,
        outputText: '',
        emotion: 'thinking',
        createdAt: DateTime.now(),
      ));
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, Object?>>(
        '/devices/${widget.deviceId}/interact',
        data: {'text': text, 'source': 'app'},
      );

      final data = response.data ?? {};
      if (mounted) {
        setState(() {
          _messages.last = Interaction(
            id: _messages.last.id,
            deviceId: widget.deviceId,
            source: InteractionSource.app,
            inputText: text,
            outputText: data['output'] as String? ?? 'Không có phản hồi.',
            emotion: data['emotion'] as String? ?? 'neutral',
            createdAt: DateTime.now(),
            latencyMs: data['latency_ms'] as int?,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.last = Interaction(
            id: _messages.last.id,
            deviceId: widget.deviceId,
            source: InteractionSource.app,
            inputText: text,
            outputText: 'Lỗi gửi tin nhắn: $e',
            emotion: 'sad',
            createdAt: DateTime.now(),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Interaction _interactionFromJson(Map<String, Object?> json) {
    return Interaction(
      id: json['id'] as int? ?? 0,
      deviceId: json['device_id'] as String? ?? widget.deviceId,
      source: _sourceFromString(json['source'] as String?),
      inputText: json['input_text'] as String? ?? '',
      outputText: json['output_text'] as String? ?? '',
      emotion: json['emotion'] as String? ?? 'neutral',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      latencyMs: json['latency_ms'] as int?,
    );
  }

  InteractionSource _sourceFromString(String? value) {
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
}
