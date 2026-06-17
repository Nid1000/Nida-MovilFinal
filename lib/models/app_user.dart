class AppUser {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String direccion;
  final String distrito;
  final String numeroCasa;
  final String token;

  const AppUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.direccion,
    required this.distrito,
    required this.numeroCasa,
    required this.token,
  });

  String get fullName {
    final value = '$nombre $apellido'.trim();
    return value.isEmpty ? 'Cliente' : value;
  }

  factory AppUser.fromApi(Map<String, dynamic> data) {
    final user = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : (data['usuario'] is Map<String, dynamic>)
        ? data['usuario'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AppUser(
      id: (user['id'] ?? data['id'] ?? '').toString(),
      nombre: (user['nombre'] ?? data['nombre'] ?? user['name'] ?? '')
          .toString(),
      apellido: (user['apellido'] ?? data['apellido'] ?? '').toString(),
      email: (user['email'] ?? data['email'] ?? '').toString(),
      telefono: (user['telefono'] ?? data['telefono'] ?? '').toString(),
      direccion: (user['direccion'] ?? data['direccion'] ?? '').toString(),
      distrito: (user['distrito'] ?? data['distrito'] ?? '').toString(),
      numeroCasa: (user['numero_casa'] ?? data['numero_casa'] ?? '').toString(),
      token: (data['token'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toPrefs() => {
    'userId': id,
    'nombre': nombre,
    'apellido': apellido,
    'userName': fullName,
    'userEmail': email,
    'telefono': telefono,
    'direccion': direccion,
    'distrito': distrito,
    'numeroCasa': numeroCasa,
    'token': token,
  };
}
