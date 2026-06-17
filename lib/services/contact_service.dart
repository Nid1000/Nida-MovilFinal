import 'package:dio/dio.dart';

import 'api_cliente.dart';
import 'api_endpoints.dart';

class ContactService {
  final Dio _api = ApiClient().dio;

  Future<void> send({
    required String nombre,
    required String email,
    required String asunto,
    required String mensaje,
  }) async {
    await _api.post(
      ApiEndpoints.contact,
      data: {
        'nombre': nombre,
        'email': email,
        'mensaje': asunto.trim().isEmpty ? mensaje : '$asunto\n\n$mensaje',
      },
    );
  }
}
