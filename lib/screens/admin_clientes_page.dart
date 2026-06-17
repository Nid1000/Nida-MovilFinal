import 'package:flutter/material.dart';

class AdminClientesPage extends StatelessWidget {
  const AdminClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Juan Pérez'),
            subtitle: Text('juan@gmail.com'),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('María López'),
            subtitle: Text('maria@gmail.com'),
          ),
        ],
      ),
    );
  }
}
