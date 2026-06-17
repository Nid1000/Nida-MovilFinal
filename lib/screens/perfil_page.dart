import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/app_config.dart';
import '../services/auth_service.dart';
import '../services/connection_config_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';

class PerfilPage extends StatefulWidget {
  final bool isGuest;

  const PerfilPage({super.key, this.isGuest = false});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _auth = AuthService();
  final _session = SessionService();
  final _connection = ConnectionConfigService();
  late Future<AppUser?> _profileFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<_ConnectionInfo> _connectionFuture;
  bool _showConnection = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _statsFuture = widget.isGuest
        ? Future.value(<String, dynamic>{})
        : _auth.fetchStats().catchError((_) => <String, dynamic>{});
    _connectionFuture = _loadConnectionInfo();
  }

  Future<_ConnectionInfo> _loadConnectionInfo() async {
    final apiBaseUrl = await _connection.apiBaseUrl();
    final isOfficial = await _connection.isOfficial();
    return _ConnectionInfo(
      apiBaseUrl: apiBaseUrl,
      hostLabel: ConnectionConfigService.labelFromApiBaseUrl(apiBaseUrl),
      isOfficial: isOfficial,
    );
  }

  Future<AppUser?> _loadProfile() async {
    final cachedUser = await _session.getUser();
    if (cachedUser == null) return null;

    try {
      return await _auth.fetchProfile();
    } catch (_) {
      return cachedUser;
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshProfile() async {
    final future = _loadProfile();
    setState(() {
      _profileFuture = future;
      _statsFuture = _auth.fetchStats().catchError((_) => <String, dynamic>{});
    });
    await future;
  }

  Future<void> _openPasswordDialog() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePasswordDialog(auth: _auth),
    );
    if (changed == true) _show('Contraseña actualizada correctamente.');
  }

  Future<void> _openConnectionDialog(_ConnectionInfo info) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConnectionDialog(
        connection: _connection,
        initialValue: info.apiBaseUrl,
      ),
    );
    if (changed != true) return;

    setState(() => _connectionFuture = _loadConnectionInfo());
    _show('Conexión actualizada.');
  }

  Future<void> _restoreOfficialConnection() async {
    await _connection.restoreOfficial();
    setState(() => _connectionFuture = _loadConnectionInfo());
    _show('Servidor oficial restaurado.');
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  Future<void> _openEditDialog(AppUser user) async {
    final updated = await showDialog<AppUser>(
      context: context,
      builder: (_) => _EditProfileDialog(auth: _auth, user: user),
    );

    if (updated == null) return;
    _show(
      'Perfil actualizado. Los cambios ya se reflejan en la app de la panadería.',
    );
    setState(() => _profileFuture = Future.value(updated));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (widget.isGuest) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.55),
                      child: const Icon(
                        Icons.person_outline,
                        size: 30,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Modo invitado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Puedes explorar la tienda antes de iniciar sesión.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginPage(),
                                ),
                                (_) => false,
                              );
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Iniciar sesión'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _connectionCard(),
            ],
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('Sin datos de sesión.'));
        }

        return RefreshIndicator(
          onRefresh: _refreshProfile,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.55),
                      child: Text(
                        user.nombre.isNotEmpty
                            ? user.nombre[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openEditDialog(user),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar perfil'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _infoCard(
                title: 'Datos personales',
                items: [
                  _ProfileItem('Nombre', user.nombre),
                  _ProfileItem('Apellido', user.apellido),
                  _ProfileItem('Correo', user.email),
                  _ProfileItem('Teléfono', user.telefono),
                ],
              ),
              const SizedBox(height: 14),
              _infoCard(
                title: 'Dirección',
                items: [
                  _ProfileItem('Dirección', user.direccion),
                  _ProfileItem('Distrito', user.distrito),
                  _ProfileItem('N.° casa', user.numeroCasa),
                ],
              ),
              const SizedBox(height: 14),
              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, statsSnapshot) {
                  final stats = statsSnapshot.data ?? {};
                  final orders =
                      stats['total_pedidos'] ?? stats['pedidos'] ?? 0;
                  final spent = stats['total_gastado'] ?? stats['gastado'] ?? 0;
                  return _infoCard(
                    title: 'Resumen de compras',
                    items: [
                      _ProfileItem('Pedidos realizados', orders.toString()),
                      _ProfileItem('Total comprado', 'S/ $spent'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _openPasswordDialog,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Cambiar contraseña'),
              ),
              const SizedBox(height: 14),
              _connectionCard(),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard({required String title, required List<_ProfileItem> items}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                item.value.trim().isEmpty ? 'No registrado' : item.value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (item != items.last) const Divider(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _connectionCard() {
    return FutureBuilder<_ConnectionInfo>(
      future: _connectionFuture,
      builder: (context, snapshot) {
        final info = snapshot.data ??
            const _ConnectionInfo(
              apiBaseUrl: AppConfig.apiBaseUrl,
              hostLabel: AppConfig.apiHostLabel,
              isOfficial: true,
            );
        final label = _showConnection ? info.hostLabel : _maskedHost(info.hostLabel);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Conexión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _showConnection ? 'Ocultar conexión' : 'Ver conexión',
                    onPressed: () => setState(() => _showConnection = !_showConnection),
                    icon: Icon(
                      _showConnection
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info.isOfficial ? 'Servidor oficial' : 'Servidor personalizado',
                style: TextStyle(
                  color: info.isOfficial ? AppColors.success : AppColors.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openConnectionDialog(info),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Cambiar'),
                  ),
                  if (!info.isOfficial)
                    TextButton.icon(
                      onPressed: _restoreOfficialConnection,
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Usar oficial'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _maskedHost(String host) {
    if (host.length <= 8) return '••••••••';
    final first = host.substring(0, 3);
    final last = host.substring(host.length - 4);
    return '$first••••••$last';
  }
}

class _ConnectionInfo {
  final String apiBaseUrl;
  final String hostLabel;
  final bool isOfficial;

  const _ConnectionInfo({
    required this.apiBaseUrl,
    required this.hostLabel,
    required this.isOfficial,
  });
}

class _ConnectionDialog extends StatefulWidget {
  final ConnectionConfigService connection;
  final String initialValue;

  const _ConnectionDialog({
    required this.connection,
    required this.initialValue,
  });

  @override
  State<_ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<_ConnectionDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.connection.save(_controller.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _restoreOfficial() async {
    await widget.connection.restoreOfficial();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF7EE),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Cambiar conexión'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Por defecto la app usa api.saborcentral.com. Cambia esto solo si estás probando otro servidor.',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Servidor API',
                hintText: 'api.saborcentral.com',
                prefixIcon: Icon(Icons.cloud_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _restoreOfficial,
          child: const Text('Usar oficial'),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final AuthService auth;
  final AppUser user;

  const _EditProfileDialog({required this.auth, required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _telefono;
  late final TextEditingController _direccion;
  late final TextEditingController _distrito;
  late final TextEditingController _numeroCasa;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.user.nombre);
    _apellido = TextEditingController(text: widget.user.apellido);
    _telefono = TextEditingController(text: widget.user.telefono);
    _direccion = TextEditingController(text: widget.user.direccion);
    _distrito = TextEditingController(text: widget.user.distrito);
    _numeroCasa = TextEditingController(text: widget.user.numeroCasa);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _distrito.dispose();
    _numeroCasa.dispose();
    super.dispose();
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final updated = await widget.auth.updateProfile(
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        telefono: _telefono.text.trim(),
        direccion: _direccion.text.trim(),
        distrito: _distrito.text.trim(),
        numeroCasa: _numeroCasa.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF7EE),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Editar perfil'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  _nombre,
                  'Nombre',
                  minLength: 2,
                  icon: Icons.person_outline,
                ),
                _field(
                  _apellido,
                  'Apellido',
                  minLength: 2,
                  icon: Icons.badge_outlined,
                ),
                _field(
                  _telefono,
                  'Teléfono',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (!RegExp(r'^9\d{8}$').hasMatch(text)) {
                      return 'Ingresa un teléfono válido de 9 dígitos';
                    }
                    return null;
                  },
                ),
                _field(
                  _direccion,
                  'Dirección',
                  minLength: 5,
                  icon: Icons.location_on_outlined,
                ),
                _field(
                  _distrito,
                  'Distrito',
                  minLength: 2,
                  icon: Icons.map_outlined,
                ),
                _field(
                  _numeroCasa,
                  'N.° casa',
                  minLength: 1,
                  icon: Icons.home_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int minLength = 1,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator:
            validator ??
            (value) {
              final text = value?.trim() ?? '';
              if (text.length < minLength) {
                return 'Completa $label';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _ProfileItem {
  final String label;
  final String value;

  const _ProfileItem(this.label, this.value);
}

class _ChangePasswordDialog extends StatefulWidget {
  final AuthService auth;

  const _ChangePasswordDialog({required this.auth});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_current.text.isEmpty || _next.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nueva contraseña debe tener 8 caracteres.'),
        ),
      );
      return;
    }
    if (_next.text != _confirmation.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.auth.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
        confirmation: _confirmation.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF7EE),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Cambiar contraseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          TextField(
            controller: _next,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: Icon(Icons.password_outlined),
            ),
          ),
          TextField(
            controller: _confirmation,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
