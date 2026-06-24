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
  static const adminPhone = '974268690';
  static const storeAddress = 'Jr. Parra del Riego 2 do piso';

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
    final localAnswer = _localAnswer(message);
    if (localAnswer != null) {
      return ChatbotReply(answer: localAnswer, source: 'local');
    }

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

  String? _localAnswer(String message) {
    final text = message.toLowerCase();
    final asksSupport = _containsAny(text, [
      'soporte',
      'ayuda',
      'reclamo',
      'problema',
      'queja',
      'administrador',
      'admin',
      'contacto',
      'telefono',
      'whatsapp',
      'numero',
    ]);
    final asksWork = _containsAny(text, [
      'trabajo',
      'trabajar',
      'empleo',
      'postular',
      'vacante',
      'cv',
      'curriculum',
      'contrat',
    ]);
    final asksAddress = _containsAny(text, [
      'direccion',
      'ubicacion',
      'ubicados',
      'local',
      'tienda',
      'donde estan',
    ]);

    if (asksWork) {
      return 'Para consultas de trabajo o postulaciones, escribe directamente al administrador al $adminPhone. Tambien puedes acercarte a $storeAddress.';
    }

    if (asksSupport) {
      return 'Para soporte, reclamos o ayuda personalizada, comunicate con el administrador al $adminPhone. Direccion: $storeAddress.';
    }

    if (asksAddress) {
      return 'Estamos ubicados en $storeAddress. Para confirmar atencion o referencias, comunicate con el administrador al $adminPhone.';
    }

    return null;
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}
