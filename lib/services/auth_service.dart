import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import 'api_cliente.dart';
import 'api_endpoints.dart';
import 'session_service.dart';
import 'app_config.dart';

class AuthService {
  final Dio _api = ApiClient().dio;
  final SessionService _session = SessionService();

  Future<AppUser> login(String email, String password) async {
    try {
      final res = await _postFirstAvailable(
        ApiEndpoints.loginCandidates,
        data: {'email': email, 'password': password},
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('No se pudo iniciar sesión.');
      }

      final data = _normalize(res.data);
      final user = AppUser.fromApi(data);
      await _session.saveUser(user);
      return user;
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, fallback: 'No se pudo iniciar sesión.'));
    }
  }

  Future<void> checkServerConnection() async {
    try {
      final res = await _api
          .get(ApiEndpoints.health)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return;
    } catch (_) {
      // Some shared hostings treat browser-like requests differently. Try a
      // second lightweight request before reporting the API as offline.
    }

    try {
      final baseUrl = await ApiClient().currentBaseUrl();
      final res = await http
          .get(
            Uri.parse('$baseUrl${ApiEndpoints.health}'),
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'Mozilla/5.0 Delicias Mobile',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return;
      throw Exception(_serverUnavailableMessage);
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage);
    } catch (_) {
      throw Exception(_serverUnavailableMessage);
    }
  }

  Future<AppUser> register({
    required String nombre,
    required String apellido,
    required String telefono,
    required String direccion,
    required String distrito,
    String numeroCasa = '',
    required String email,
    required String password,
    required String emailVerificationToken,
  }) async {
    try {
      final res = await _postFirstAvailable(
        ApiEndpoints.registerCandidates,
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'telefono': telefono,
          'direccion': direccion,
          'distrito': distrito,
          'numero_casa': numeroCasa,
          'email': email,
          'password': password,
          'registration_channel': 'mobile',
          'email_verification_token': emailVerificationToken,
        },
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('No se pudo registrar el usuario.');
      }
      final user = AppUser.fromApi(_normalize(res.data));
      await _session.saveUser(user);
      return user;
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(e, fallback: 'No se pudo registrar el usuario.'),
      );
    }
  }

  Future<void> logout() => _session.clear();

  Future<AppUser> loginWithGoogle(String idToken) async {
    try {
      final res = await _api.post(
        ApiEndpoints.googleLogin,
        data: {'id_token': idToken},
      );
      final user = AppUser.fromApi(_normalize(res.data));
      await _session.saveUser(user);
      return user;
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(e, fallback: 'No se pudo iniciar sesión con Google.'),
      );
    }
  }

  Future<String> sendRegistrationCode(String email) async {
    try {
      final res = await _api.post(
        ApiEndpoints.sendRegistrationCode,
        data: {'email': email},
      );
      final data = _normalize(res.data);
      final challenge = (data['challenge'] ?? '').toString();
      if (challenge.isEmpty) {
        throw Exception('El servidor no devolvió el código de verificación.');
      }
      return challenge;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception(
          'La verificación por correo aún no está publicada en api.saborcentral.com.',
        );
      }
      throw Exception(
        _errorMessage(e, fallback: 'No se pudo enviar el código.'),
      );
    }
  }

  Future<String> verifyRegistrationCode({
    required String email,
    required String code,
    required String challenge,
  }) async {
    try {
      final res = await _api.post(
        ApiEndpoints.verifyRegistrationCode,
        data: {'email': email, 'code': code, 'challenge': challenge},
      );
      final data = _normalize(res.data);
      final token = (data['verification_token'] ?? '').toString();
      if (token.isEmpty) {
        throw Exception('El servidor no confirmó la verificación del correo.');
      }
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception(
          'La verificación por correo aún no está publicada en api.saborcentral.com.',
        );
      }
      throw Exception(
        _errorMessage(e, fallback: 'No se pudo verificar el código.'),
      );
    }
  }

  Future<Map<String, dynamic>> verifyGoogleRegistration(String idToken) async {
    try {
      final res = await _api.post(
        ApiEndpoints.verifyGoogleRegistration,
        data: {'id_token': idToken},
      );
      return _normalize(res.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, fallback: 'No se pudo validar Google.'));
    }
  }

  Future<Map<String, String>> requestPasswordReset(String email) async {
    try {
      final res = await _api.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      final data = _normalize(res.data);
      return {
        'message': (data['message'] ?? 'Revisa tu correo.').toString(),
        'challenge': (data['challenge'] ?? '').toString(),
      };
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(
          e,
          fallback: 'No se pudo enviar el correo de recuperación.',
        ),
      );
    }
  }

  Future<String> verifyPasswordResetCode({
    required String email,
    required String code,
    required String challenge,
  }) async {
    try {
      final res = await _api.post(
        ApiEndpoints.verifyPasswordResetCode,
        data: {'email': email, 'code': code, 'challenge': challenge},
      );
      final data = _normalize(res.data);
      final token = (data['reset_token'] ?? '').toString();
      if (token.isEmpty) {
        throw Exception('El servidor no confirmó el código de recuperación.');
      }
      return token;
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(e, fallback: 'No se pudo verificar el código.'),
      );
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _api.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': token,
          'password': password,
          'password_confirmation': password,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(e, fallback: 'No se pudo actualizar la contraseña.'),
      );
    }
  }

  Future<Map<String, dynamic>> fetchStats() async {
    final res = await _api.get(ApiEndpoints.profileStats);
    final data = _normalize(res.data);
    final stats = data['estadisticas'] ?? data['data'] ?? data;
    return stats is Map ? Map<String, dynamic>.from(stats) : {};
  }

  Future<AppUser?> restoreSession() async {
    final cached = await _session.getUser();
    if (cached == null || cached.token.isEmpty) {
      await _session.clear();
      return null;
    }

    try {
      final response = await _api
          .get(ApiEndpoints.verifySession)
          .timeout(const Duration(seconds: 6));
      final data = _normalize(response.data);
      final user = AppUser.fromApi({...data, 'token': cached.token});
      if (user.id.isEmpty || user.email.isEmpty) {
        await _session.clear();
        return null;
      }
      await _session.saveUser(user);
      return user;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        await _session.clear();
        return null;
      }
      return cached;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      await _api.put(
        ApiEndpoints.changePassword,
        data: {
          'passwordActual': currentPassword,
          'passwordNueva': newPassword,
          'confirmarPassword': confirmation,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(e, fallback: 'No se pudo cambiar la contraseña.'),
      );
    }
  }

  Future<AppUser> fetchProfile() async {
    try {
      final res = await _api.get(ApiEndpoints.me);
      if (res.statusCode != 200) {
        throw Exception('No se pudo cargar el perfil.');
      }

      final data = _normalize(res.data);
      final currentSession = await _session.getUser();
      final profile = AppUser.fromApi({
        ...data,
        'token': currentSession?.token ?? '',
      });
      await _session.saveUser(profile);
      return profile;
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(e, fallback: 'No se pudo cargar el perfil.'),
      );
    }
  }

  Future<AppUser> updateProfile({
    required String nombre,
    required String apellido,
    required String telefono,
    required String direccion,
    required String distrito,
    required String numeroCasa,
  }) async {
    try {
      final res = await _api.put(
        ApiEndpoints.me,
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'telefono': telefono,
          'direccion': direccion,
          'distrito': distrito,
          'numero_casa': numeroCasa,
        },
      );

      if (res.statusCode != 200) {
        throw Exception('No se pudo actualizar el perfil.');
      }

      final data = _normalize(res.data);
      final currentSession = await _session.getUser();
      final profile = AppUser.fromApi({
        ...data,
        'token': currentSession?.token ?? '',
      });
      await _session.saveUser(profile);
      return profile;
    } on DioException catch (e) {
      throw Exception(
        _errorMessage(e, fallback: 'No se pudo actualizar el perfil.'),
      );
    }
  }

  Map<String, dynamic> _normalize(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is String) return jsonDecode(body) as Map<String, dynamic>;
    return {};
  }

  Future<Response<dynamic>> _postFirstAvailable(
    List<String> paths, {
    required Map<String, dynamic> data,
  }) async {
    DioException? lastError;
    for (final path in paths) {
      try {
        return await _api.post(path, data: data);
      } on DioException catch (e) {
        lastError = e;
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode == 404 || statusCode == 405) {
          continue;
        }
        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    throw Exception('No se encontró una ruta compatible para conectar la app.');
  }

  String _errorMessage(DioException error, {required String fallback}) {
    final response = error.response?.data;
    if (response is Map<String, dynamic>) {
      final details = response['details'];
      if (details is Map) {
        for (final value in details.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first.toString().trim();
            if (first.isNotEmpty) return first;
          }
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
      final message =
          response['message'] ?? response['error'] ?? response['msg'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    if (response is String && response.trim().isNotEmpty) {
      return response.trim();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _serverUnavailableMessage;
      case DioExceptionType.connectionError:
        return _serverUnavailableMessage;
      default:
        return fallback;
    }
  }

  String get _serverUnavailableMessage =>
      'No pudimos conectar con ${AppConfig.apiHostLabel}. '
      'El servidor API no está aceptando conexiones en este momento.';
}
