import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/repositories/mock_ai_assistant_repository.dart';

void main() {
  group('AI Assistant Unit Tests', () {
    late MockAiAssistantRepository repository;

    setUp(() {
      repository = MockAiAssistantRepository();
    });

    test('Returns curated guidance for visiting loved ones', () async {
      final response = await repository.getResponse('What should I bring on my visit?');
      expect(response, contains('Familiar Sensory Anchors'));
      expect(response, contains('Dignity Tip'));
    });

    test('Returns Montessori guidance for sundowning and agitation', () async {
      final response = await repository.getResponse('How to soothe agitation during sundowning?');
      expect(response, contains('sundowning'));
      expect(response, contains('Ambient Lighting'));
      expect(response, contains('Purposeful Muscle Memory'));
    });

    test('Returns nutrition and meal encouragement tips', () async {
      final response = await repository.getResponse('How can I help with poor meal intake?');
      expect(response, contains('Dignity-first mealtime guidance'));
      expect(response, contains('Visual Contrast'));
    });

    test('Returns resident personalized preferences for Margaret', () async {
      final response = await repository.getResponse('What does Margaret enjoy most?');
      expect(response, contains('Gardening'));
      expect(response, contains('yellow roses'));
    });

    test('Streaming yields progressive text chunks', () async {
      final stream = repository.streamResponse('What to bring on visits?');
      final chunks = <String>[];

      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      expect(chunks, isNotEmpty);
      final combined = chunks.join();
      expect(combined, contains('Familiar Sensory Anchors'));
    });
  });
}
