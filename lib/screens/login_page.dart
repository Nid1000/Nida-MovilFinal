import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart' as google_auth;
import '../theme/app_colors.dart';
import '../theme/responsive.dart';
import '../widgets/app_shell.dart';
import '../widgets/google_sign_in_button.dart';
import 'forgot_password_page.dart';
import 'registro_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  final _google = google_auth.GoogleAuthService();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;

  bool _loading = false;
  bool _googleReady = false;
  bool _obscurePassword = true;
  bool _checkingApi = false;
  bool? _apiSynced;

  @override
  void initState() {
    super.initState();
    _initializeGoogle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncApi(showToast: false);
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
      final user = await _auth.loginWithGoogle(idToken);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AppShell(userName: user.fullName)),
      );
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startGoogleSignIn() async {
    try {
      await _google.authenticate();
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _enterAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AppShell(userName: 'Invitado', isGuest: true),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _show('Ingresa un correo electrónico válido.');
      return;
    }
    if (password.isEmpty) {
      _show('Completa el correo y la contraseña.');
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await _auth.login(email.toLowerCase(), password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AppShell(userName: user.fullName)),
      );
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _testConnection() async {
    await _syncApi();
  }

  Future<void> _syncApi({bool showToast = true}) async {
    if (_checkingApi) return;
    setState(() => _checkingApi = true);
    try {
      await _auth.checkServerConnection();
      if (!mounted) return;
      setState(() => _apiSynced = true);
      if (showToast) {
        _show('API sincronizada con api.saborcentral.com.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _apiSynced = false);
      if (showToast) {
        _show(
          'API no sincronizada. ${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _checkingApi = false);
    }
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE6E8EF))),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 18 : 24,
                    vertical: 24,
                  ),
                  child: ResponsiveContent(
                    padding: EdgeInsets.zero,
                    maxWidth: 420,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/logos/delicias.png',
                                width: 34,
                                height: 34,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Delicias',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0C4FB6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            compact ? 16 : 20,
                            18,
                            compact ? 16 : 20,
                            18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE7EAF2)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x120F172A),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Inicia sesión',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF23262F),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _loginField(
                                controller: _emailController,
                                hintText: 'Correo electrónico',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              _loginField(
                                controller: _passwordController,
                                hintText: 'Contraseña',
                                obscureText: _obscurePassword,
                                onSubmitted: (_) => _loading ? null : _login(),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: const Color(0xFF7A8090),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFB725),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: const Color(0x33FFB725),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size.fromHeight(48),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'INICIAR SESIÓN',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'o',
                                style: TextStyle(
                                  color: Color(0xFF8C92A3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_googleReady)
                                GoogleSignInButton(
                                  loading: _loading,
                                  onPressed: _startGoogleSignIn,
                                )
                              else
                                const SizedBox(
                                  height: 42,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              _secondaryButton(
                                icon: Icons.person_2_outlined,
                                label: 'Ingresar como invitado',
                                onTap: _loading ? null : _enterAsGuest,
                              ),
                              const SizedBox(height: 10),
                              _secondaryButton(
                                icon: Icons.lock_reset_outlined,
                                label: 'Olvidé mi contraseña',
                                onTap: _loading
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordPage(),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 10),
                              _secondaryButton(
                                icon: _apiSynced == true
                                    ? Icons.cloud_done_outlined
                                    : _apiSynced == false
                                    ? Icons.cloud_off_outlined
                                    : Icons.sync_outlined,
                                label: _checkingApi
                                    ? 'Sincronizando API...'
                                    : _apiSynced == true
                                    ? 'API sincronizada'
                                    : _apiSynced == false
                                    ? 'API no sincronizada'
                                    : 'Sincronizar API',
                                onTap: (_loading || _checkingApi)
                                    ? null
                                    : _testConnection,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: [
                                  const Text(
                                    '¿No tienes una cuenta?',
                                    style: TextStyle(
                                      color: Color(0xFF303544),
                                      fontSize: 13,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _loading
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => RegisterPage(),
                                              ),
                                            );
                                          },
                                    child: const Text(
                                      'Regístrate',
                                      style: TextStyle(
                                        color: Color(0xFF6B6EFF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Tu cuenta de cliente sigue conectada con compras, pedidos y seguimiento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: Color(0xFF737A8C), fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD9DEE8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF0C4FB6), width: 1.2),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    Widget? customLeading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF303544),
          side: const BorderSide(color: Color(0xFFD9DEE8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          children: [
            customLeading ??
                Icon(icon, size: 18, color: const Color(0xFF303544)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
