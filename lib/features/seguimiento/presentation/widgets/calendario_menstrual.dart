import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/registro_ciclo.dart';

/// Calendario mensual que resalta los días cubiertos por algún ciclo
/// registrado. El color de cada día varía según la abundancia del
/// sangrado, para que la usuaria distinga visualmente la intensidad de
/// cada ciclo al navegar el calendario. Incluye una leyenda de colores.
class CalendarioMenstrual extends StatelessWidget {
  final List<RegistroCiclo> registros;
  final DateTime mesEnfocado;
  final ValueChanged<DateTime> onMesCambiado;

  const CalendarioMenstrual({
    super.key,
    required this.registros,
    required this.mesEnfocado,
    required this.onMesCambiado,
  });

  static const Map<AbundanciaSangrado, Color> _colorPorAbundancia = {
    AbundanciaSangrado.leve: Color(0xFFF48FB1),
    AbundanciaSangrado.moderada: Color(0xFFE91E63),
    AbundanciaSangrado.abundante: Color(0xFFB71C1C),
  };

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  RegistroCiclo? _registroDelDia(DateTime dia) {
    for (final registro in registros) {
      if (registro.diasCubiertos.any((d) => _mismoDia(d, dia))) {
        return registro;
      }
    }
    return null;
  }

  Widget? _construirDia(DateTime day, {bool esHoy = false}) {
    final registro = _registroDelDia(day);
    if (registro == null) return null;
    final color = _colorPorAbundancia[registro.abundancia]!;
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: esHoy ? Border.all(color: Colors.black87, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2035, 12, 31),
          focusedDay: mesEnfocado,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarFormat: CalendarFormat.month,
          onPageChanged: onMesCambiado,
          selectedDayPredicate: (_) => false,
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) => _construirDia(day),
            todayBuilder: (context, day, focusedDay) =>
                _construirDia(day, esHoy: true),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: _colorPorAbundancia.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: entry.value, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(entry.key.etiqueta, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}