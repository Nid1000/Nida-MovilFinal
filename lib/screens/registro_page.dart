import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_shell.dart';
import '../widgets/google_sign_in_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const List<String> _distritosHuancayo = [
    'Huancayo',
    'Carhuacallanga',
    'Chacapampa',
    'Chicche',
    'Chilca',
    'Chongos Alto',
    'Chupuro',
    'Colca',
    'Cullhuas',
    'El Tambo',
    'Huacrapuquio',
    'Hualhuas',
    'Huancán',
    'Huasicancha',
    'Huayucachi',
    'Ingenio',
    'Pariahuanca',
    'Pilcomayo',
    'Pucará',
    'Quichuay',
    'Quilcas',
    'San Agustín',
    'San Jerónimo de Tunán',
    'Santo Domingo de Acobamba',
    'Sapallanga',
    'Sicaya',
    'Viques',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _numeroCasa = TextEditingController();
  final _email = TextEditingController();
  final _verificationCode = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  final _auth = AuthService();
  final _google = GoogleAuthService();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;
  bool _loading = false;
  bool _sendingCode = false;
  bool _verifyingCode = false;
  bool _googleReady = false;
  bool _emailVerified = false;
  String _challenge = '';
  String _emailVerificationToken = '';
  String _verifiedEmail = '';
  String? _distritoSeleccionado;

  @override
  void initState() {
    super.initState();
    _email.addListener(_resetVerificationWhenEmailChanges);
    _initializeGoogle();
  }

  void _resetVerificationWhenEmailChanges() {
    if (_email.text.trim().toLowerCase() == _verifiedEmail) return;
    if (!_emailVerified && _emailVerificationToken.isEmpty) return;
    setState(() {
      _emailVerified = false;
      _emailVerificationToken = '';
      _verifiedEmail = '';
    });
  }

  Future<void> _initializeGoogle() async {
    try {
      await _google.initialize();
      if (_google.usesExternalWebFlow) {
        if (mounted) setState(() => _googleReady = true);
        return;
      }
      _googleSubscription = _google.events.listen(_handleGoogleEvent);
      if (mounted) setState(() => _googleReady = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _googleReady = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _show(
          error.toString().replaceFirst(
            'Exception: ',
            'No se pudo preparar Google: ',
          ),
        );
      });
    }
  }

  Future<void> _handleGoogleEvent(GoogleSignInAuthenticationEvent event) async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    final idToken = event.user.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      _show('Google no devolvió una credencial válida.');
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await _auth.verifyGoogleRegistration(idToken);
      final profile = data['profile'] is Map
          ? Map<String, dynamic>.from(data['profile'] as Map)
          : <String, dynamic>{};
      final email = (profile['email'] ?? event.user.email)
          .toString()
          .trim()
          .toLowerCase();
      setState(() {
        if (_nombre.text.trim().isEmpty) {
          _nombre.text = (profile['nombre'] ?? '').toString();
        }
        if (_apellido.text.trim().isEmpty) {
          _apellido.text = (profile['apellido'] ?? '').toString();
        }
        _email.text = email;
        _verifiedEmail = email;
        _emailVerificationToken = (data['verification_token'] ?? '').toString();
        _emailVerified = _emailVerificationToken.isNotEmpty;
      });
      _show('Correo validado con Google.');
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _show('Ingresa un correo válido.');
      return;
    }
    setState(() => _sendingCode = true);
    try {
      final challenge = await _auth.sendRegistrationCode(email);
      setState(() {
        _challenge = challenge;
        _emailVerified = false;
        _emailVerificationToken = '';
      });
      _show('Te enviamos un código de 6 dígitos.');
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_challenge.isEmpty) {
      _show('Primero envía el código.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(_verificationCode.text.trim())) {
      _show('Ingresa el código de 6 dígitos.');
      return;
    }
    setState(() => _verifyingCode = true);
    try {
      final email = _email.text.trim().toLowerCase();
      final token = await _auth.verifyRegistrationCode(
        email: email,
        code: _verificationCode.text.trim(),
        challenge: _challenge,
      );
      setState(() {
        _emailVerificationToken = token;
        _verifiedEmail = email;
        _emailVerified = token.isNotEmpty;
      });
      _show('Correo verificado correctamente.');
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _verifyingCode = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startGoogleSignIn() async {
    try {
      await _google.authenticate(registration: true);
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_emailVerified || _emailVerificationToken.isEmpty) {
      _show('Verifica tu correo antes de registrarte.');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _auth.register(
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        telefono: _telefono.text.trim(),
        direccion: _direccion.text.trim(),
        distrito: _distritoSeleccionado!.trim(),
        numeroCasa: _numeroCasa.text.trim(),
        email: _email.text.trim().toLowerCase(),
        password: _password.text.trim(),
        emailVerificationToken: _emailVerificationToken,
      );
      if (!mounted) return;
      _show('Cuenta creada correctamente.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AppShell(userName: user.fullName)),
        (_) => false,
      );
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _numeroCasa.dispose();
    _email.dispose();
    _verificationCode.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 620),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 26,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 34,
                      color: AppColors.accentDark,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea tu cuenta',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Valida tu correo con Google o con un código de 6 dígitos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (_googleReady)
                      GoogleSignInButton(
                        loading: _loading,
                        onPressed: _startGoogleSignIn,
                      )
                    else
                      const SizedBox(
                        height: 42,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _field(
                      _nombre,
                      'Nombre',
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Ingresa al menos 2 caracteres'
                          : null,
                    ),
                    _field(
                      _apellido,
                      'Apellido',
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Ingresa al menos 2 caracteres'
                          : null,
                    ),
                    _field(
                      _telefono,
                      'Teléfono',
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          !RegExp(r'^9\d{8}$').hasMatch(value?.trim() ?? '')
                          ? 'Ingresa un teléfono válido de 9 dígitos'
                          : null,
                    ),
                    _field(
                      _direccion,
                      'Dirección',
                      validator: (value) => (value?.trim().length ?? 0) < 5
                          ? 'Ingresa una dirección válida'
                          : null,
                    ),
                    _field(
                      _numeroCasa,
                      'Número de casa',
                      keyboardType: TextInputType.streetAddress,
                    ),
                    _districtField(),
                    _emailVerificationSection(),
                    _field(
                      _password,
                      'Contraseña',
                      obscure: true,
                      validator: (value) {
                        final text = value ?? '';
                        if (text.length < 6 ||
                            !RegExp(r'[a-z]').hasMatch(text) ||
                            !RegExp(r'[A-Z]').hasMatch(text) ||
                            !RegExp(r'\d').hasMatch(text)) {
                          return 'Usa 6 caracteres, una mayúscula, una minúscula y un número';
                        }
                        return null;
                      },
                    ),
                    _field(
                      _passwordConfirmation,
                      'Confirmar contraseña',
                      obscure: true,
                      validator: (value) => value != _password.text
                          ? 'Las contraseñas no coinciden'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading || !_emailVerified ? null : _submit,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Registrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _districtField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _distritoSeleccionado,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Distrito de Huancayo',
          border: OutlineInputBorder(),
        ),
        hint: const Text('Selecciona un distrito'),
        items: _distritosHuancayo
            .map(
              (distrito) => DropdownMenuItem<String>(
                value: distrito,
                child: Text(distrito, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() => _distritoSeleccionado = value);
        },
        validator: (value) => (value == null || value.trim().isEmpty)
            ? 'Selecciona un distrito'
            : null,
      ),
    );
  }

  Widget _emailVerificationSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;
        final emailField = Expanded(
          child: _field(
            _email,
            'Correo electrónico',
            readOnly: _emailVerified,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
        );
        final sendButton = Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SizedBox(
            width: compact ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: _sendingCode || _emailVerified ? null : _sendCode,
              icon: const Icon(Icons.mark_email_read_outlined, size: 18),
              label: Text(_sendingCode ? 'Enviando...' : 'Enviar código'),
            ),
          ),
        );

        return Column(
          children: [
            if (compact)
              Column(
                children: [
                  Row(children: [emailField]),
                  sendButton,
                  const SizedBox(height: 12),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [emailField, const SizedBox(width: 8), sendButton],
              ),

            if (_challenge.isNotEmpty && !_emailVerified)
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _verificationCode,
                      'Código de 6 dígitos',
                      validator: (_) => null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _verifyingCode ? null : _verifyCode,
                    child: Text(_verifyingCode ? 'Validando...' : 'Verificar'),
                  ),
                ],
              ),
            if (_emailVerified)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: AppColors.success),
                    SizedBox(width: 8),
                    Text(
                      'Correo verificado',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator:
            validator ??
            (value) => (value == null || value.trim().isEmpty)
                ? 'Completa $label'
                : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
