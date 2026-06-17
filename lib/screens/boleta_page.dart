import 'package:flutter/material.dart';
import 'direccion_page.dart';

class BoletaPage extends StatelessWidget {
  const BoletaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EACB),
      appBar: AppBar(
        title: const Text('Boleta'),
        backgroundColor: const Color(0xFFE8C27D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _item('Pan francés', 2, 1.0),
            _item('Torta', 1, 15.0),

            const Divider(height: 30),

            _total(17.0),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DireccionPage()),
                  );
                },
                child: const Text('CONFIRMAR COMPRA'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String nombre, int cant, double precio) {
    return ListTile(
      title: Text(nombre),
      subtitle: Text('Cantidad: $cant'),
      trailing: Text('S/ ${(cant * precio).toStringAsFixed(2)}'),
    );
  }

  Widget _total(double total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('TOTAL', style: TextStyle(fontSize: 18)),
        Text(
          'S/ ${total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
