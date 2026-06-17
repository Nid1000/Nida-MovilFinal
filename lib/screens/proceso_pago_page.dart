import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../services/dni_service.dart';
import '../services/orders_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import 'pago_exitoso_page.dart';

class ProcesoPagoPage extends StatefulWidget {
  const ProcesoPagoPage({super.key});

  @override
  State<ProcesoPagoPage> createState() => _ProcesoPagoPageState();
}

class _ProcesoPagoPageState extends State<ProcesoPagoPage> {
  static const List<String> _districtOptions = [
    'El Tambo',
    'Huancayo',
    'Chilca',
    'Pilcomayo',
    'San Agustin',
  ];

  String _metodo = 'Contra entrega';
  String _comprobanteTipo = 'boleta';
  String _tipoDocumento = 'DNI';
  bool _loading = false;
  bool _initialized = false;
  bool _consultandoDocumento = false;
  String? _documentoInfo;
  String? _documentoError;

  final _nTarjeta = TextEditingController();
  final _titular = TextEditingController();
  final _expiracion = TextEditingController();
  final _fechaEntrega = TextEditingController();
  final _direccion = TextEditingController();
  final _distrito = TextEditingController(text: 'El Tambo');
  final _numeroCasa = TextEditingController();
  final _telefono = TextEditingController();
  final _notas = TextEditingController();
  final _numeroDocumento = TextEditingController();
  final _operacionYape = TextEditingController();
  final _documentoService = DniService();

  Future<void> _seleccionarFechaEntrega() async {
    final now = DateTime.now();
    final initialDate =
        _parseFechaEntrega() ?? now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(now.year, now.month, now.day + 1),
      lastDate: DateTime(now.year + 2),
      helpText: 'Selecciona la fecha de entrega',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) return;

