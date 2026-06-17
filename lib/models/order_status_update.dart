class OrderStatusUpdate {
  final String orderId;
  final String estado;
  final String? mensaje;

  const OrderStatusUpdate({
    required this.orderId,
    required this.estado,
    this.mensaje,
  });

  factory OrderStatusUpdate.fromMap(Map<String, dynamic> data) {
    return OrderStatusUpdate(
      orderId: (data['orderId'] ?? data['pedidoId'] ?? data['id'] ?? '')
          .toString(),
      estado: (data['estado'] ?? data['status'] ?? '').toString(),
      mensaje: data['mensaje']?.toString(),
    );
  }
}
