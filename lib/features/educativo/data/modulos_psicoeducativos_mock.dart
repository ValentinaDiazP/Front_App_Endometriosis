import '../models/modulo_psicoeducativo.dart';

/// Contenido SIMULADO de los módulos informativos guiados (Psicoeducación).
/// Texto de ejemplo, informativo y general: no diagnostica ni reemplaza la
/// atención profesional. El contenido definitivo debe ser revisado por una
/// persona del área de la salud antes de publicarse.
class ModulosPsicoeducativosMock {
  ModulosPsicoeducativosMock._();

  static ModuloPsicoeducativo? deEjercicio(String idEjercicio) =>
      _modulos[idEjercicio];

  static const _modulos = <String, ModuloPsicoeducativo>{
    'e1': ModuloPsicoeducativo(
      idEjercicio: 'e1',
      pasos: [
        PasoModulo(
          titulo: 'Tu dolor es real',
          parrafos: [
            'Cuando vives con endometriosis, el dolor no es "exageración" ni '
                'algo que esté solo en tu cabeza. Es una experiencia real, '
                'con causas físicas y también con otros factores que influyen.',
            'En este módulo vas a entender, paso a paso, qué puede estar '
                'pasando en tu cuerpo cuando duele. Entenderlo no hace que el '
                'dolor desaparezca, pero puede darte más calma y más control.',
          ],
          puntoClave: 'Tu dolor es real y merece ser tomado en serio.',
        ),
        PasoModulo(
          titulo: 'Dolor agudo y dolor crónico',
          parrafos: [
            'El dolor agudo es una alarma: aparece ante una lesión y se va '
                'cuando el cuerpo se recupera.',
            'El dolor crónico es el que dura meses. Con el tiempo, la alarma '
                'puede seguir sonando aunque no haya un daño nuevo, y por eso '
                'a veces cuesta entenderlo.',
          ],
          puntoClave: 'Un dolor que dura mucho tiempo funciona distinto a un '
              'dolor reciente.',
        ),
        PasoModulo(
          titulo: 'Un sistema nervioso más sensible',
          parrafos: [
            'Cuando el dolor se repite, el sistema nervioso puede volverse '
                'más sensible y reaccionar con más intensidad a estímulos que '
                'antes dolían menos. A esto se le llama sensibilización.',
            'No es una falla tuya: es una forma en que el cuerpo se adapta '
                'al dolor sostenido.',
          ],
          puntoClave: 'La sensibilidad aumentada es una adaptación del '
              'cuerpo, no una debilidad.',
        ),
        PasoModulo(
          titulo: 'Lo que puede amplificar el dolor',
          parrafos: [
            'El estrés, dormir poco, la preocupación constante y el miedo a '
                'que llegue el dolor pueden hacer que se sienta con más '
                'intensidad.',
            'Esto no significa que "te lo causes tú". Significa que el '
                'cuerpo y las emociones están conectados, y que hay cosas '
                'que sí puedes influir.',
          ],
          puntoClave: 'Estrés, sueño y emociones influyen en cómo se siente '
              'el dolor.',
        ),
        PasoModulo(
          titulo: 'Lo que sí puedes hacer',
          parrafos: [
            'Registrar tus síntomas, cuidar tus descansos, moverte con '
                'suavidad cuando puedas y practicar ejercicios de calma son '
                'pequeñas acciones que suman.',
            'En los siguientes ejercicios de la app aprenderás herramientas '
                'concretas. Y si el dolor te limita mucho, habla con tu '
                'profesional de salud.',
          ],
          puntoClave: 'Pequeñas acciones constantes ayudan, y no tienes que '
              'hacerlo sola.',
        ),
      ],
    ),
    'e5': ModuloPsicoeducativo(
      idEjercicio: 'e5',
      pasos: [
        PasoModulo(
          titulo: 'El círculo del dolor y el estrés',
          parrafos: [
            'Cuando duele, es normal sentir tensión y preocupación. Esa '
                'tensión puede aumentar la sensación de dolor, y más dolor '
                'genera más estrés. Así se forma un círculo.',
          ],
          puntoClave: 'Dolor y estrés pueden alimentarse entre sí.',
        ),
        PasoModulo(
          titulo: 'Cómo se siente en el ánimo',
          parrafos: [
            'Vivir con dolor frecuente cansa. Es habitual sentir tristeza, '
                'irritabilidad o desánimo en algunos días.',
            'Estas emociones no son un fallo personal: son una respuesta '
                'comprensible a una situación difícil.',
          ],
          puntoClave: 'Sentirte así es comprensible, no es un defecto tuyo.',
        ),
        PasoModulo(
          titulo: 'Dónde puedes cortar el círculo',
          parrafos: [
            'No se trata de eliminar el estrés por completo, sino de bajar '
                'un poco la intensidad: respirar con calma, hacer pausas, '
                'hablar con alguien de confianza.',
            'Cada pausa pequeña le da al cuerpo una señal de seguridad.',
          ],
          puntoClave: 'Pausas pequeñas también cuentan.',
        ),
        PasoModulo(
          titulo: 'Cuándo pedir ayuda',
          parrafos: [
            'Si notas que la tristeza o la ansiedad se vuelven constantes o '
                'te impiden hacer tu vida diaria, conviene hablarlo con un '
                'profesional de salud o de salud mental.',
            'Pedir ayuda es una forma de cuidarte.',
          ],
          puntoClave: 'Pedir ayuda es parte del autocuidado.',
        ),
      ],
    ),
    'e6': ModuloPsicoeducativo(
      idEjercicio: 'e6',
      pasos: [
        PasoModulo(
          titulo: 'Por qué importa el ritmo',
          parrafos: [
            'En los días buenos es tentador hacer todo de una vez. Pero '
                'pasarse puede traer un día de más dolor después. Y en los '
                'días malos, no hacer nada puede dejarte más rígida.',
          ],
          puntoClave: 'Ni todo de golpe ni nada: busca un punto medio.',
        ),
        PasoModulo(
          titulo: 'Dosificar tu energía',
          parrafos: [
            'Dosificar significa dividir las actividades en partes '
                'pequeñas y alternar con descansos antes de sentirte '
                'agotada, no después.',
          ],
          puntoClave: 'Descansar antes de agotarte ayuda a sostener el día.',
        ),
        PasoModulo(
          titulo: 'Escucha tu cuerpo, sin juzgarte',
          parrafos: [
            'Algunos días harás más y otros menos. Cambiar el plan no es '
                'fracasar: es adaptarte a cómo está tu cuerpo hoy.',
          ],
          puntoClave: 'Adaptar el plan no es fracasar.',
        ),
        PasoModulo(
          titulo: 'Tu primer paso',
          parrafos: [
            'Elige una actividad de tu día y piensa cómo dividirla en dos '
                'o tres partes con una pausa en medio.',
            'Puedes usar el seguimiento de la app para notar qué días te '
                'cuestan más y ajustar tu ritmo.',
          ],
          puntoClave: 'Empieza con una sola actividad y una pausa.',
        ),
      ],
    ),
  };
}