    _fechaEntrega.text = _formatFechaEntrega(picked);
  }

  DateTime? _parseFechaEntrega() {
    final value = _fechaEntrega.text.trim();
    if (value.isEmpty) return null;
    final slashMatch = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$').firstMatch(value);
    if (slashMatch != null) {
      final day = int.tryParse(slashMatch.group(1)!);
      final month = int.tryParse(slashMatch.group(2)!);
      final year = int.tryParse(slashMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(value);
  }

  String _formatFechaEntrega(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String? _backendFechaEntrega() {
    final parsed = _parseFechaEntrega();
    if (parsed == null) return null;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  void _msg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _consultarDocumento() async {
    final numero = _numeroDocumento.text.trim();
    if (_tipoDocumento == 'DNI') {
      if (numero.length != 8) {
        setState(() {
          _documentoError = 'El DNI debe tener 8 digitos';
          _documentoInfo = null;
        });
        return;
      }
    } else {
      if (numero.length != 11) {
        setState(() {
          _documentoError = 'El RUC debe tener 11 digitos';
          _documentoInfo = null;
        });
        return;
      }
    }

    setState(() {
      _consultandoDocumento = true;
      _documentoError = null;
      _documentoInfo = null;
    });

    if (_tipoDocumento == 'DNI') {
      final result = await _documentoService.consultarDni(numero);
      if (!mounted) return;
      setState(() {
        _consultandoDocumento = false;
        if (result == null) {
          _documentoError = 'No se pudo validar el DNI en este momento';
        } else {
          _documentoInfo = result.nombreCompleto.isEmpty
              ? 'DNI validado correctamente'
              : result.nombreCompleto;
        }
      });
      return;
    }

    final result = await _documentoService.consultarRuc(numero);
    if (!mounted) return;
    setState(() {
      _consultandoDocumento = false;
      if (result == null) {
        _documentoError = 'No se pudo validar el RUC en este momento';
      } else {
        _documentoInfo = result.razonSocial.isEmpty
            ? 'RUC validado correctamente'
            : result.nombreCompleto;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    SessionService().getUser().then((user) {
      if (!mounted || user == null) return;
      setState(() {
        _direccion.text = user.direccion;
        _distrito.text = user.distrito.trim().isEmpty
            ? _distrito.text
            : user.distrito;
        _telefono.text = user.telefono;
        _numeroCasa.text = user.numeroCasa;
      });
    });
  }

  @override
  void dispose() {
    _nTarjeta.dispose();
    _titular.dispose();
    _expiracion.dispose();
    _fechaEntrega.dispose();
    _direccion.dispose();
    _distrito.dispose();
    _numeroCasa.dispose();
    _telefono.dispose();
    _notas.dispose();
    _numeroDocumento.dispose();
    _operacionYape.dispose();
    super.dispose();
  }

  Future<void> _pagar() async {
    final cart = CartService();
    if (cart.items.isEmpty) {
      _msg('Tu carrito esta vacio');
      return;
    }

    if (_direccion.text.trim().isEmpty ||
        _distrito.text.trim().isEmpty ||
        _telefono.text.trim().isEmpty) {
      _msg('Completa dirección, distrito y teléfono');
      return;
    }

    if (_tipoDocumento == 'DNI' && _numeroDocumento.text.trim().length != 8) {
      _msg('El DNI debe tener 8 digitos');
      return;
    }

    if (_tipoDocumento == 'RUC' && _numeroDocumento.text.trim().length != 11) {
      _msg('El RUC debe tener 11 digitos');
      return;
    }

    if (_metodo == 'Tarjeta') {
      if (_nTarjeta.text.trim().length != 4 || _titular.text.trim().isEmpty) {
        _msg('Completa bien los datos de la tarjeta');
        return;
      }
    }
    if (_metodo == 'Yape' && _operacionYape.text.trim().isEmpty) {
      _msg('Ingresa el número de operación de Yape');
      return;
    }

    setState(() => _loading = true);
    final orders = OrdersService();

    try {
      final orderId = await orders.createOrder(
        items: cart.items,
        total: cart.total,
        metodoPago: _metodo,
        pagoReferencia: _metodo == 'Yape'
            ? _operacionYape.text.trim()
            : _metodo == 'Tarjeta'
            ? '${_titular.text.trim()} | ****${_nTarjeta.text.trim()} | ${_expiracion.text.trim()}'
            : null,
        fechaEntrega: _backendFechaEntrega(),
        direccionEntrega: _direccion.text.trim(),
        distritoEntrega: _distrito.text.trim(),
        numeroCasaEntrega: _numeroCasa.text.trim(),
        telefonoContacto: _telefono.text.trim(),
        notas: _notas.text.trim().isEmpty ? null : _notas.text.trim(),
      );

      if (orderId == null || orderId.trim().isEmpty) {
        _msg('No pudimos registrar tu pedido en este momento');
        return;
      }

      final receiptIssued = await orders.issueReceipt(
        orderId: orderId,
        comprobanteTipo: _comprobanteTipo,
        tipoDocumento: _tipoDocumento,
        numeroDocumento: _numeroDocumento.text.trim(),
      );

      cart.clear();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PagoExitosoPage(orderId: orderId)),
      );

      if (receiptIssued) {
        _msg('Pedido registrado y comprobante emitido correctamente.');
      }
    } catch (_) {
      _msg('No pudimos registrar tu compra en este momento.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartService();
    final textTheme = Theme.of(context).textTheme;
    final twoColumns = MediaQuery.of(context).size.width >= 420;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _checkoutSection(
              title: 'Resumen de productos',
              child: Column(
                children: [
                  ...cart.items.asMap().entries.map((entry) {
                    final isLast = entry.key == cart.items.length - 1;
                    return Column(
                      children: [
                        _summaryProductRow(entry.value),
                        if (!isLast)
                          const Divider(height: 1, color: AppColors.text),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  _summaryTotal(cart.total),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Boleta: Sin IGV',
                      style: TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _responsiveFields(
              twoColumns: twoColumns,
              left: _fieldBlock(
                label: 'Distrito',
                child: DropdownButtonFormField<String>(
                  value: _districtOptions.contains(_distrito.text.trim())
                      ? _distrito.text.trim()
                      : null,
                  items: _districtOptions
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _distrito.text = value ?? '';
                    });
                  },
                  decoration: _checkoutInputDecoration(),
                ),
              ),
              right: _fieldBlock(
                label: 'Número de casa',
                child: TextField(
                  controller: _numeroCasa,
                  decoration: _checkoutInputDecoration(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _responsiveFields(
              twoColumns: twoColumns,
              left: _fieldBlock(
                label: 'Dirección de entrega',
                child: TextField(
                  controller: _direccion,
                  decoration: _checkoutInputDecoration(
                    prefixIcon: const Icon(Icons.place_outlined, size: 18),
                  ),
                ),
              ),
              right: _fieldBlock(
                label: 'Fecha de entrega',
                child: TextField(
                  controller: _fechaEntrega,
                  readOnly: true,
                  onTap: _seleccionarFechaEntrega,
                  decoration: _checkoutInputDecoration(
                    hintText: 'dd/mm/aaaa',
                    suffixIcon: IconButton(
                      onPressed: _seleccionarFechaEntrega,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _responsiveFields(
              twoColumns: twoColumns,
              left: _fieldBlock(
                label: 'Teléfono de contacto',
                child: TextField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: _checkoutInputDecoration(),
                ),
              ),
              right: _fieldBlock(
                label: 'Notas',
                child: TextField(
                  controller: _notas,
                  decoration: _checkoutInputDecoration(
                    hintText: 'Instrucciones adicionales',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Método de pago', style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _compactRadio('Contra entrega')),
                Expanded(child: _compactRadio('Tarjeta')),
                Expanded(child: _compactRadio('Yape')),
              ],
            ),
            if (_metodo == 'Tarjeta') ...[
              const SizedBox(height: 10),
              _responsiveFields(
                twoColumns: twoColumns,
                left: _fieldBlock(
                  label: 'Ultimos 4 digitos',
                  child: TextField(
                    controller: _nTarjeta,
                    keyboardType: TextInputType.number,
                    decoration: _checkoutInputDecoration(hintText: '1234'),
                  ),
                ),
                right: _fieldBlock(
                  label: 'Nombre en la tarjeta',
                  child: TextField(
                    controller: _titular,
                    decoration: _checkoutInputDecoration(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldBlock(
                label: 'Expiracion (MM/YY)',
                child: TextField(
                  controller: _expiracion,
                  decoration: _checkoutInputDecoration(hintText: 'MM/YY'),
                ),
              ),
            ],
            if (_metodo == 'Yape') ...[
              const SizedBox(height: 10),
              const Text(
                'Realiza el pago por Yape al 993 560 096 y registra el número de operación.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _operacionYape,
                keyboardType: TextInputType.number,
                decoration: _checkoutInputDecoration(
                  hintText: 'Número de operación',
                ),
              ),
            ],
            const SizedBox(height: 12),
            _checkoutSection(
              title: 'Comprobante electrónico',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _responsiveFields(
                    twoColumns: twoColumns,
                    left: _fieldBlock(
                      label: 'Tipo',
                      child: DropdownButtonFormField<String>(
                        value: _comprobanteTipo,
                        items: const [
                          DropdownMenuItem(
                            value: 'boleta',
                            child: Text('Boleta'),
                          ),
                          DropdownMenuItem(
                            value: 'factura',
                            child: Text('Factura'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _comprobanteTipo = value!),
                        decoration: _checkoutInputDecoration(),
                      ),
                    ),
                    right: _fieldBlock(
                      label: 'Documento',
                      child: DropdownButtonFormField<String>(
                        value: _tipoDocumento,
                        items: const [
                          DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                          DropdownMenuItem(value: 'RUC', child: Text('RUC')),
                        ],
                        onChanged: (value) => setState(() {
                          _tipoDocumento = value!;
                          _documentoInfo = null;
                          _documentoError = null;
                        }),
                        decoration: _checkoutInputDecoration(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _fieldBlock(
                          label: 'Número',
                          child: TextField(
                            controller: _numeroDocumento,
                            keyboardType: TextInputType.number,
                            decoration: _checkoutInputDecoration(
                              hintText: _tipoDocumento == 'DNI'
                                  ? '12345678'
                                  : '12345678901',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: !_consultandoDocumento
                              ? _consultarDocumento
                              : null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            side: const BorderSide(
                              color: AppColors.text,
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          child: _consultandoDocumento
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Consultar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Para boleta no se aplica IGV.',
                    style: TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
                  if (_documentoInfo != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _tipoDocumento == 'DNI'
                          ? 'RENIEC: $_documentoInfo'
                          : 'SUNAT: $_documentoInfo',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_documentoError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _documentoError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : ElevatedButton(
                      onPressed: _pagar,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Confirmar pedido'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactRadio(String label) {
    final value = label;
    return InkWell(
      onTap: () => setState(() => _metodo = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _metodo,
            onChanged: (selected) => setState(() => _metodo = selected!),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _checkoutSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppColors.text, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Text(title, style: const TextStyle(fontSize: 12)),
          ),
          const Divider(height: 1, color: AppColors.text, thickness: 0.8),
          Padding(padding: const EdgeInsets.all(8), child: child),
        ],
      ),
    );
  }

  Widget _fieldBlock({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _responsiveFields({
    required bool twoColumns,
    required Widget left,
    required Widget right,
  }) {
    if (!twoColumns) {
      return Column(children: [left, const SizedBox(height: 12), right]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right),
      ],
    );
  }

  Widget _summaryProductRow(Map<String, dynamic> item) {
    final qty = item['qty'] as int;
    final price = item['price'] as double;
    final subtotal = price * qty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Cantidad: x$qty',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                const Text(
                  'Subtotal',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Precio unitario: S/ ${price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              Text(
                'S/ ${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTotal(double total) {
    return Row(
      children: [
        const Expanded(child: Text('Total', style: TextStyle(fontSize: 12))),
        Text(
          'S/ ${total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  InputDecoration _checkoutInputDecoration({
    String? hintText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      fillColor: Colors.white.withValues(alpha: 0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: AppColors.text, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: AppColors.text, width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: AppColors.text, width: 0.8),
      ),
    );
  }
}
