import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../screens/my_orders_page.dart';
import '../screens/pedido_lookup_page.dart';
import '../screens/my_home_page.dart';
import '../screens/perfil_page.dart';
import '../screens/seguimiento_page.dart';
import '../screens/store_page.dart';
import '../services/backend_notification_service.dart';
import '../services/local_notification_service.dart';
import '../services/order_tracking_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';

class AppShell extends StatefulWidget {
  final String userName;
  final bool isGuest;

  const AppShell({super.key, required this.userName, this.isGuest = false});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  final _session = SessionService();
  final _orders = OrderTrackingService();
  final _notifications = BackendNotificationService();
  final List<BackendNotificationItem> _inbox = [];
  Timer? _pollTimer;
  StreamSubscription<String?>? _tapSubscription;
  DateTime? _lastNotifErrorAt;

  @override
  void initState() {
    super.initState();
    if (widget.isGuest) return;
    _tapSubscription = LocalNotificationService.instance.onNotificationTap
        .listen(_handleNotificationTap);
    final initialPayload = LocalNotificationService.instance
        .consumeInitialPayload();
    if (initialPayload != null && initialPayload.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleNotificationTap(initialPayload);
      });
    }
    _pollNotifications();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _pollNotifications(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wideLayout = context.isExpanded;
    final pages = [
      MyHomePage(
        userName: widget.userName,
        isGuest: widget.isGuest,
        embedded: true,
        onOpenTracking: () => setState(() => _tab = 2),
        onOpenLatestOrder: widget.isGuest
            ? () => setState(() => _tab = 2)
            : _openLatestOrder,
      ),
      const StorePage(),
      widget.isGuest
          ? const PedidoLookupPage()
          : MyOrdersPage(
              onGoHome: () => setState(() => _tab = 0),
              onGoStore: () => setState(() => _tab = 1),
            ),
      PerfilPage(isGuest: widget.isGuest),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logos/delicias.png', height: 26),
            const SizedBox(width: 8),
            const Text(
              'Delicias',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFCF8), Color(0xFFF8F1E7)],
            ),
          ),
        ),
        actions: [
          if (!widget.isGuest)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notificaciones',
                    icon: Icon(
                      _inbox.isNotEmpty
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: _inbox.isNotEmpty
                          ? const Color(0xFFE19A00)
                          : AppColors.text,
                    ),
                    onPressed: _openNotificationsSheet,
                  ),
                  if (_inbox.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55E53935),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          '${_inbox.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF7), AppColors.bg],
          ),
        ),
        child: wideLayout
            ? Row(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                      child: NavigationRail(
                        selectedIndex: _tab,
                        onDestinationSelected: (value) =>
                            setState(() => _tab = value),
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: Colors.white.withValues(alpha: 0.82),
                        leading: const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Icon(Icons.dashboard_outlined),
                        ),
                        destinations: [
                          const NavigationRailDestination(
                            icon: Icon(Icons.home_outlined),
                            label: Text('Inicio'),
                          ),
                          const NavigationRailDestination(
                            icon: Icon(Icons.storefront_outlined),
                            label: Text('Tienda'),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: Text(
                              widget.isGuest ? 'Seguimiento' : 'Pedidos',
                            ),
                          ),
                          const NavigationRailDestination(
                            icon: Icon(Icons.person_outline),
                            label: Text('Perfil'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: pages[_tab]),
                ],
              )
            : pages[_tab],
      ),
      bottomNavigationBar: wideLayout
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (value) => setState(() => _tab = value),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Inicio',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  label: 'Tienda',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: widget.isGuest ? 'Seguimiento' : 'Pedidos',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Perfil',
                ),
              ],
            ),
      floatingActionButton: _tab == 0 && !widget.isGuest
          ? FloatingActionButton.extended(
              onPressed: _openLatestOrder,
              icon: const Icon(Icons.radar),
              label: const Text('Mi último pedido'),
            )
          : null,
    );
  }

  Future<void> _openLatestOrder() async {
    final orderId = await _session.getLastOrderId();
    if (orderId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SeguimientoPage(orderId: orderId)),
      );
      return;
    }

    final latest = await _orders.findLatestOrderForCurrentUser();
    if (!mounted) return;
    if (latest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró un pedido reciente.')),
      );
      return;
    }

    await _session.setLastOrderId(latest.id);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeguimientoPage(orderId: latest.id)),
    );
  }

  Future<void> _pollNotifications() async {
    if (widget.isGuest) return;
    final items = await _notifications.fetchPending();
    if (!mounted) return;

    if (items.isEmpty && _notifications.lastError != null) {
      final now = DateTime.now();
      final last = _lastNotifErrorAt;
      if (last == null || now.difference(last).inSeconds > 60) {
        _lastNotifErrorAt = now;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_notifications.lastError!),
              duration: const Duration(seconds: 6),
            ),
          );
      }
      return;
    }
    if (!mounted || items.isEmpty) return;

    setState(() {
      for (final item in items) {
        final exists = _inbox.any((entry) => entry.id == item.id);
        if (!exists) {
          _inbox.insert(0, item);
        }
      }
    });

    for (final item in items) {
      await LocalNotificationService.instance.show(
        title: item.title,
        body: item.body,
        payload: jsonEncode({'route': item.route, 'targetId': item.targetId}),
      );
      _showInAppNotification(item);
    }

    await _notifications.markShown(items.map((item) => item.id).toList());
  }

  void _showInAppNotification(BackendNotificationItem item) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(item.body),
            ],
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () {
              _handleNotificationTap(
                jsonEncode({'route': item.route, 'targetId': item.targetId}),
              );
            },
          ),
        ),
      );
  }

  void _openNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        if (_inbox.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No tienes notificaciones.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _inbox.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _inbox[index];
              return Material(
                color: const Color(0xFFFFF7E7),
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE6B55A),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.black87,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item.body),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleNotificationTap(
                      jsonEncode({
                        'route': item.route,
                        'targetId': item.targetId,
                      }),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      setState(() {
                        _inbox.removeWhere((entry) => entry.id == item.id);
                      });
                      Navigator.pop(context);
                      _openNotificationsSheet();
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleNotificationTap(String? payload) {
    if (!mounted || payload == null || payload.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return;
      final route = (decoded['route'] ?? '').toString();
      final targetId = (decoded['targetId'] ?? '').toString();

      if (route == 'store') {
        setState(() => _tab = 1);
        return;
      }

      if (route == 'order' && targetId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SeguimientoPage(orderId: targetId)),
        );
      }
    } catch (_) {
      // Ignore invalid payloads.
    }
  }
}
