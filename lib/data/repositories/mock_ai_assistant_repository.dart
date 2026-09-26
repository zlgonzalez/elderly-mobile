import 'dart:async';
import '../../core/config/app_config.dart';
import 'ai_assistant_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: AiService - Mock Implementation
// Provides streaming elder-care AI responses with automatic offline fallback to curated Montessori guidance.
class MockAiAssistantRepository implements AiAssistantRepository {
  final String? _apiKey;

  MockAiAssistantRepository({String? apiKey}) : _apiKey = apiKey ?? AppConfig.fromEnvironment().geminiApiKey;

  String? get apiKey => _apiKey;

  @override
  Stream<String> streamResponse(
    String prompt, {
    String? residentContext,
    String? screenContext,
  }) async* {
    final fullAnswer = await getResponse(
      prompt,
      residentContext: residentContext,
      screenContext: screenContext,
    );

    // Yield words/phrases progressively to simulate real streaming
    final words = fullAnswer.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield '${words[i]}${i == words.length - 1 ? '' : ' '}';
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  @override
  Future<String> getResponse(
    String prompt, {
    String? residentContext,
    String? screenContext,
  }) async {
    // If live API key is set and not empty, could plug into live Gemini endpoint
    // In mock mode / offline fallback, provide curated, dignity-centered Montessori answers:
    return _generateCuratedResponse(prompt, residentContext: residentContext, screenContext: screenContext);
  }

  String _generateCuratedResponse(
    String prompt, {
    String? residentContext,
    String? screenContext,
  }) {
    final p = prompt.toLowerCase();

    if (p.contains('bring') || p.contains('visit')) {
      return 'Here are thoughtful items to bring for your visit:\n\n'
          '• **Familiar Sensory Anchors**: A soft knitted shawl or lavender-scented hand cream.\n'
          '• **Shared Memories**: 3 to 4 laminated photographs with clear faces, rather than a heavy album.\n'
          '• **Comforting Treats**: Small bite-sized lemon biscuits or peeled soft fruit slices.\n'
          '• **Music**: A downloaded playlist of 1950s swing or jazz.\n\n'
          '💡 *Dignity Tip*: Sit at eye level, match their conversational pace, and embrace quiet companionship.';
    }

    if (p.contains('agitation') || p.contains('sundown') || p.contains('anxious') || p.contains('restless')) {
      return 'Montessori approaches for evening restlessness (sundowning):\n\n'
          '1. **Ambient Lighting**: Draw curtains and turn on warm floor lamps before dusk settles.\n'
          '2. **Purposeful Muscle Memory**: Offer a basket of freshly warmed hand towels to fold side-by-side.\n'
          '3. **Aromatherapy**: Place a dried lavender sachet nearby or offer a warm rosemary hand massage.\n'
          '4. **Gentle Validation**: If she asks about going home, validate the feeling ("You want to feel safe and comfortable; I am here with you") rather than correcting the date or location.';
    }

    if (p.contains('meal') || p.contains('eat') || p.contains('food') || p.contains('intake') || p.contains('appetite')) {
      return 'Dignity-first mealtime guidance:\n\n'
          '• **Visual Contrast**: Serve light-colored foods (mashed sweet potatoes, poached eggs) on high-contrast tableware.\n'
          '• **Small Portions**: Offer small, unhurried servings to avoid overwhelming visual fatigue.\n'
          '• **Finger Foods**: If utensils feel challenging, present soft savory rolls, steamed carrot sticks, or fruit wedges.\n'
          '• **Hydration**: Offer small cups of water or infused chamomile throughout the day.';
    }

    if (p.contains('activity') || p.contains('calm') || p.contains('engage')) {
      return 'Recommended gentle engagement activities:\n\n'
          '• **Watercolour Blossom Washes**: Wax-resist floral painting where every stroke looks lovely.\n'
          '• **Seed Sorting Tray**: Sorting large white beans and sunflower seeds into wooden bowls.\n'
          '• **Lyric Completion**: Singing first bars of beloved songs together.\n\n'
          'Always honor their desire to stop whenever tired.';
    }

    if (p.contains('margaret') || p.contains('enjoy') || p.contains('likes') || p.contains('hobby')) {
      return 'Margaret finds deep peace and joy in:\n\n'
          '• **Gardening**: Talking about yellow roses and garden herbs.\n'
          '• **Music**: Classic swing jazz (Ella Fitzgerald, Glenn Miller).\n'
          '• **Baking Reminiscence**: The smell of warm cinnamon and lemon tea.\n'
          '• **Family**: Looking at photos of Sarah and hearing stories about grandchildren.';
    }

    // Default supportive elder-care response
    return 'Thank you for reaching out to Kubo AI. In Montessori dementia care, our guiding principle is always: '
        '"Help me to do it by myself." Focus on preserved capabilities, encourage autonomy, and celebrate each small moment of connection.';
  }
}
