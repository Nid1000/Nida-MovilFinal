import 'package:flutter/material.dart';

class AdminReportesPage extends StatelessWidget {
  const AdminReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Reporte de ventas'),
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Reporte de pedidos'),
          ),
        ],
      ),
    );
  }
}
