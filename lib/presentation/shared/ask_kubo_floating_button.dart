import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../ai_assistant/ai_assistant_drawer.dart';

class AskKuboFloatingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? contextScreen;
  final Object? heroTag;

  const AskKuboFloatingButton({
    super.key,
    this.onPressed,
    this.contextScreen,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: onPressed ?? () {
        AiAssistantDrawer.show(context, contextScreen: contextScreen);
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text('Ask Kubo North AI'),
    );
  }
}
