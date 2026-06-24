import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'SessionService stores token securely and keeps app config on clear',
    () async {
      final service = SessionService();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('apiBaseUrlOverride', 'https://example.com/api');

      await service.saveUser(
        const AppUser(
          id: '1',
          nombre: 'Ana',
          apellido: 'Perez',
          email: 'ana@example.com',
          telefono: '987654321',
          direccion: 'Jr. Uno',
          distrito: 'Huancayo',
          numeroCasa: '123',
          token: 'secure-token',
        ),
      );

      expect(prefs.getString('token'), isNull);
      expect(await service.getToken(), 'secure-token');

      await service.clear();

      expect(await service.getUser(), isNull);
      expect(await service.getToken(), isEmpty);
      expect(prefs.getString('apiBaseUrlOverride'), 'https://example.com/api');
    },
  );
}
