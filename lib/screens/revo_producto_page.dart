import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/delicias_appbar.dart';
import '../widgets/delicias_card.dart';
import '../widgets/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RevoProductoPage extends StatelessWidget {
  const RevoProductoPage({super.key});

  Future<String> _name() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? 'Cliente';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DeliciasAppBar(title: 'Revo Producto'),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _name(),
          builder: (context, snap) {
            final userName = snap.data ?? 'Cliente';
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    '¡GRACIAS POR TU COMPRA!',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'AQUI TIENES EL DETALLE DE TU BOLETA',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DeliciasCard(
                    child: Column(
                      children: [
                        Image.asset('assets/logos/delicias.png', height: 30),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Pedido entregado',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _row('Pan Integral', 'S/8.00'),
                        const SizedBox(height: 8),
                        _row('Pan Especial', 'S/8.00'),
                        const SizedBox(height: 14),
                        Row(
                          children: const [
                            Text(
                              'Total:',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Spacer(),
                            Text(
                              's/12.000',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6D7B3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text(
                        'Mapa (placeholder)',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppShell(userName: userName),
                        ),
                      ),
                      child: const Text('Seguir pidiendo'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _row(String a, String b) => Row(
    children: [
      Expanded(
        child: Text(a, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      Text(b, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}
