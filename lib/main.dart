import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/local_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_page.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delicias del centro',
      theme: AppTheme.light(),
      home: const BootstrapPage(),
    );
  }
}

class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key});

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await LocalNotificationService.instance.init().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      // Las notificaciones no deben impedir que la app cargue.
    }

    final user = await AuthService().restoreSession();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            user != null ? AppShell(userName: user.fullName) : LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(
                image: AssetImage('assets/logos/delicias.png'),
                width: 56,
                height: 56,
              ),
              SizedBox(height: 14),
              Text(
                'Delicias',
                style: TextStyle(
                  color: Color(0xFF0C4FB6),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 22),
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 14),
              Text('Conectando con api.saborcentral.com...'),
            ],
          ),
        ),
      ),
    );
  }
}
