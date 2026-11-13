// Informacion agronomica por clase del modelo (pantalla de Resultado).
// Recomendaciones generales: deben validarse con un ingeniero agronomo y la etiqueta
// del producto (dosis, periodo de carencia). Rotar modos de accion (FRAC/IRAC).
class DiseaseInfo {
  final String scientific;
  final String type; // Enfermedad | Plaga | Sin problema
  final List<String> symptoms;
  final List<String> favorable; // condiciones que favorecen su aparicion
  final List<String> preventive;
  final List<String> chemical; // vacio = no requiere intervencion quimica

  const DiseaseInfo({
    required this.scientific,
    required this.type,
    required this.symptoms,
    required this.favorable,
    required this.preventive,
    required this.chemical,
  });

  static DiseaseInfo of(String label) => _info[label] ?? _info['sana']!;

  static const _info = <String, DiseaseInfo>{
    'mildiu': DiseaseInfo(
      scientific: 'Phytophthora infestans',
      type: 'Enfermedad (oomiceto)',
      symptoms: [
        'Manchas irregulares verde oscuro a marrón, de aspecto aceitoso, que avanzan rápido.',
        'Con humedad, borde de la mancha con vellosidad blanquecina en el envés.',
        'Lesiones marrones en tallos y pecíolos.',
        'Frutos con manchas marrones firmes y de superficie rugosa.',
      ],
      favorable: [
        'Humedad relativa alta (más de 90 %) y hojas mojadas varias horas.',
        'Temperaturas frescas, entre 10 y 25 °C.',
        'Noches frías con rocío o neblina.',
        'Riego por aspersión y follaje denso con poca ventilación.',
      ],
      preventive: [
        'Retirar y sacar del campo hojas y plantas afectadas.',
        'Mejorar la ventilación: poda de hojas bajeras y distanciamiento adecuado.',
        'Regar por goteo sin mojar el follaje.',
        'Protectantes a base de cobre en forma preventiva.',
      ],
      chemical: [
        'Fungicidas sistémicos o translaminares (p. ej. cimoxanil, metalaxil-M, dimetomorf, mandipropamid) junto a un protectante (mancozeb o clorotalonil).',
        'Rotar grupos de modo de acción (FRAC) para evitar resistencia.',
        'Respetar dosis y período de carencia de la etiqueta.',
      ],
    ),
    'oidio': DiseaseInfo(
      scientific: 'Oidium neolycopersici',
      type: 'Enfermedad (hongo)',
      symptoms: [
        'Polvo blanco grisáceo sobre las hojas.',
        'Manchas amarillas (cloróticas) que luego se necrosan.',
        'Hojas que se secan y enrollan; defoliación en ataques fuertes.',
      ],
      favorable: [
        'Ambiente seco con humedad relativa moderada (50–75 %).',
        'Temperaturas de 20 a 27 °C.',
        'No necesita agua libre en la hoja: es frecuente en zonas áridas como Majes.',
        'Poca ventilación y exceso de nitrógeno.',
      ],
      preventive: [
        'Azufre mojable o en polvo (evitar aplicar con más de 30 °C).',
        'Bicarbonato de potasio.',
        'Eliminar hojas muy afectadas y mejorar la ventilación.',
        'Fertilización balanceada, sin exceso de nitrógeno.',
      ],
      chemical: [
        'Triazoles (p. ej. tebuconazol, difenoconazol) o estrobilurinas (p. ej. azoxistrobina).',
        'Rotar grupos de modo de acción (FRAC).',
        'Respetar dosis y período de carencia de la etiqueta.',
      ],
    ),
    'mosca_blanca': DiseaseInfo(
      scientific: 'Bemisia tabaci',
      type: 'Plaga (insecto)',
      symptoms: [
        'Insectos blancos pequeños en el envés que vuelan al mover la planta.',
        'Melaza pegajosa y fumagina (hollín negro) sobre hojas y frutos.',
        'Amarillamiento y debilitamiento de la planta.',
        'Transmite virus: hojas enrolladas o con mosaico amarillo.',
      ],
      favorable: [
        'Clima cálido y seco (25–30 °C).',
        'Malezas hospederas y cultivos abandonados cerca.',
        'Exceso de nitrógeno (brotes tiernos).',
      ],
      preventive: [
        'Trampas amarillas pegajosas para monitoreo y captura.',
        'Eliminar malezas y restos de cultivo.',
        'Mallas antiinsecto en almácigos.',
        'Control biológico: Encarsia formosa, Eretmocerus, hongos Beauveria o Isaria.',
        'Jabón potásico o aceites, aplicados al envés.',
      ],
      chemical: [
        'Insecticidas específicos (p. ej. piriproxifen, spirotetramat, acetamiprid) dirigidos al envés.',
        'Rotar grupos de modo de acción (IRAC).',
        'Respetar dosis y período de carencia de la etiqueta.',
      ],
    ),
    'polilla': DiseaseInfo(
      scientific: 'Tuta absoluta',
      type: 'Plaga (insecto)',
      symptoms: [
        'Minas o galerías translúcidas en las hojas, con excremento negro dentro.',
        'Hojas minadas que se secan.',
        'Perforaciones y galerías en frutos, brotes y tallos.',
      ],
      favorable: [
        'Temperaturas cálidas: varias generaciones por campaña.',
        'Restos de cultivo y campos abandonados cerca.',
        'Siembra continua de tomate sin descanso del campo.',
      ],
      preventive: [
        'Trampas de feromona para monitoreo y captura masiva.',
        'Retirar y destruir hojas y frutos minados.',
        'Bacillus thuringiensis al inicio del daño.',
        'Enemigos naturales (Trichogramma, Nesidiocoris tenuis).',
        'Rotación de cultivos y descanso entre campañas.',
      ],
      chemical: [
        'Insecticidas específicos (p. ej. clorantraniliprol, spinosad, benzoato de emamectina) al aparecer las primeras minas.',
        'Rotar grupos de modo de acción (IRAC).',
        'Respetar dosis y período de carencia de la etiqueta.',
      ],
    ),
    'sana': DiseaseInfo(
      scientific: '',
      type: 'Sin problema',
      symptoms: [
        'No se observan síntomas de enfermedad ni plagas en la imagen.',
      ],
      favorable: [],
      preventive: [
        'Monitoreo semanal de hojas (haz y envés).',
        'Riego y fertilización balanceados.',
        'Eliminar malezas y restos de cultivo.',
        'Trampas amarillas y de feromona para detectar plagas a tiempo.',
      ],
      chemical: [],
    ),
  };
}
