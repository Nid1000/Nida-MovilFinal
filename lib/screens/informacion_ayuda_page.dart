import 'package:flutter/material.dart';

import '../models/informacion_ayuda.dart';
import '../theme/app_colors.dart';
import '../widgets/delicias_appbar.dart';
import '../widgets/delicias_card.dart';

class InformacionAyudaPage extends StatefulWidget {
  const InformacionAyudaPage({super.key});

  @override
  State<InformacionAyudaPage> createState() => _InformacionAyudaPageState();
}

class _InformacionAyudaPageState extends State<InformacionAyudaPage> {
  final List<InformacionAyuda> items = [
    InformacionAyuda(
      titulo: 'Como comprar en nuestra panaderia',
      detalles: [
        {'Paso 1': 'Explora panes, postres y productos destacados en Tienda.'},
        {
          'Paso 2':
              'Abre cada producto para ver ingredientes, precio y disponibilidad.',
        },
        {
          'Paso 3':
              'Agrega tus favoritos al carrito y ajusta cantidades antes de pagar.',
        },
        {
          'Paso 4':
              'Completa tus datos de entrega y selecciona la direccion del pedido.',
        },
        {
          'Paso 5':
              'Elige tu metodo de pago y confirma para generar tu comprobante.',
        },
      ],
    ),
    InformacionAyuda(
      titulo: 'Horario de atencion',
      detalles: [
        {'Lunes a viernes': '9:00 AM - 6:00 PM.'},
        {'Sabado': '8:00 AM - 2:00 PM.'},
        {'Domingo': 'Cerrado.'},
        {'Feriados': 'Puede variar segun campana o temporada.'},
      ],
    ),
    InformacionAyuda(
      titulo: 'Formas de pago',
      detalles: [
        {'Visa': 'Pago seguro con tarjetas Visa debito o credito.'},
        {'Mastercard': 'Disponible para compras en linea y en tienda.'},
        {'Efectivo': 'Pago contra entrega segun cobertura del delivery.'},
        {'Yape/Plin': 'Solicita el numero al confirmar tu pedido.'},
      ],
    ),
    InformacionAyuda(
      titulo: 'Cambios y devoluciones',
      detalles: [
        {
          'Producto en mal estado':
              'Reporta dentro de las primeras 24 horas con foto del producto.',
        },
        {
          'Pedido incompleto':
              'Te ayudamos con reposicion o nota de credito segun el caso.',
        },
        {
          'Error en pedido':
              'Si aun no fue preparado, podemos corregirlo antes del despacho.',
        },
        {
          'Canales de apoyo':
              'Contactanos por telefono o WhatsApp para seguimiento rapido.',
        },
      ],
    ),
    InformacionAyuda(
      titulo: 'Ubicacion y contacto',
      detalles: [
        {'Direccion': 'Jr. Parra del Riego 2 do piso'},
        {'Administrador': '974268690'},
        {'WhatsApp': '974268690'},
        {'Correo': 'delicias@empresa.com'},
        {
          'Referencia':
              'Consulta referencias directamente con el administrador.',
        },
      ],
    ),
  ];

  void _openDialog(String title) {
    final selectedItem = items.firstWhere((item) => item.titulo == title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Detalle',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: selectedItem.detalles.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.keys.first,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.values.first,
                        style: const TextStyle(
                          height: 1.35,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: AppColors.accentDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DeliciasAppBar(title: 'Informacion / Ayuda'),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(18),
          itemBuilder: (_, i) => _buildCard(items[i].titulo),
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemCount: items.length,
        ),
      ),
    );
  }

  Widget _buildCard(String title) {
    return DeliciasCard(
      onTap: () => _openDialog(title),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: AppColors.text,
          ),
        ],
      ),
    );
  }
}
