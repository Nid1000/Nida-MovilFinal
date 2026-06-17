import 'package:flutter/material.dart';
import '../widgets/delicias_appbar.dart';
import '../widgets/delicias_card.dart';

class DireccionPage extends StatefulWidget {
  const DireccionPage({super.key});

  @override
  State<DireccionPage> createState() => _DireccionPageState();
}

class _DireccionPageState extends State<DireccionPage> {
  final _dir = TextEditingController();

  @override
  void dispose() {
    _dir.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DeliciasAppBar(title: 'Dirección'),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const DeliciasCard(
              child: Text(
                'Agrega tu dirección para delivery.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dir,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
