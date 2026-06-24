import 'package:dio/dio.dart';
import '../services/api_cliente.dart';

class DioClient {
  static Dio get dio => ApiClient().dio;
}
