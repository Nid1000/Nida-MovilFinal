import 'package:flutter/material.dart';
import 'boleta_page.dart';

class PasteleriaPage extends StatelessWidget {
  const PasteleriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pastelería')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _producto(
            context,
            'Torta de chocolate',
            'Clásica y deliciosa',
            15.00,
          ),
          _producto(context, 'Cupcake', 'Pequeño y dulce', 5.00),
          _producto(context, 'Pie de limón', 'Refrescante', 12.00),
        ],
      ),
    );
  }

  Widget _producto(BuildContext c, String nombre, String desc, double precio) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(desc),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('S/ ${precio.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  c,
                  MaterialPageRoute(builder: (_) => const BoletaPage()),
                );
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}
