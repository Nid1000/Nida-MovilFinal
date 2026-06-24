import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const List<String> _fallbackDistricts = [
    'Huancayo',
    'El Tambo',
    'Chilca',
    'Pilcomayo',
    'San Agustin de Cajas',
    'Sapallanga',
    'Sicaya',
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
  bool _loadingDistricts = true;
  bool _googleReady = false;
  bool _obscurePassword = true;
  bool _sendingCode = false;
  bool _verifyingCode = false;
  bool _emailVerified = false;
  String _verifiedEmail = '';
  String _emailVerificationToken = '';
  List<String> _districts = _fallbackDistricts;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
    _initializeGoogle();
  }

  Future<void> _loadDistricts() async {
    final districts = await _auth.fetchDistrictsHuancayo();
    if (!mounted) return;
    setState(() {
      if (districts.isNotEmpty) _districts = districts;
      _loadingDistricts = false;
    });
  }

  Future<void> _initializeGoogle() async {
    if (!_google.isSupported) {
      if (mounted) setState(() => _googleReady = true);
      return;
    }

    try {
      await _google.initialize();
      if (!_google.usesExternalWebFlow) {
        _googleSubscription = _google.events.listen(_handleGoogleEvent);
      }
      if (mounted) {
        setState(() {
          _googleReady = true;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _googleReady = true;
      });
    }
  }

  Future<void> _handleGoogleEvent(GoogleSignInAuthenticationEvent event) async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (event is! GoogleSignInAuthenticationEventSignIn) return;

    final email = event.user.email.trim().toLowerCase();
    if (email.isEmpty) {
      _show('Google no devolvio un correo valido.');
      return;
    }

    final displayName = event.user.displayName?.trim() ?? '';
    final parts = displayName.split(RegExp(r'\s+'));
    setState(() {
      _email.text = email;
      _verifiedEmail = email;
      _emailVerified = true;
      _emailVerificationToken = 'google';
      _verificationCode.clear();
      if (_nombre.text.trim().isEmpty && parts.isNotEmpty) {
        _nombre.text = parts.first;
      }
      if (_apellido.text.trim().isEmpty && parts.length > 1) {
        _apellido.text = parts.skip(1).join(' ');
      }
    });
    _show(
      'Correo validado con Google. Completa tus datos para crear la cuenta.',
    );
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
    final email = _email.text.trim().toLowerCase();
    if (!_emailVerified || _verifiedEmail != email) {
      _show('Verifica primero tu correo con Resend o continua con Google.');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _auth.register(
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        telefono: _telefono.text.trim(),
        direccion: _direccion.text.trim(),
        distrito: _selectedDistrict!.trim(),
        numeroCasa: _numeroCasa.text.trim(),
        email: email,
        password: _password.text,
        emailVerificationToken: _emailVerificationToken,
      );
      if (!mounted) return;
      _show('Cuenta creada correctamente.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AppShell(userName: user.fullName)),
        (_) => false,
      );
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  void _resetEmailVerification() {
    final email = _email.text.trim().toLowerCase();
    if (_emailVerified && email == _verifiedEmail) return;
    setState(() {
      _emailVerified = false;
      _verifiedEmail = '';
      _emailVerificationToken = '';
      _verificationCode.clear();
    });
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim().toLowerCase();
    if (!_validEmail(email)) {
      _show('Ingresa un correo valido.');
      return;
    }

    setState(() => _sendingCode = true);
    try {
      final message = await _auth.sendRegistrationCode(email);
      if (!mounted) return;
      setState(() {
        _emailVerified = false;
        _verifiedEmail = '';
        _emailVerificationToken = '';
      });
      _show(message);
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _email.text.trim().toLowerCase();
    final code = _verificationCode.text.trim();
    if (!_validEmail(email)) {
      _show('Ingresa un correo valido.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _show('Ingresa el codigo de 6 digitos.');
      return;
    }

    setState(() => _verifyingCode = true);
    try {
      final token = await _auth.verifyRegistrationCode(
        email: email,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        _emailVerified = true;
        _verifiedEmail = email;
        _emailVerificationToken = token;
      });
      _show('Correo verificado correctamente.');
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _verifyingCode = false);
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
                      'Usa los mismos datos que utilizaras en la web para que tus pedidos queden en una sola cuenta.',
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
                      'Telefono',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      validator: (value) =>
                          !RegExp(r'^9\d{8}$').hasMatch(value?.trim() ?? '')
                          ? 'Ingresa un telefono valido de 9 digitos'
                          : null,
                    ),
                    _field(
                      _direccion,
                      'Direccion',
                      validator: (value) => (value?.trim().length ?? 0) < 5
                          ? 'Ingresa una direccion valida'
                          : null,
                    ),
                    _field(
                      _numeroCasa,
                      'Numero de casa',
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Completa el numero de casa'
                          : null,
                    ),
                    _districtField(),
                    _field(
                      _email,
                      'Correo electronico',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _resetEmailVerification(),
                      suffixIcon: _emailVerified
                          ? const Icon(Icons.verified, color: AppColors.success)
                          : null,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (!_validEmail(text)) {
                          return 'Ingresa un correo valido';
                        }
                        return null;
                      },
                    ),
                    _EmailVerificationPanel(
                      controller: _verificationCode,
                      verified: _emailVerified,
                      sending: _sendingCode,
                      verifying: _verifyingCode,
                      onSend: _sendCode,
                      onVerify: _verifyCode,
                    ),
                    _field(
                      _password,
                      'Contrasena',
                      obscure: _obscurePassword,
                      suffixIcon: _passwordVisibilityButton(),
                      validator: (value) {
                        final text = value ?? '';
                        if (text.length < 6 ||
                            !RegExp(r'[a-z]').hasMatch(text) ||
                            !RegExp(r'[A-Z]').hasMatch(text) ||
                            !RegExp(r'\d').hasMatch(text)) {
                          return 'Usa 6 caracteres, una mayuscula, una minuscula y un numero';
                        }
                        return null;
                      },
                    ),
                    _field(
                      _passwordConfirmation,
                      'Confirmar contrasena',
                      obscure: _obscurePassword,
                      validator: (value) => value != _password.text
                          ? 'Las contrasenas no coinciden'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
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
        initialValue: _selectedDistrict,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: _loadingDistricts
              ? 'Cargando distritos...'
              : 'Distrito de Huancayo',
        ),
        hint: const Text('Selecciona un distrito'),
        items: _districts
            .map(
              (district) => DropdownMenuItem<String>(
                value: district,
                child: Text(district, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _loadingDistricts
            ? null
            : (value) {
                setState(() => _selectedDistrict = value);
              },
        validator: (value) => (value == null || value.trim().isEmpty)
            ? 'Selecciona un distrito'
            : null,
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        validator:
            validator ??
            (value) => (value == null || value.trim().isEmpty)
                ? 'Completa $label'
                : null,
        decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
      ),
    );
  }

  Widget _passwordVisibilityButton() {
    return IconButton(
      onPressed: () {
        setState(() => _obscurePassword = !_obscurePassword);
      },
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
      ),
    );
  }
}

class _EmailVerificationPanel extends StatelessWidget {
  const _EmailVerificationPanel({
    required this.controller,
    required this.verified,
    required this.sending,
    required this.verifying,
    required this.onSend,
    required this.onVerify,
  });

  final TextEditingController controller;
  final bool verified;
  final bool sending;
  final bool verifying;
  final VoidCallback onSend;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified : Icons.mark_email_read_outlined,
                color: verified ? AppColors.success : AppColors.accentDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verified
                      ? 'Correo verificado'
                      : 'Verifica tu correo con Resend',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (!verified) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: sending || verifying ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(sending ? 'Enviando...' : 'Enviar codigo'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Codigo de 6 digitos',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: sending || verifying ? null : onVerify,
                    child: verifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verificar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
