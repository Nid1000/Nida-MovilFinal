import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../services/products_service.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';
import 'proceso_pago_page.dart';
import 'promociones_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final _products = ProductsService();
  final _cart = CartService();

  bool _loading = true;
  List<Map<String, dynamic>> _featured = [];
  List<Map<String, dynamic>> _latest = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final featured = await _products.fetchProducts(
        featuredOnly: true,
        limit: 8,
      );
      final latest = await _products.fetchProducts(limit: 8);
      if (!mounted) return;
      setState(() {
        _featured = featured;
        _latest = latest.take(6).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    _cart.addProduct({
      'id': product['id'],
      'name': product['name'],
      'price': product['price'],
    });
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} agregado al carrito')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final featuredHeight = compact ? 232.0 : 246.0;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.only(top: 16, bottom: 20),
        children: [
          ResponsiveContent(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.panelGradient,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F3F210F),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tienda Delicias',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Arma tu pedido con una presentación más limpia, productos destacados y compra conectada al servidor oficial.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  compact
                      ? Column(
                          children: [
                            _MiniMetric(
                              label: 'Carrito',
                              value: '${_cart.count}',
                              icon: Icons.shopping_bag_outlined,
                            ),
                            const SizedBox(height: 10),
                            _MiniMetric(
                              label: 'Total',
                              value: 'S/${_cart.total.toStringAsFixed(2)}',
                              icon: Icons.sell_outlined,
                            ),
                          ],
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: 220,
                              child: _MiniMetric(
                                label: 'Carrito',
                                value: '${_cart.count}',
                                icon: Icons.shopping_bag_outlined,
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: _MiniMetric(
                                label: 'Total',
                                value: 'S/${_cart.total.toStringAsFixed(2)}',
                                icon: Icons.sell_outlined,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ResponsiveContent(
            child: compact
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PromocionesPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.local_offer_outlined),
                          label: const Text('Promociones'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _cart.items.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProcesoPagoPage(),
                                    ),
                                  ).then((_) => setState(() {}));
                                },
                          icon: const Icon(Icons.payment_outlined),
                          label: Text(
                            _cart.items.isEmpty
                                ? 'Sin carrito'
                                : 'Ir al checkout',
                          ),
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: 220,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PromocionesPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.local_offer_outlined),
                          label: const Text('Promociones'),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: ElevatedButton.icon(
                          onPressed: _cart.items.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProcesoPagoPage(),
                                    ),
                                  ).then((_) => setState(() {}));
                                },
                          icon: const Icon(Icons.payment_outlined),
                          label: Text(
                            _cart.items.isEmpty
                                ? 'Sin carrito'
                                : 'Ir al checkout',
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          const ResponsiveContent(
            child: Text(
              'Destacados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_featured.isEmpty)
            ResponsiveContent(
              child: _emptyCard(
                'No hay productos destacados disponibles por ahora.',
              ),
            )
          else
            ResponsiveContent(
              child: SizedBox(
                height: featuredHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _featured.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _FeaturedCard(
                    product: _featured[index],
                    onAdd: () => _addProduct(_featured[index]),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const ResponsiveContent(
            child: Text(
              'Nuevos para tu compra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const SizedBox.shrink()
          else if (_latest.isEmpty)
            ResponsiveContent(
              child: _emptyCard('No hay productos recientes para mostrar.'),
            )
          else
            ..._latest.map(
              (product) => ResponsiveContent(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecentRow(
                    product: product,
                    onAdd: () => _addProduct(product),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.text),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAdd;

  const _FeaturedCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final price = ((product['price'] as num?) ?? 0).toDouble();
    final category = (product['category'] ?? 'Panadería').toString();

    return Container(
      width: compact ? 190 : 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                color: AppColors.bgSoft,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.bakery_dining,
                          size: 42,
                          color: AppColors.text,
                        ),
                      )
                    : const Icon(
                        Icons.bakery_dining,
                        size: 42,
                        color: AppColors.text,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              category.isEmpty ? 'Destacado' : category,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (product['name'] ?? 'Producto').toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'S/${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.accentDark,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Agregar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAdd;

  const _RecentRow({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final price = ((product['price'] as num?) ?? 0).toDouble();
    final category = (product['category'] ?? 'Panadería').toString();
    final desc = (product['desc'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 78,
                  height: 78,
                  color: AppColors.bgSoft,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.bakery_dining,
                            color: AppColors.text,
                          ),
                        )
                      : const Icon(Icons.bakery_dining, color: AppColors.text),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product['name'] ?? 'Producto').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'S/${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                ElevatedButton(onPressed: onAdd, child: const Text('Agregar')),
              ],
            ],
          ),
          if (compact) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAdd,
                child: const Text('Agregar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
