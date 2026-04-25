import '../../core/network/api_client.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class CareGuideService {
  final ApiClient apiClient;

  CareGuideService({required this.apiClient});

  Future<String> askCareGuide(String prompt, String residentContext) async {
    try {
      // Mock MCP / AI response for now
      // In a real implementation, this would call an LLM via the MCP server
      await Future.delayed(const Duration(seconds: 2));
      
      if (prompt.toLowerCase().contains('montessori')) {
        return "In Montessori senior care, focus on 'meaningful work' that aligns with the resident's past interests. For $residentContext, consider activities like organizing familiar objects or participating in light domestic tasks to foster a sense of purpose.";
      }
      
      return "Based on $residentContext's profile, they respond well to tactile stimulation. I recommend the 'Memory Box' activity to encourage reminiscence and engagement.";
    } catch (e) {
      return "I'm sorry, I'm having trouble connecting to the CareGuide service right now. Please try again later.";
    }
  }
}
