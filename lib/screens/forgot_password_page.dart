import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _codeSent = false;
  bool _codeVerified = false;
  bool _obscurePassword = true;
  String _challenge = '';
  String _resetToken = '';

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
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

  bool _validPassword(String value) {
    return value.length >= 6 &&
        RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'\d').hasMatch(value);
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim().toLowerCase();
    if (!_validEmail(email)) {
      _show('Ingresa un correo válido.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _auth.requestPasswordReset(email);
      if (!mounted) return;
      final challenge = result['challenge'] ?? '';
      setState(() {
        _challenge = challenge;
        _codeSent = challenge.isNotEmpty;
        _codeVerified = false;
        _resetToken = '';
      });
      _show(result['message'] ?? 'Revisa tu correo.');
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_challenge.isEmpty) {
      _show('Primero solicita el código.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      _show('Ingresa el código de 6 dígitos.');
      return;
    }

    setState(() => _loading = true);
    try {
      final token = await _auth.verifyPasswordResetCode(
        email: _email.text.trim().toLowerCase(),
        code: _code.text.trim(),
        challenge: _challenge,
      );
      if (!mounted) return;
      setState(() {
        _resetToken = token;
        _codeVerified = token.isNotEmpty;
      });
      _show('Código verificado. Crea tu nueva contraseña.');
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_validPassword(_password.text)) {
      _show('Usa 6 caracteres, una mayúscula, una minúscula y un número.');
      return;
    }
    if (_password.text != _confirmation.text) {
      _show('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.resetPassword(token: _resetToken, password: _password.text);
      if (!mounted) return;
      _show('Contraseña actualizada correctamente.');
      Navigator.pop(context);
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    size: 42,
                    color: AppColors.accentDark,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Recupera tu cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Te enviaremos un código de 6 dígitos para validar tu identidad.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _email,
                    enabled: !_codeVerified,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loading || _codeVerified ? null : _sendCode,
                    icon: const Icon(Icons.mark_email_read_outlined),
                    label: Text(
                      _loading && !_codeSent
                          ? 'Enviando...'
                          : _codeSent
                          ? 'Reenviar código'
                          : 'Enviar código',
                    ),
                  ),
                  if (_codeSent && !_codeVerified) ...[
                    const SizedBox(height: 18),
                    TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Código de 6 dígitos',
                        prefixIcon: Icon(Icons.pin_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _verifyCode,
                      child: Text(_loading ? 'Verificando...' : 'Verificar'),
                    ),
                  ],
                  if (_codeVerified) ...[
                    const SizedBox(height: 18),
                    TextField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.password_outlined),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmation,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: Text(
                        _loading ? 'Actualizando...' : 'Guardar contraseña',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
