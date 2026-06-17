import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../services/products_service.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';
import '../widgets/delicias_appbar.dart';

class PromocionesPage extends StatefulWidget {
  const PromocionesPage({super.key});

  @override
  State<PromocionesPage> createState() => _PromocionesPageState();
}

class _PromocionesPageState extends State<PromocionesPage> {
  final _service = ProductsService();
  final _cart = CartService();
  bool _loading = true;
  List<Map<String, dynamic>> _products = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final featuredProducts = await _service.fetchProducts(
        featuredOnly: true,
        limit: 10,
      );
      final allProducts = await _service.fetchProducts(limit: 20);

      final mergedProducts = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      void addProducts(Iterable<Map<String, dynamic>> items) {
        for (final item in items) {
          final id = (item['id'] ?? '').toString();
          final key = id.isNotEmpty
              ? id
              : '${item['name']}-${item['price']}-${item['category']}';
          if (seenIds.add(key)) {
            mergedProducts.add(item);
          }
        }
      }

      addProducts(
        featuredProducts.where(
          (p) => p['featured'] == true || p['promotion'] == true,
        ),
      );
      addProducts(
        allProducts.where(
          (p) => p['featured'] == true || p['promotion'] == true,
        ),
      );

      if (!mounted) return;
      setState(() {
        _products = mergedProducts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar las promociones.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;
    final crossAxisCount = width >= 980
        ? 4
        : width >= 720
        ? 3
        : 2;

    return Scaffold(
      appBar: const DeliciasAppBar(title: 'Promociones'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
            ? Center(
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                children: [
                  ResponsiveContent(
                    child: const Text(
                      'Promociones y productos destacados de la panadería.',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_products.isEmpty)
                    const ResponsiveContent(child: _EmptyPromoState())
                  else
                    ResponsiveContent(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: width < 390 ? 0.66 : 0.72,
                        ),
                        itemBuilder: (context, index) => _PromoCard(
                          product: _products[index],
                          onTap: () => _addToCart(_products[index]),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    _cart.addProduct({
      'id': product['id'],
      'name': product['name'],
      'price': product['price'],
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} agregado al carrito'),
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {});
  }
}

class _PromoCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _PromoCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final title = (product['name'] ?? 'Producto').toString();
    final desc =
        (product['desc'] ?? 'Disponible en el catálogo de la panadería')
            .toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E9EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.28,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFF1F2F6)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, _, _) => const _PromoImageFallback(),
                    )
                  : const _PromoImageFallback(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C2F38),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      desc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: Color(0xFF8A90A0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB725),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Ver oferta',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoImageFallback extends StatelessWidget {
  const _PromoImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.bakery_dining_outlined,
        color: AppColors.text,
        size: 34,
      ),
    );
  }
}

class _EmptyPromoState extends StatelessWidget {
  const _EmptyPromoState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9E9EE)),
      ),
      child: const Text(
        'No hay promociones destacadas disponibles por ahora.',
        style: TextStyle(color: AppColors.muted),
      ),
    );
  }
}
