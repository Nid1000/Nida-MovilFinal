import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PedidoEntregadoPage extends StatefulWidget {
  final String orderId;
  const PedidoEntregadoPage({super.key, required this.orderId});

  @override
  State<PedidoEntregadoPage> createState() => _PedidoEntregadoPageState();
}

class _PedidoEntregadoPageState extends State<PedidoEntregadoPage> {
  int _stars = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping, size: 70, color: Colors.green),
              const SizedBox(height: 10),
              const Text(
                'Pedido entregado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pedido #${widget.orderId}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Califica tu experiencia ⭐',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => _stars = idx),
                    icon: Icon(
                      _stars >= idx ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gracias por calificar: $_stars ⭐'),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Finalizar',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
