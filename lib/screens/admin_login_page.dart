import 'package:flutter/material.dart';
import 'admin_home_page.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso Administrador')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            _input('Usuario'),
            const SizedBox(height: 12),
            _input('Contraseña', pass: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminHomePage()),
                  );
                },
                child: const Text('Ingresar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String t, {bool pass = false}) {
    return TextField(
      obscureText: pass,
      decoration: InputDecoration(
        labelText: t,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
