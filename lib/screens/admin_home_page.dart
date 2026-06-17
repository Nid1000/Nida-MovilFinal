import 'package:flutter/material.dart';
import 'login_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_productos_page.dart';
import 'admin_pedidos_page.dart';
import 'admin_clientes_page.dart';
import 'admin_reportes_page.dart';
import 'admin_config_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        children: [
          _card(
            context,
            'Dashboard',
            Icons.dashboard,
            const AdminDashboardPage(),
          ),
          _card(
            context,
            'Productos',
            Icons.inventory,
            const AdminProductosPage(),
          ),
          _card(
            context,
            'Pedidos',
            Icons.shopping_cart,
            const AdminPedidosPage(),
          ),
          _card(context, 'Clientes', Icons.people, const AdminClientesPage()),
          _card(
            context,
            'Reportes',
            Icons.bar_chart,
            const AdminReportesPage(),
          ),
          _card(
            context,
            'Configuración',
            Icons.settings,
            const AdminConfigPage(),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext c, String t, IconData i, Widget p) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => p)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, size: 40, color: Colors.orange),
            const SizedBox(height: 10),
            Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
