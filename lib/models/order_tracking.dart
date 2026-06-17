class OrderTracking {
  final String id;
  final String codigo;
  final String estado;
  final String estadoDetalle;
  final String cliente;
  final String direccion;
  final String distrito;
  final String metodoPago;
  final double total;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final List<OrderTrackingTimelineItem> timeline;

  const OrderTracking({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.estadoDetalle,
    required this.cliente,
    required this.direccion,
    required this.distrito,
    required this.metodoPago,
    required this.total,
    required this.creadoEn,
    required this.actualizadoEn,
    required this.timeline,
  });

  factory OrderTracking.fromApi(Map<String, dynamic> raw) {
    final payload = (raw['pedido'] is Map<String, dynamic>)
        ? raw['pedido'] as Map<String, dynamic>
        : raw;

    final dynamic timelineRaw =
        payload['timeline'] ??
        payload['seguimiento'] ??
        payload['historialEstados'] ??
        [];
    final timeline = <OrderTrackingTimelineItem>[];
    if (timelineRaw is List) {
      for (final item in timelineRaw) {
        if (item is Map<String, dynamic>) {
          timeline.add(OrderTrackingTimelineItem.fromApi(item));
        }
      }
    }

    final estado =
        (payload['estado'] ??
                payload['status'] ??
                payload['orderStatus'] ??
                'pendiente')
            .toString();

    return OrderTracking(
      id: (payload['id'] ?? payload['_id'] ?? raw['id'] ?? '').toString(),
      codigo:
          (payload['codigo'] ??
                  payload['numeroPedido'] ??
                  payload['correlativo'] ??
                  payload['id'] ??
                  '')
              .toString(),
      estado: estado,
      estadoDetalle:
          (payload['estado_detalle'] ??
                  payload['statusLabel'] ??
                  payload['descripcionEstado'] ??
                  estado)
              .toString(),
      cliente:
          (payload['cliente_nombre'] ??
                  payload['cliente'] ??
                  payload['nombreCliente'] ??
                  '')
              .toString(),
      direccion: (payload['direccion'] ?? payload['direccion_entrega'] ?? '')
          .toString(),
      distrito: (payload['distrito'] ?? payload['distrito_entrega'] ?? '')
          .toString(),
      metodoPago: (payload['metodoPago'] ?? payload['metodo_pago'] ?? '')
          .toString(),
      total: _toDouble(payload['total']),
      creadoEn: _toDate(
        payload['createdAt'] ?? payload['creado_en'] ?? payload['fecha'],
      ),
      actualizadoEn: _toDate(
        payload['updatedAt'] ??
            payload['actualizado_en'] ??
            payload['fechaActualizacion'],
      ),
      timeline: timeline.isEmpty ? _defaultTimeline(estado) : timeline,
    );
  }

  static List<OrderTrackingTimelineItem> _defaultTimeline(String estado) {
    final normalized = estado.toLowerCase();
    final enCamino =
        normalized.contains('camino') ||
        normalized.contains('ruta') ||
        normalized.contains('delivery') ||
        normalized.contains('entreg');
    final entregado = normalized.contains('entreg');

    return [
      const OrderTrackingTimelineItem(
        label: 'Pedido recibido',
        estado: 'completado',
        fecha: null,
      ),
      OrderTrackingTimelineItem(
        label: 'En preparación',
        estado: enCamino || !entregado ? 'completado' : 'pendiente',
        fecha: null,
      ),
      OrderTrackingTimelineItem(
        label: 'En camino',
        estado: enCamino ? 'completado' : 'pendiente',
        fecha: null,
      ),
      OrderTrackingTimelineItem(
        label: 'Entregado',
        estado: entregado ? 'completado' : 'pendiente',
        fecha: null,
      ),
    ];
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class OrderTrackingTimelineItem {
  final String label;
  final String estado;
  final DateTime? fecha;

  const OrderTrackingTimelineItem({
    required this.label,
    required this.estado,
    required this.fecha,
  });

  factory OrderTrackingTimelineItem.fromApi(Map<String, dynamic> raw) {
    return OrderTrackingTimelineItem(
      label: (raw['label'] ?? raw['titulo'] ?? raw['estado'] ?? '').toString(),
      estado: (raw['status'] ?? raw['estado'] ?? 'pendiente').toString(),
      fecha: DateTime.tryParse(
        (raw['fecha'] ?? raw['createdAt'] ?? '').toString(),
      ),
    );
  }
}
