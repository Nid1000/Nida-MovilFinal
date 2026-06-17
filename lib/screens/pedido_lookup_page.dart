import 'package:flutter/material.dart';
import '../services/order_tracking_service.dart';
import '../theme/app_colors.dart';
import 'seguimiento_page.dart';

class PedidoLookupPage extends StatefulWidget {
  const PedidoLookupPage({super.key});

  @override
  State<PedidoLookupPage> createState() => _PedidoLookupPageState();
}

class _PedidoLookupPageState extends State<PedidoLookupPage> {
  final _controller = TextEditingController();
  final _service = OrderTrackingService();
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _service.getMyOrders(limit: 10);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openTracking(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeguimientoPage(orderId: trimmed)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Buscar pedido',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa el ID del pedido o usa la lista de tus pedidos recientes de la panadería.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Pedido',
              hintText: 'Ejemplo: 25 o B001-B001-00000025',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openTracking(_controller.text),
              icon: const Icon(Icons.search),
              label: const Text('Ver seguimiento'),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Mis pedidos recientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_orders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'No hay pedidos recientes disponibles todavia en tu cuenta.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            ..._orders.map(_orderCard),
        ],
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final id = (order['id'] ?? '').toString();
    final estado = (order['estado'] ?? 'pendiente').toString();
    final total = ((order['total'] as num?) ?? 0).toDouble();
    final createdAt = (order['created_at'] ?? order['fecha_pedido'] ?? '')
        .toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido #$id',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estado: ${estado.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Text(
                    createdAt,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _openTracking(id),
                child: const Text('Abrir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
