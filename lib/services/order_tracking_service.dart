import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/order_tracking.dart';
import 'api_cliente.dart';
import 'api_endpoints.dart';
import 'session_service.dart';

class OrderTrackingService {
  final Dio _api = ApiClient().dio;
  final SessionService _session = SessionService();

  Future<List<Map<String, dynamic>>> getMyOrders({int limit = 10}) async {
    for (final path in ApiEndpoints.ordersCandidates) {
      try {
        final res = await _api.get(
          path,
          queryParameters: {
            'pagina': 1,
            'limite': limit,
            'limit': limit,
            'sort': 'desc',
          },
        );
        if (res.statusCode == 200) {
          return _normalizeOrdersList(res.data);
        }
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode != 404 && statusCode != 405) rethrow;
      }
    }
    return [];
  }

  Future<OrderTracking> getOrderById(String orderId) async {
    final resolvedReceiptOrderId = await _resolveOrderIdFromReceipt(orderId);

    final candidates = <String>{
      orderId.trim(),
      ?resolvedReceiptOrderId,
      ..._resolvePossibleOrderIds(orderId),
    };

    for (final candidate in candidates) {
      try {
        for (final path in ApiEndpoints.orderTrackingCandidates(candidate)) {
          try {
            final trackingRes = await _api.get(path);
            if (trackingRes.statusCode == 200) {
              final order = OrderTracking.fromApi(_normalize(trackingRes.data));
              await _session.setLastOrderId(
                order.id.isNotEmpty ? order.id : candidate,
              );
              return order;
            }
          } on DioException catch (e) {
            final statusCode = e.response?.statusCode ?? 0;
            if (statusCode != 404 && statusCode != 405) rethrow;
          }
        }
      } catch (_) {}

      for (final path in ApiEndpoints.orderByIdCandidates(candidate)) {
        try {
          final res = await _api.get(path);
          if (res.statusCode == 200) {
            final data = _normalize(res.data);
            final order = OrderTracking.fromApi(data);
            await _session.setLastOrderId(
              order.id.isNotEmpty ? order.id : candidate,
            );
            return order;
          }
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode ?? 0;
          if (statusCode != 404 && statusCode != 405) rethrow;
        }
      }
    }
    throw Exception('No pudimos cargar tu pedido en este momento.');
  }

  Future<OrderTracking?> findLatestOrderForCurrentUser() async {
    final orders = await getMyOrders(limit: 10);
    if (orders.isEmpty) return null;
    return OrderTracking.fromApi(orders.first);
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _api.put(ApiEndpoints.cancelOrder(orderId));
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message']?.toString() : null;
      throw Exception(message ?? 'No se pudo cancelar el pedido.');
    }
  }

  Iterable<String> _resolvePossibleOrderIds(String rawValue) sync* {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return;

    final direct = int.tryParse(trimmed);
    if (direct != null) {
      yield direct.toString();
      return;
    }

    final matches = RegExp(r'\d+').allMatches(trimmed).map((m) => m.group(0)!);
    for (final part in matches.toList().reversed) {
      final parsed = int.tryParse(part);
      if (parsed != null) {
        yield parsed.toString();
      }
    }
  }

  Map<String, dynamic> _normalize(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is String) return jsonDecode(body) as Map<String, dynamic>;
    return {};
  }

  List<Map<String, dynamic>> _normalizeOrdersList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final normalized = _normalize(body);
    final rawList =
        normalized['data'] ??
        normalized['items'] ??
        normalized['pedidos'] ??
        normalized['orders'] ??
        [];

    if (rawList is! List) return [];

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<String?> _resolveOrderIdFromReceipt(String rawValue) async {
    final lookup = rawValue.trim().toUpperCase();
    if (lookup.isEmpty) return null;
    if (!lookup.contains('B001') && !lookup.contains('F001')) return null;

    try {
      final res = await _api.get(ApiEndpoints.receipts);
      if (res.statusCode != 200) return null;

      final normalized = _normalize(res.data);
      final rawList = normalized['comprobantes'] ?? normalized['items'] ?? [];
      if (rawList is! List) return null;

      for (final item in rawList.whereType<Map>()) {
        final comprobante = Map<String, dynamic>.from(item);
        final numero = (comprobante['numero'] ?? '').toString().toUpperCase();
        final numeroFormateado = (comprobante['numero_formateado'] ?? '')
            .toString()
            .toUpperCase();

        if (lookup != numero && lookup != numeroFormateado) continue;

        final archivos = comprobante['archivos'];
        if (archivos is! Map) continue;
        final pdfPath = (archivos['pdf'] ?? '').toString();
        final match = RegExp(r'pedido-(\d+)-').firstMatch(pdfPath);
        final pedidoId = match?.group(1);
        if (pedidoId != null && pedidoId.isNotEmpty) {
          return pedidoId;
        }
      }
    } catch (_) {}

    return null;
  }
}
