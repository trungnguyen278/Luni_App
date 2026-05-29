import 'package:flutter/material.dart';

class TalkButton extends StatelessWidget {
  const TalkButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: 'Push-to-talk',
      icon: const Icon(Icons.mic_none),
    );
  }
}
