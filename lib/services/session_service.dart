import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_user.dart';

class SessionService {
  static const _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'token';
  static const _prefsKeys = [
    'userId',
    'nombre',
    'apellido',
    'userName',
    'userEmail',
    'telefono',
    'direccion',
    'distrito',
    'numeroCasa',
    'lastOrderId',
    'lastOrderStatus',
  ];

  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final data = user.toPrefs();
    for (final entry in data.entries) {
      if (entry.key == _tokenKey) continue;
      await prefs.setString(entry.key, entry.value.toString());
    }
    await _secureStorage.write(key: _tokenKey, value: user.token);
  }

  Future<AppUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? '';
    var token = await _secureStorage.read(key: _tokenKey) ?? '';
    final legacyToken = prefs.getString(_tokenKey) ?? '';
    if (token.isEmpty && legacyToken.isNotEmpty) {
      token = legacyToken;
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_tokenKey);
    }
    if (email.isEmpty && token.isEmpty) return null;

    return AppUser(
      id: prefs.getString('userId') ?? '',
      nombre: prefs.getString('nombre') ?? '',
      apellido: prefs.getString('apellido') ?? '',
      email: email,
      telefono: prefs.getString('telefono') ?? '',
      direccion: prefs.getString('direccion') ?? '',
      distrito: prefs.getString('distrito') ?? '',
      numeroCasa: prefs.getString('numeroCasa') ?? '',
      token: token,
    );
  }

  Future<String?> getLastOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastOrderId');
  }

  Future<void> setLastOrderId(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastOrderId', orderId);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _prefsKeys) {
      await prefs.remove(key);
    }
    await prefs.remove(_tokenKey);
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _secureStorage.read(key: _tokenKey) ?? '';
    if (token.isNotEmpty) return token;

    final legacyToken = prefs.getString(_tokenKey) ?? '';
    if (legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_tokenKey);
    }
    return legacyToken;
  }
}
