import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';
import 'app_config.dart';
import 'connection_config_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 Delicias Mobile',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await _getPrefs();
          final saved = prefs.getString('apiBaseUrlOverride');
          options.baseUrl = saved?.trim().isNotEmpty == true
              ? saved!.trim()
              : AppConfig.apiBaseUrl;
          final token = prefs.getString('token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          log(
            'API ERROR => ${error.requestOptions.method} ${error.requestOptions.uri} :: ${error.message}',
          );
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  SharedPreferences? _prefs;
  final _connection = ConnectionConfigService();

  Dio get dio => _dio;

  Future<String> currentBaseUrl() => _connection.apiBaseUrl();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
