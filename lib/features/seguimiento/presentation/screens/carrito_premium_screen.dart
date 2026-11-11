import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
 
enum _Paso { carrito, pago, procesando, listo }
 
class CarritoPremiumScreen extends StatefulWidget {
  const CarritoPremiumScreen({super.key});
 
  @override
  State<CarritoPremiumScreen> createState() => _CarritoPremiumScreenState();
}
 
class _CarritoPremiumScreenState extends State<CarritoPremiumScreen> {
  static const _precio = r'$18.000';
  static const _metodos = <(String, IconData)>[
    ('Tarjeta de crédito o débito', Icons.credit_card),
    ('PSE', Icons.account_balance),
    ('Nequi', Icons.phone_android),
    ('Daviplata', Icons.phone_android),
  ];
  static const _beneficios = <String>[
    'Reportes completos con gráficas y calendario',
    'Comparación de tu dolor durante la regla y fuera de ella',
    'Cruces con sueño y estrés',
    'Resumen médico en PDF para tu consulta',
  ];
 
  _Paso _paso = _Paso.carrito;
  String? _metodo;
 
  Future<void> _pagar() async {
    setState(() => _paso = _Paso.procesando);
    try {
      final token = AuthService.token;
      if (token == null) throw Exception('Tu sesión expiró. Inicia sesión de nuevo.');
      await Future.wait([
        AuthService.activarPremium(token),
        Future<void>.delayed(const Duration(milliseconds: 2500)),
      ]);
      if (!mounted) return;
      setState(() => _paso = _Paso.listo);
    } catch (e) {
      if (!mounted) return;
      setState(() => _paso = _Paso.pago);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final bloqueado = _paso == _Paso.procesando || _paso == _Paso.listo;
    return PopScope(
      canPop: !bloqueado,
      child: Scaffold(
        appBar: AppBar(
          title: Text(switch (_paso) {
            _Paso.carrito => 'Mi carrito',
            _Paso.pago => 'Método de pago',
            _Paso.procesando => 'Procesando pago',
            _Paso.listo => 'Compra exitosa',
          }),
          automaticallyImplyLeading: !bloqueado,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: switch (_paso) {
              _Paso.carrito => _vistaCarrito(context),
              _Paso.pago => _vistaPago(context),
              _Paso.procesando => _vistaProcesando(context),
              _Paso.listo => _vistaListo(context),
            },
          ),
        ),
      ),
    );
  }
 
  Widget _resumen(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        leading: Icon(Icons.workspace_premium, color: color, size: 32),
        title: const Text('Florecer Premium',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Suscripción mensual'),
        trailing: Text(
          _precio,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
 
  Widget _total(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '$_precio COP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      );
 
  Widget _vistaCarrito(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _resumen(context),
          const Spacer(),
          _total(context),
          ElevatedButton(
            onPressed: () => setState(() => _paso = _Paso.pago),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Seleccionar método de pago'),
            ),
          ),
        ],
      );
 
  Widget _vistaPago(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('¿Cómo quieres pagar?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final m in _metodos)
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _metodo == m.$1 ? color : Colors.grey.shade300,
                width: _metodo == m.$1 ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Icon(m.$2, color: color),
              title: Text(m.$1),
              trailing: Icon(
                _metodo == m.$1
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: color,
              ),
              onTap: () => setState(() => _metodo = m.$1),
            ),
          ),
        const Spacer(),
        _total(context),
        ElevatedButton(
          onPressed: _metodo == null ? null : _pagar,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Pagar $_precio'),
          ),
        ),
      ],
    );
  }
 
  Widget _vistaProcesando(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Procesando pago…',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Un momento, por favor.'),
          ],
        ),
      );
 
  Widget _vistaListo(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Icon(Icons.check_circle, size: 80, color: color),
        const SizedBox(height: 12),
        Text(
          '¡Ya eres Premium!',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 20),
        for (final b in _beneficios)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(child: Text(b)),
              ],
            ),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Ver mis reportes'),
          ),
        ),
      ],
    );
  }
}