import 'package:flutter/material.dart';

import '../services/contact_service.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _asunto = TextEditingController();
  final _mensaje = TextEditingController();
  final _service = ContactService();
  bool _loading = false;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _asunto.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.send(
        nombre: _nombre.text.trim(),
        email: _email.text.trim(),
        asunto: _asunto.text.trim(),
        mensaje: _mensaje.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje enviado correctamente.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Administrador',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6),
                    Text('Telefono / WhatsApp: 974268690'),
                    Text('Direccion: Jr. Parra del Riego 2 do piso'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _field(_nombre, 'Nombre'),
            _field(_email, 'Correo', email: true),
            _field(_asunto, 'Asunto'),
            _field(_mensaje, 'Mensaje', lines: 5),
            ElevatedButton(
              onPressed: _loading ? null : _send,
              child: Text(_loading ? 'Enviando...' : 'Enviar mensaje'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    bool email = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: email ? TextInputType.emailAddress : null,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Completa $label';
          if (email && !text.contains('@')) return 'Correo no válido';
          return null;
        },
      ),
    );
  }
}
