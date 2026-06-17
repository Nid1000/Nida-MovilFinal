import 'package:dio/dio.dart';
import '../models/digi_model.dart';
import '../utils/dio_cliente.dart';

class DigiService {
  final Dio _dio = DioClient.dio;
  static int page = 0;

  Future<List<DigiModel>> getDigimons() async {
    try {
      final response = await _dio.get('/digimon?page=$page');

      if (response.data == null || response.data['content'] == null) {
        return [];
      }

      page++;

      final List data = response.data['content'];
      return data.map((e) => DigiModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar Digimons');
    }
  }
}
