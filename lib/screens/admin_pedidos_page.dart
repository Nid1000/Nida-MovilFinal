import 'package:flutter/material.dart';

class AdminPedidosPage extends StatelessWidget {
  const AdminPedidosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.receipt),
            title: Text('Pedido #001'),
            subtitle: Text('Pendiente'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          ListTile(
            leading: Icon(Icons.receipt),
            title: Text('Pedido #002'),
            subtitle: Text('Entregado'),
          ),
        ],
      ),
    );
  }
}
