import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ai_assistant_repository.dart';
import '../../domain/entities/ai_message.dart';
import '../family_portal/resident_provider.dart';

class AiAssistantState {
  final List<AiMessage> messages;
  final bool isGenerating;
  final List<String> quickSuggestions;

  const AiAssistantState({
    this.messages = const [],
    this.isGenerating = false,
    this.quickSuggestions = const [
      'What should I bring on visits?',
      'How to soothe agitation during sundowning?',
      'Dignity-first ways to encourage meal intake',
      'Montessori activities for calm afternoons',
      'What does Margaret enjoy most?',
    ],
  });

  AiAssistantState copyWith({
    List<AiMessage>? messages,
    bool? isGenerating,
    List<String>? quickSuggestions,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      quickSuggestions: quickSuggestions ?? this.quickSuggestions,
    );
  }
}

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final AiAssistantRepository _repository;
  final String _residentName;

  AiAssistantNotifier({
    required AiAssistantRepository repository,
    required String residentName,
  })  : _repository = repository,
        _residentName = residentName,
        super(const AiAssistantState()) {
    _initWelcome();
  }

  void _initWelcome() {
    state = state.copyWith(
      messages: [
        AiMessage(
          id: 'welcome_1',
          sender: MessageSender.assistant,
          content: 'Hello! I am your Kubo Care Companion. How can I support you and $_residentName today?',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> sendMessage(String text, {String? contextScreen}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isGenerating) return;

    final userMsg = AiMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      content: trimmed,
      timestamp: DateTime.now(),
      contextScreen: contextScreen,
    );

    final assistantMsgId = 'reply_${DateTime.now().millisecondsSinceEpoch}';
    final initialAssistantMsg = AiMessage(
      id: assistantMsgId,
      sender: MessageSender.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
      contextScreen: contextScreen,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, initialAssistantMsg],
      isGenerating: true,
    );

    try {
      final buffer = StringBuffer();
      final stream = _repository.streamResponse(
        trimmed,
        residentContext: _residentName,
        screenContext: contextScreen,
      );

      await for (final chunk in stream) {
        buffer.write(chunk);
        final currentContent = buffer.toString();

        final updatedList = state.messages.map((m) {
          if (m.id == assistantMsgId) {
            return m.copyWith(content: currentContent);
          }
          return m;
        }).toList();

        state = state.copyWith(messages: updatedList);
      }

      // Finish streaming
      final finalList = state.messages.map((m) {
        if (m.id == assistantMsgId) {
          return m.copyWith(isStreaming: false);
        }
        return m;
      }).toList();

      state = state.copyWith(messages: finalList, isGenerating: false);
    } catch (e) {
      final errorList = state.messages.map((m) {
        if (m.id == assistantMsgId) {
          return m.copyWith(
            content: 'I apologize, but I encountered an issue. In Montessori care, focusing on calm presence and comfort is always the best path.',
            isStreaming: false,
          );
        }
        return m;
      }).toList();
      state = state.copyWith(messages: errorList, isGenerating: false);
    }
  }

  void clearHistory() {
    _initWelcome();
  }
}

final aiAssistantProvider = StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  final repo = ref.watch(aiAssistantRepositoryProvider);
  final resident = ref.watch(residentProvider);
  return AiAssistantNotifier(repository: repo, residentName: resident.fullName);
});
