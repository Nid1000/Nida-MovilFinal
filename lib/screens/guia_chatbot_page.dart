import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/delicias_appbar.dart';
import '../widgets/delicias_card.dart';

class GuiaChatbotPage extends StatelessWidget {
  const GuiaChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DeliciasAppBar(title: 'Guía chatbot'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: DeliciasCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guía completa de\ninformación con el chatbot',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _bubbleLeft(
                  'Estoy aquí para ayudarte. ¿Qué deseas consultar hoy?',
                ),
                const SizedBox(height: 10),
                _bubbleRight('Quiero ver los productos\ndisponibles'),
                const SizedBox(height: 10),
                _bubbleLeft(
                  'Puedes consultar:\n• Panes del día\n• Pasteles y tortas\n• Pedidos especiales\n• Horarios y ubicación',
                ),
                const SizedBox(height: 10),
                _bubbleRight('Quiero hacer un\npedido.'),
                const SizedBox(height: 10),
                _bubbleLeft(
                  'Nuestro horario de\natención es de\nlunes a domingo.',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB99BA0),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      'Con delivery.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black,
                    child: const Icon(Icons.chat, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _bubbleLeft(String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.smart_toy_outlined, color: AppColors.accent),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E9CF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ],
  );

  static Widget _bubbleRight(String text) => Row(
    children: [
      const Spacer(),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFD3B2B7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      const SizedBox(width: 10),
      const Icon(Icons.person, color: Colors.black),
    ],
  );
}
