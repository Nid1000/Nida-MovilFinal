import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_cliente.dart';
import 'api_endpoints.dart';

class ProductsService {
  final Dio _api = ApiClient().dio;

  Future<List<Map<String, dynamic>>> fetchProducts({
    bool featuredOnly = false,
    int limit = 50,
    String search = '',
    String categoryId = '',
  }) async {
    try {
      final res = await _api.get(
        ApiEndpoints.products,
        queryParameters: {
          'pagina': 1,
          'limite': limit,
          if (featuredOnly) 'destacado': 'true',
          if (search.trim().isNotEmpty) 'buscar': search.trim(),
          if (categoryId.trim().isNotEmpty) 'categoria': categoryId.trim(),
        },
      );

      if (res.statusCode == 200) {
        final data = _normalizeList(res.data);
        if (data.isNotEmpty) {
          return data;
        }
      }
    } catch (e) {
      // Keep local fallback products available if the backend is temporarily unavailable.
    }

    return _fallbackProducts;
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final res = await _api.get(ApiEndpoints.categories);
      final raw = _extractList(res.data);
      return raw
          .map(
            (item) => {
              'id': (item['id'] ?? '').toString(),
              'name': (item['nombre'] ?? item['name'] ?? 'Categoria')
                  .toString(),
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _normalizeList(dynamic body) {
    final rawList = _extractList(body);
    return rawList.map(_normalizeProduct).toList();
  }

  List<Map<String, dynamic>> _extractList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final candidates = [
        body['data'],
        body['items'],
        body['productos'],
        body['categorias'],
        body['results'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }
    if (body is String) {
      final decoded = jsonDecode(body);
      return _extractList(decoded);
    }
    return [];
  }

  Map<String, dynamic> _normalizeProduct(Map<String, dynamic> raw) {
    final image = (raw['image'] ?? raw['imagen'] ?? raw['imageUrl'] ?? '')
        .toString();
    return {
      'id': (raw['id'] ?? raw['_id'] ?? raw['productId'] ?? '').toString(),
      'name': (raw['name'] ?? raw['nombre'] ?? raw['title'] ?? 'Producto')
          .toString(),
      'price': _toDouble(raw['price'] ?? raw['precio']),
      'desc': (raw['desc'] ?? raw['descripcion'] ?? raw['description'] ?? '')
          .toString(),
      'image': image,
      'imageUrl': _resolveImageUrl(image),
      'discount': _toDouble(raw['discount'] ?? raw['descuento']),
      'promotion': _toBool(
        raw['promotion'] ?? raw['promocion'] ?? raw['destacado'],
      ),
      'featured': _toBool(
        raw['destacado'] ?? raw['promotion'] ?? raw['promocion'],
      ),
      'stock': int.tryParse((raw['stock'] ?? '0').toString()) ?? 0,
      'category': (raw['categoria_nombre'] ?? raw['categoria']?['nombre'] ?? '')
          .toString(),
    };
  }

  String _resolveImageUrl(String image) {
    var trimmed = image.trim().replaceAll('\\', '/');
    if (trimmed.isEmpty) return '';

    final absoluteUri = Uri.tryParse(trimmed);
    if (absoluteUri != null && absoluteUri.hasScheme) {
      trimmed = absoluteUri.path;
    }

    trimmed = trimmed.replaceFirst(RegExp(r'^/+'), '');
    trimmed = trimmed.replaceFirst(RegExp(r'^(api/)?uploads/+'), '');
    if (trimmed.isEmpty) return '';

    return '${ApiEndpoints.uploadsBaseUrl}/$trimmed';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 'si';
  }

  List<Map<String, dynamic>> get _fallbackProducts => const [
    {
      'id': 'p1',
      'name': 'Pan de Hamburguesas',
      'price': 10.00,
      'desc': 'Pan perfecto para hamburguesas',
      'image': '',
      'imageUrl': '',
      'discount': 0.1,
      'promotion': true,
      'featured': true,
      'stock': 10,
      'category': 'Panadería',
    },
    {
      'id': 'p2',
      'name': 'Pan Especial',
      'price': 8.00,
      'desc': 'Masa madre, súper suave',
      'image': '',
      'imageUrl': '',
      'discount': 0.2,
      'promotion': true,
      'featured': true,
      'stock': 8,
      'category': 'Panadería',
    },
    {
      'id': 'p3',
      'name': 'Pan Integral',
      'price': 7.00,
      'desc': 'Opción saludable integral',
      'image': '',
      'imageUrl': '',
      'discount': 0.05,
      'promotion': false,
      'featured': false,
      'stock': 6,
      'category': 'Panadería',
    },
    {
      'id': 'p4',
      'name': 'Pan Francés',
      'price': 2.00,
      'desc': 'Clásico crocante del día',
      'image': '',
      'imageUrl': '',
      'discount': 0.0,
      'promotion': false,
      'featured': false,
      'stock': 20,
      'category': 'Panadería',
    },
  ];
}
