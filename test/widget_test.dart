import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/app_user.dart';

void main() {
  test('AppUser.fullName combines first and last name', () {
    const user = AppUser(
      id: '1',
      nombre: 'Ana',
      apellido: 'Perez',
      email: 'ana@example.com',
      telefono: '',
      direccion: '',
      distrito: '',
      numeroCasa: '',
      token: 'token',
    );

    expect(user.fullName, 'Ana Perez');
  });

  test('AppUser.fullName falls back to Cliente when empty', () {
    const user = AppUser(
      id: '1',
      nombre: '',
      apellido: '',
      email: 'cliente@example.com',
      telefono: '',
      direccion: '',
      distrito: '',
      numeroCasa: '',
      token: 'token',
    );

    expect(user.fullName, 'Cliente');
  });
}
