import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';
import 'proceso_pago_page.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final cart = CartService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900),
        ),
      ),
      body: cart.items.isEmpty ? _empty() : _content(),
    );
  }

  Widget _empty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 46, color: AppColors.text),
            SizedBox(height: 10),
            Text(
              'Aún no agregaste productos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Ve a Nuevos Productos y presiona Agregar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final compact = context.isCompact;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        10,
        compact ? 12 : 16,
        16,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final it = cart.items[i];
                final name = it['name'].toString();
                final qty = it['qty'] as int;
                final price = it['price'] as double;
                final subtotal = price * qty;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.bakery_dining,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'S/${price.toStringAsFixed(2)} • Cantidad: $qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(width: 10),
                            _itemActions(subtotal, name),
                          ],
                        ],
                      ),
                      if (compact) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'S/${subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                            const Spacer(),
                            _removeButton(name),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Text(
                  'S/${cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          compact
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(() => cart.clear()),
                        child: const Text('Vaciar'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProcesoPagoPage(),
                            ),
                          );
                          setState(() {});
                        },
                        child: const Text('Continuar'),
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 180,
                      child: OutlinedButton(
                        onPressed: () => setState(() => cart.clear()),
                        child: const Text('Vaciar'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProcesoPagoPage(),
                            ),
                          );
                          setState(() {});
                        },
                        child: const Text('Continuar'),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _itemActions(double subtotal, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'S/${subtotal.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        _removeButton(name),
      ],
    );
  }

  Widget _removeButton(String name) {
    return InkWell(
      onTap: () => setState(() => cart.removeOne(name)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Quitar',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
        ),
      ),
    );
  }
}
