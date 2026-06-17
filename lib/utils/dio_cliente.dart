import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/app_config.dart';
import '../services/connection_config_service.dart';

class DioClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              options.baseUrl = await ConnectionConfigService().apiBaseUrl();
              handler.next(options);
            },
          ),
        )
        ..interceptors.add(
          LogInterceptor(
            requestBody: false,
            responseBody: kDebugMode,
            error: kDebugMode,
            logPrint: (o) {
              if (kDebugMode) {
                // ignore: avoid_print
                print(o);
              }
            },
          ),
        );
}
