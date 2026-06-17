import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class SessionService {
  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final data = user.toPrefs();
    for (final entry in data.entries) {
      await prefs.setString(entry.key, entry.value.toString());
    }
  }

  Future<AppUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? '';
    final token = prefs.getString('token') ?? '';
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
    await prefs.clear();
  }
}
