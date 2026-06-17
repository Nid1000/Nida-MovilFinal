import 'package:dio/dio.dart';

import 'api_cliente.dart';
import 'api_endpoints.dart';

class ChatbotReply {
  final String answer;
  final String source;

  const ChatbotReply({required this.answer, required this.source});

  bool get comesFromOllama => source == 'ollama';
}

class ChatbotStatus {
  final bool available;
  final bool ollamaEnabled;
  final String model;

  const ChatbotStatus({
    required this.available,
    required this.ollamaEnabled,
    required this.model,
  });
}

class ChatbotService {
  final Dio _api = ApiClient().dio;

  Future<ChatbotStatus> health() async {
    try {
      final response = await _api.get(
        ApiEndpoints.chatbotHealth,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final data = _asMap(response.data);
      return ChatbotStatus(
        available: data['ok'] == true,
        ollamaEnabled:
            data['ollamaEnabled'] == true && data['ollamaConnected'] == true,
        model: (data['ollamaModel'] ?? '').toString(),
      );
    } on DioException {
      return const ChatbotStatus(
        available: false,
        ollamaEnabled: false,
        model: '',
      );
    }
  }

  Future<ChatbotReply> ask({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.chatbotAsk,
        data: {'message': message, 'history': history},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      final data = _asMap(response.data);
      final answer = (data['answer'] ?? '').toString().trim();
      if (answer.isEmpty) {
        throw Exception('El chatbot no devolvió una respuesta.');
      }
      return ChatbotReply(
        answer: answer,
        source: (data['source'] ?? 'default').toString(),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw Exception(
          'El chatbot aún no está publicado en api.saborcentral.com.',
        );
      }
      final data = _asMap(error.response?.data);
      throw Exception(
        (data['message'] ?? 'No se pudo conectar con Valeria.').toString(),
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
