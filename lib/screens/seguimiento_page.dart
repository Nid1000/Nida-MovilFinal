import 'package:flutter/material.dart';

import '../models/order_status_update.dart';
import '../models/order_tracking.dart';
import '../services/order_tracking_service.dart';
import '../services/pusher_tracking_service.dart';
import '../theme/app_colors.dart';

class SeguimientoPage extends StatefulWidget {
  final String orderId;

  const SeguimientoPage({super.key, required this.orderId});

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage> {
  final OrderTrackingService _service = OrderTrackingService();
  final PusherTrackingService _pusher = PusherTrackingService();

  OrderTracking? _order;
  bool _loading = true;
  String? _socketInfo;
  String? _socketDebug;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final order = await _service.getOrderById(widget.orderId);
      if (!mounted) return;

      setState(() => _order = _normalizeOrder(order));
      await _pusher.connectToOrder(
        orderId: order.id.isNotEmpty ? order.id : widget.orderId,
        onUpdate: _handleSocketUpdate,
        onInfo: (message) {
          if (!mounted) return;
          setState(() => _socketDebug = message);
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _socketInfo = message;
            _socketDebug = 'Pusher: $message';
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos cargar el seguimiento del pedido.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSocketUpdate(OrderStatusUpdate update) async {
    if (update.orderId.isNotEmpty &&
        update.orderId != widget.orderId &&
        update.orderId != (_order?.id ?? '')) {
      return;
    }

    final currentOrder = _order;
    if (currentOrder != null) {
      setState(() {
        _order = _normalizeOrder(_applySocketUpdate(currentOrder, update));
        _socketInfo = update.mensaje ?? 'Pedido actualizado en tiempo real';
      });
    }

    try {
      final refreshed = await _service.getOrderById(widget.orderId);
      if (!mounted) return;
      setState(() => _order = _normalizeOrder(refreshed));
    } catch (_) {
      // Conservamos el cambio visual recibido por tiempo real.
    }
  }

  OrderTracking _normalizeOrder(OrderTracking order) {
    final timeline = order.timeline.isEmpty
        ? _buildTimeline(order.estado, order.creadoEn)
        : _normalizeTimeline(order.timeline, order.estado, order.creadoEn);

    return OrderTracking(
      id: order.id,
      codigo: order.codigo,
      estado: order.estado,
      estadoDetalle: _statusLabel(
        order.estadoDetalle.isEmpty ? order.estado : order.estadoDetalle,
      ),
      cliente: order.cliente,
      direccion: order.direccion,
      distrito: order.distrito,
      metodoPago: _paymentLabel(order.metodoPago),
      total: order.total,
      creadoEn: order.creadoEn,
      actualizadoEn: order.actualizadoEn,
      timeline: timeline,
    );
  }

  List<OrderTrackingTimelineItem> _normalizeTimeline(
    List<OrderTrackingTimelineItem> timeline,
    String estado,
    DateTime? createdAt,
  ) {
    if (timeline.length >= 4) return timeline;
    return _buildTimeline(estado, createdAt);
  }

  List<OrderTrackingTimelineItem> _buildTimeline(
    String estado,
    DateTime? createdAt,
  ) {
    final stage = _stageIndex(estado);
    final isCancelled = estado.toLowerCase().contains('cancel');
    final labels = [
      'Pedido recibido',
      'Preparación en cocina',
      'Listo para entrega',
      'Pedido completado',
    ];

    return List.generate(labels.length, (index) {
      final itemEstado = isCancelled
          ? (index == 0 ? 'completado' : 'cancelado')
          : (index <= stage ? 'completado' : 'pendiente');
      return OrderTrackingTimelineItem(
        label: labels[index],
        estado: itemEstado,
        fecha: index == 0 && createdAt != null ? createdAt : null,
      );
    });
  }

  int _stageIndex(String estado) {
    final normalized = estado.toLowerCase();
    if (normalized.contains('cancel')) return 0;
    if (normalized.contains('entreg')) return 3;
    if (normalized.contains('listo')) return 2;
    if (normalized.contains('prepar') || normalized.contains('confirm')) {
      return 1;
    }
    return 0;
  }

  String _statusLabel(String status) {
    final normalized = status.toLowerCase().trim();
    if (normalized.contains('cancel')) return 'Pedido cancelado';
    if (normalized.contains('entreg')) return 'Entregado';
    if (normalized.contains('listo')) return 'Listo para entrega';
    if (normalized.contains('prepar')) return 'En preparación';
    if (normalized.contains('confirm')) return 'Confirmado';
    if (normalized.contains('pend')) return 'Pedido recibido';
    return status.replaceAll('_', ' ').trim();
  }

  String _paymentLabel(String metodo) {
    final normalized = metodo.toLowerCase();
    if (normalized.contains('contra')) return 'Contra entrega';
    if (normalized.contains('cash')) return 'Pago en efectivo';
    if (normalized.contains('card') || normalized.contains('tarjeta')) {
      return 'Tarjeta registrada';
    }
    if (normalized.contains('yape')) return 'Yape';
    if (metodo.trim().isEmpty) return 'Pendiente de confirmación';
    return metodo;
  }

  OrderTracking _applySocketUpdate(
    OrderTracking order,
    OrderStatusUpdate update,
  ) {
    final nextEstado = update.estado.trim().isEmpty
        ? order.estado
        : update.estado;
    final nextDetalle = update.mensaje?.trim().isNotEmpty == true
        ? update.mensaje!.trim()
        : nextEstado;

    return OrderTracking(
      id: order.id,
      codigo: order.codigo,
      estado: nextEstado,
      estadoDetalle: nextDetalle,
      cliente: order.cliente,
      direccion: order.direccion,
      distrito: order.distrito,
      metodoPago: order.metodoPago,
      total: order.total,
      creadoEn: order.creadoEn,
      actualizadoEn: DateTime.now(),
      timeline: _buildTimeline(nextEstado, order.creadoEn),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Sin registrar';
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · $hour:$minute';
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('cancel')) return AppColors.danger;
    if (normalized.contains('entreg')) return AppColors.success;
    if (normalized.contains('listo')) return AppColors.info;
    if (normalized.contains('prepar')) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  void dispose() {
    _pusher.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Seguimiento del pedido'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
          ? const Center(child: Text('No se encontró el pedido.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _heroCard(order),
                  const SizedBox(height: 14),
                  _summaryGrid(order),
                  const SizedBox(height: 14),
                  _timelineSection(order),
                  if (_socketInfo != null) ...[
                    const SizedBox(height: 14),
                    _liveInfoCard(_socketInfo!),
                  ],
                  if (_socketDebug != null) ...[
                    const SizedBox(height: 14),
                    _debugCard(order),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _heroCard(OrderTracking order) {
    final color = _statusColor(order.estado);
    final stage = _stageIndex(order.estado) + 1;
    final progress = (stage / 4).clamp(0.25, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.74)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${order.codigo.isEmpty ? order.id : order.codigo}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.estadoDetalle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Actualizado: ${_formatDate(order.actualizadoEn ?? order.creadoEn)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid(OrderTracking order) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _InfoCard(
          title: 'Cliente',
          value: order.cliente.isEmpty ? 'Cliente Delicias' : order.cliente,
          icon: Icons.person_outline,
        ),
        _InfoCard(
          title: 'Entrega',
          value: order.direccion.isEmpty
              ? 'Dirección pendiente'
              : '${order.direccion}${order.distrito.isEmpty ? '' : '\n${order.distrito}'}',
          icon: Icons.location_on_outlined,
        ),
        _InfoCard(
          title: 'Pago',
          value: order.metodoPago,
          icon: Icons.payments_outlined,
        ),
        _InfoCard(
          title: 'Total',
          value: 'S/ ${order.total.toStringAsFixed(2)}',
          icon: Icons.sell_outlined,
        ),
      ],
    );
  }

  Widget _timelineSection(OrderTracking order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ruta de tu compra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Este flujo muestra el avance real que devuelve el backend y se actualiza cuando llega un evento nuevo.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ...order.timeline.asMap().entries.map(
            (entry) => _timelineItem(
              entry.value,
              isLast: entry.key == order.timeline.length - 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveInfoCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: AppColors.info,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _debugCard(OrderTracking order) {
    final orderId = order.id.isNotEmpty ? order.id : widget.orderId;
    final channelName = _pusher.subscribedChannel.isNotEmpty
        ? _pusher.subscribedChannel
        : 'pedido.$orderId';

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.bgSoft,
      collapsedBackgroundColor: AppColors.bgSoft,
      title: const Text(
        'Conexión en tiempo real',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: const Text('Detalle técnico de Pusher'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _DebugLine(label: 'Canal', value: channelName),
        _DebugLine(label: 'Evento', value: _pusher.expectedEvent),
        _DebugLine(label: 'Estado', value: _socketDebug ?? 'Sin novedades'),
      ],
    );
  }

  Widget _timelineItem(OrderTrackingTimelineItem item, {required bool isLast}) {
    final normalized = item.estado.toLowerCase();
    final isDone = normalized.contains('complet');
    final isCancelled = normalized.contains('cancel');
    final color = isCancelled
        ? AppColors.danger
        : isDone
        ? AppColors.success
        : AppColors.muted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCancelled
                    ? Icons.close_rounded
                    : isDone
                    ? Icons.check_rounded
                    : Icons.schedule_rounded,
                size: 18,
                color: color,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 34, color: AppColors.card2),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.fecha != null ? _formatDate(item.fecha) : 'Pendiente',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugLine extends StatelessWidget {
  final String label;
  final String value;

  const _DebugLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
