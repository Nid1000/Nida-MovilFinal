import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        children: const [
          _Item('Ventas del día', 'S/ 1,250', Icons.attach_money),
          _Item('Pedidos', '28', Icons.shopping_cart),
          _Item('Clientes', '15', Icons.people),
          _Item('Productos', '42', Icons.inventory),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String t, v;
  final IconData i;
  const _Item(this.t, this.v, this.i);

  @override
  Widget build(BuildContext c) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, size: 40, color: Colors.orange),
          const SizedBox(height: 8),
          Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(v),
        ],
      ),
    );
  }
}
