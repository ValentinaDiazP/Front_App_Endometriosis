import 'package:flutter/material.dart';
import '../../models/profesional.dart';

class DetalleProfesionalScreen extends StatelessWidget {
  final Profesional profesional;
  final VoidCallback onContactar;

  const DetalleProfesionalScreen({
    super.key,
    required this.profesional,
    required this.onContactar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profesional.nombre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera: Avatar, Nombre, Especialidad, Modalidad, Estrellas y Reseñas
            Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFF48FB1),
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profesional.nombre,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profesional.especialidad} • Virtual / Presencial',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          SizedBox(width: 4),
                          Text(
                            '4.9 (24 reseñas)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sección 'Sobre el especialista'
            const Text(
              'Sobre el especialista',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Especialista con amplia trayectoria enfocada en el acompañamiento integral de la salud femenina, dolor pélvico crónico y endometriosis. Comprometida con brindar un espacio empático, seguro y basado en evidencia científica.',
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
            ),
            const SizedBox(height: 24),

            // Banner de incentivo para agendar por la app (Sin emojis, usando Iconos vectoriales)
            Card(
              color: Colors.purple[50],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Beneficios de agendar por Florecer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(Icons.card_giftcard, size: 18, color: Colors.pinkAccent),
                        SizedBox(width: 8),
                        Expanded(child: Text('+20 puntos para tu nivel de bienestar al completar la cita.')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.analytics_outlined, size: 18, color: Colors.purple),
                        SizedBox(width: 8),
                        Expanded(child: Text('Tu reporte de síntomas se comparte de forma segura antes de la consulta.')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.verified_outlined, size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Expanded(child: Text('Desbloquea la opción de dejar tu reseña y calificar la atención.')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de Agenciamiento / Contacto
            ElevatedButton.icon(
              onPressed: onContactar,
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text(
                'Agendar cita por Florecer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Sección de Reseñas y Comentarios
            const Text(
              'Reseñas de la comunidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildResenaItem(
              nombre: 'Valeria M.',
              estrellas: const [
                Icon(Icons.star, size: 14, color: Colors.amber),
                Icon(Icons.star, size: 14, color: Colors.amber),
                Icon(Icons.star, size: 14, color: Colors.amber),
                Icon(Icons.star, size: 14, color: Colors.amber),
                Icon(Icons.star, size: 14, color: Colors.amber),
              ],
              comentario: 'Excelente profesional, muy empática y me ayudó muchísimo a entender mi diagnóstico. La recomiendo totalmente.',
              fecha: 'Hace 2 semanas',
            ),
            const Divider(height: 24),
            _buildResenaItem(
              nombre: 'Camila R.',
              estrellas: const [
                Icon(Icons.star, size: 14, color: Colors.amber),
                Icon(Icons.star, size: 14, color: Colors.amber),
                Icon(Icons.star, size: 14, color: Colors.amber),
                Icon(Icons.star, size: 14, color: Colors.amber),
                Icon(Icons.star, size: 14, color: Colors.amber),
              ],
              comentario: 'La consulta por la app fue muy fluida y el reporte de síntomas previo facilitó todo. Maravillosa atención.',
              fecha: 'Hace 1 mes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResenaItem({required String nombre, required List<Widget> estrellas, required String comentario, required String fecha}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(fecha, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Row(children: estrellas),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, size: 12, color: Colors.green),
                  SizedBox(width: 2),
                  Text(
                    'Cita verificada',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(comentario, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
      ],
    );
  }
}
