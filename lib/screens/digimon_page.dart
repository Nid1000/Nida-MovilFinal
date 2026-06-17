import 'package:flutter/material.dart';
import '../services/digi_service.dart';
import '../models/digi_model.dart';

class DigimonPage extends StatefulWidget {
  const DigimonPage({super.key});

  @override
  State<DigimonPage> createState() => _DigimonPageState();
}

class _DigimonPageState extends State<DigimonPage> {
  final DigiService _service = DigiService();
  late Future<List<DigiModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getDigimons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digimons')),
      body: FutureBuilder<List<DigiModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos'));
          }

          final digimons = snapshot.data!;

          return ListView.builder(
            itemCount: digimons.length,
            itemBuilder: (context, index) {
              final d = digimons[index];
              return Card(
                child: ListTile(
                  leading: Image.network(d.image, width: 50),
                  title: Text(d.name),
                  subtitle: Text('ID: ${d.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
