import 'package:flutter/material.dart';

class AdminProductosPage extends StatelessWidget {
  const AdminProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.cake),
            title: Text('Torta de Chocolate'),
            subtitle: Text('S/ 35.00'),
          ),
          ListTile(
            leading: Icon(Icons.bakery_dining),
            title: Text('Pan francés'),
            subtitle: Text('S/ 0.50'),
          ),
        ],
      ),
    );
  }
}
