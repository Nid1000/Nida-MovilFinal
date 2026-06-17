import 'package:dio/dio.dart';
import 'api_cliente.dart';
import 'api_endpoints.dart';

class BackendNotificationItem {
  final int id;
  final String title;
  final String body;
  final String route;
  final String targetId;

  const BackendNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.targetId,
  });

  factory BackendNotificationItem.fromMap(Map<String, dynamic> map) {
    return BackendNotificationItem(
      id: ((map['id'] as num?) ?? 0).toInt(),
      title: (map['title'] ?? map['titulo'] ?? 'Notificacion').toString(),
      body: (map['body'] ?? map['mensaje'] ?? '').toString(),
      route: (map['route'] ?? '').toString(),
      targetId: (map['targetId'] ?? '').toString(),
    );
  }
}

class BackendNotificationService {
  final _api = ApiClient().dio;
  String? lastError;

  Future<List<BackendNotificationItem>> fetchPending() async {
    try {
      lastError = null;
      final res = await _api.get(
        ApiEndpoints.pendingNotifications,
        queryParameters: {'canal': 'mobile'},
      );
      final raw = res.data;
      if (raw is! Map<String, dynamic>) return const [];
      final items = raw['notificaciones'];
      if (items is! List) return const [];
      return items
          .whereType<Map>()
          .map(
            (item) =>
                BackendNotificationItem.fromMap(item.cast<String, dynamic>()),
          )
          .where((item) => item.id > 0)
          .toList();
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 401 || status == 403) {
        lastError = 'Sesión expirada. Vuelve a iniciar sesión.';
      } else if (status >= 400 && status < 600) {
        lastError = 'Error del servidor al consultar notificaciones.';
      } else {
        lastError = 'Sin conexión al servidor. Revisa la IP configurada.';
      }
      return const [];
    }
  }

  Future<void> markShown(List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      await _api.post(
        ApiEndpoints.markNotificationsShown,
        data: {'ids': ids, 'canal': 'mobile'},
      );
    } on DioException {
      // Best-effort.
    }
  }
}
