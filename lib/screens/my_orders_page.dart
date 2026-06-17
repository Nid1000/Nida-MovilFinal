import 'package:flutter/material.dart';

import '../services/order_tracking_service.dart';
import '../theme/app_colors.dart';
import 'seguimiento_page.dart';

class MyOrdersPage extends StatefulWidget {
  final VoidCallback? onGoHome;
  final VoidCallback? onGoStore;

  const MyOrdersPage({super.key, this.onGoHome, this.onGoStore});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final _service = OrderTrackingService();

  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await _service.getMyOrders(limit: 20);
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

  String _headerStatus() {
    if (_orders.isEmpty) return 'Sin compras registradas';
    return (_orders.first['estado'] ?? 'Pendiente').toString();
  }

  Future<void> _cancel(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text('Se cancelara el pedido #$id.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.cancelOrder(id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pedido cancelado.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE7C48A), Color(0xFFF2DEC2)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mis pedidos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Revisa el historial de compras registradas en Delicias y abre su seguimiento en tiempo real.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Total',
                        value: _loading ? '...' : '${_orders.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Último estado',
                        value: _loading ? '...' : _headerStatus(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            widget.onGoHome ??
                            () => Navigator.maybePop(context),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Inicio'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            widget.onGoStore ??
                            () => Navigator.maybePop(context),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Tienda'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_orders.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                'Todavía no tienes pedidos registrados en tu cuenta.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ..._orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCard(order: order, onCancel: _cancel),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final ValueChanged<String> onCancel;

  const _OrderCard({required this.order, required this.onCancel});

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final date = parsed.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final id = (order['id'] ?? '').toString();
    final estado = (order['estado'] ?? 'pendiente').toString();
    final total = ((order['total'] as num?) ?? 0).toDouble();
    final fecha = (order['created_at'] ?? order['fecha_pedido'] ?? '')
        .toString();
    final totalProductos = (order['total_productos'] ?? 0).toString();
    final normalizedStatus = estado.toLowerCase();
    final canCancel =
        !normalizedStatus.contains('entreg') &&
        !normalizedStatus.contains('cancel') &&
        !normalizedStatus.contains('listo');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pedido',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#$id',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: estado),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniTag(
                icon: Icons.calendar_today_outlined,
                label: fecha.isEmpty ? 'Sin fecha' : _formatDate(fecha),
              ),
              _MiniTag(
                icon: Icons.shopping_bag_outlined,
                label: '$totalProductos productos',
              ),
              _MiniTag(
                icon: Icons.sell_outlined,
                label: 'S/ ${total.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeguimientoPage(orderId: id),
                  ),
                );
              },
              icon: const Icon(Icons.route_outlined),
              label: const Text('Abrir seguimiento'),
            ),
          ),
          if (canCancel) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onCancel(id),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar pedido'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized.contains('cancel')
        ? AppColors.danger
        : normalized.contains('entreg')
        ? AppColors.success
        : normalized.contains('listo')
        ? AppColors.info
        : normalized.contains('prepar')
        ? AppColors.warning
        : AppColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
