const List<String> _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];
const List<String> _dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

String fechaCorta(DateTime f) => '${f.day} ${_meses[f.month - 1]} ${f.year}';

String diaCorto(DateTime f) => _dias[f.weekday - 1];

String kgTexto(double kg) => kg.toStringAsFixed(1);

/// Convierte "2,5" o "2.5" en 2.5. Devuelve null si no es un número.
double? parsearKg(String? texto) =>
    double.tryParse((texto ?? '').trim().replaceAll(',', '.'));
