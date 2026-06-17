import 'package:flutter/material.dart';

import '../services/order_tracking_service.dart';
import '../services/products_service.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';
import 'chat_bot_page.dart';
import 'contact_page.dart';
import 'informacion_ayuda_page.dart';
import 'panaderia_page.dart';
import 'promociones_page.dart';

class MyHomePage extends StatefulWidget {
  final String userName;
  final bool isGuest;
  final bool embedded;
  final VoidCallback? onOpenTracking;
  final VoidCallback? onOpenLatestOrder;

  const MyHomePage({
    super.key,
    required this.userName,
    this.isGuest = false,
    this.embedded = false,
    this.onOpenTracking,
    this.onOpenLatestOrder,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _trackingService = OrderTrackingService();
  final _productsService = ProductsService();

  int _ordersCount = 0;
  int _featuredCount = 0;
  String _latestOrderStatus = 'Sin pedidos';
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _trackingService.getMyOrders(limit: 20),
        _productsService.fetchProducts(featuredOnly: true, limit: 20),
      ]);

      final orders = results[0];
      final featured = results[1];
      if (!mounted) return;

      final latestStatus = orders.isEmpty
          ? 'Sin pedidos'
          : (orders.first['estado'] ?? 'Pendiente').toString();

      setState(() {
        _ordersCount = orders.length;
        _featuredCount = featured.length;
        _latestOrderStatus = latestStatus;
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileColumns = context.screenWidth >= 900 ? 3 : 2;

    final content = SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logos/delicias.png',
                          width: 38,
                          height: 38,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            fontFamily: 'serif',
                            color: Color(0xFF0C4FB6),
                            shadows: [
                              Shadow(
                                color: Color(0x1A000000),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      '¡Bienvenido a Panadería\nDelicias del Centro!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.15,
                        fontFamily: 'serif',
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      widget.isGuest
                          ? 'Explora nuestras delicias y servicios.'
                          : 'Explora nuestras delicias, servicios y el estado de tus pedidos.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: tileColumns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.92,
                    children: [
                      _HomeTile(
                        label: 'Promociones',
                        icon: Icons.local_offer_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PromocionesPage(),
                          ),
                        ),
                      ),
                      _HomeTile(
                        label: 'Seguimiento',
                        icon: Icons.local_shipping_outlined,
                        onTap: widget.onOpenTracking ?? () {},
                      ),
                      _HomeTile(
                        label: 'Productos',
                        icon: Icons.bakery_dining_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PanaderiaPage(),
                          ),
                        ),
                      ),
                      _HomeTile(
                        label: 'Chatbot',
                        icon: Icons.smart_toy_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChatBotPage(),
                          ),
                        ),
                      ),
                      _HomeTile(
                        label: 'Mi pedido',
                        icon: Icons.inventory_2_outlined,
                        badge: _loadingStats
                            ? '...'
                            : widget.isGuest
                            ? _latestOrderStatus
                            : '$_ordersCount',
                        onTap:
                            widget.onOpenLatestOrder ??
                            widget.onOpenTracking ??
                            () {},
                      ),
                      _HomeTile(
                        label: 'Información',
                        icon: Icons.info_outline,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InformacionAyudaPage(),
                          ),
                        ),
                      ),
                      _HomeTile(
                        label: 'Contacto',
                        icon: Icons.mail_outline,
                        badge: _loadingStats ? '...' : '$_featuredCount',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContactPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 130,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            children: [
              Image.asset('assets/logos/delicias.png', height: 24),
              const SizedBox(width: 8),
              const Text(
                'Delicias',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'Inicio',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
        ),
      ),
      body: content,
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _HomeTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(223, 216, 168, 66),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: const Color(0xFF171717)),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 8),
                Text(
                  badge!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A2410),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
