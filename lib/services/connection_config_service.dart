import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class ConnectionConfigService {
  static const _apiBaseUrlKey = 'apiBaseUrlOverride';

  Future<String> apiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _normalize(prefs.getString(_apiBaseUrlKey) ?? '');
    return saved ?? AppConfig.apiBaseUrl;
  }

  Future<String> hostLabel() async {
    final baseUrl = await apiBaseUrl();
    return labelFromApiBaseUrl(baseUrl);
  }

  Future<bool> isOfficial() async {
    final baseUrl = await apiBaseUrl();
    return baseUrl == AppConfig.apiBaseUrl;
  }

  Future<void> save(String value) async {
    final normalized = _normalize(value);
    if (normalized == null) {
      throw Exception('Ingresa una URL válida.');
    }

    final prefs = await SharedPreferences.getInstance();
    if (normalized == AppConfig.apiBaseUrl) {
      await prefs.remove(_apiBaseUrlKey);
      return;
    }
    await prefs.setString(_apiBaseUrlKey, normalized);
  }

  Future<void> restoreOfficial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiBaseUrlKey);
  }

  static String labelFromApiBaseUrl(String apiBaseUrl) {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || uri.host.isEmpty) return AppConfig.apiHostLabel;
    return uri.host;
  }

  static String? _normalize(String value) {
    var text = value.trim();
    if (text.isEmpty) return null;

    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      text = 'https://$text';
    }

    var uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;

    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    if (!path.endsWith('/api')) {
      uri = uri.replace(path: path.isEmpty ? '/api' : '$path/api');
    } else {
      uri = uri.replace(path: path);
    }

    return uri.toString().replaceAll(RegExp(r'/+$'), '');
  }
}
