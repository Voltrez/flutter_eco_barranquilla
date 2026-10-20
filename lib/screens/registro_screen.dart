import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/materiales.dart';
import '../models/material_reciclable.dart';
import '../models/registro_reciclaje.dart';
import '../state/reciclaje_state.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../utils/mensajes.dart';
import '../widgets/contenedor_info.dart';

/// PANTALLA 2: registro de información (formulario con validaciones).
class RegistroScreen extends StatefulWidget {
  final ValueChanged<int> onIrA;

  const RegistroScreen({super.key, required this.onIrA});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kgCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();

  MaterialReciclable? _material;
  double _objetos = 1;
  LugarEntrega _lugar = LugarEntrega.puntoReciclaje;
  bool _limpio = true;
  bool _confirmado = false;
  bool _errorConfirmacion = false;
  DateTime _fecha = DateUtils.dateOnly(DateTime.now());
  int _reinicios = 0; // fuerza a recrear el Dropdown al limpiar

  @override
  void dispose() {
    _kgCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: hoy.subtract(const Duration(days: 30)),
      lastDate: hoy,
      helpText: 'Fecha del reciclaje',
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  void _limpiar() {
    _formKey.currentState?.reset();
    _kgCtrl.clear();
    _notaCtrl.clear();
    setState(() {
      _material = null;
      _objetos = 1;
      _lugar = LugarEntrega.puntoReciclaje;
      _limpio = true;
      _confirmado = false;
      _errorConfirmacion = false;
      _fecha = DateUtils.dateOnly(DateTime.now());
      _reinicios++;
    });
  }

  Future<void> _guardar() async {
    final formularioValido = _formKey.currentState!.validate();
    setState(() => _errorConfirmacion = !_confirmado);

    if (!formularioValido || !_confirmado) {
      mostrarMensaje(
        context,
        'Revisa los campos marcados antes de guardar.',
        tipo: TipoMensaje.error,
      );
      return;
    }

    final kg = parsearKg(_kgCtrl.text)!;

    // Advertencia para pesos muy altos.
    if (kg > 50) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber,
              color: Color(0xFFEF6C00), size: 36),
          title: const Text('Peso elevado'),
          content: Text(
              'Vas a registrar ${kgTexto(kg)} kg en una sola entrega. ¿Es correcto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Corregir'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, guardar'),
            ),
          ],
        ),
      );
      if (continuar != true) return;
    }

    if (!mounted) return;

    final registro = estadoApp.registrar(
      material: _material!,
      kg: kg,
      objetos: _objetos.round(),
      lugar: _lugar,
      limpio: _limpio,
      fecha: _fecha,
      nota: _notaCtrl.text,
    );

    mostrarMensaje(
      context,
      '¡Registro guardado! Ganaste ${registro.puntos} puntos.',
      tipo: TipoMensaje.exito,
      accion: 'Ver historial',
      onAccion: () => widget.onIrA(2),
    );
    _limpiar();
  }

  Widget _vistaPrevia() {
    final kg = parsearKg(_kgCtrl.text);
    if (_material == null || kg == null || kg <= 0 || kg > 200) {
      return const SizedBox.shrink();
    }
    final puntos = ReciclajeState.calcularPuntos(
      _material!,
      kg,
      conReciclador: _lugar == LugarEntrega.reciclador,
      limpio: _limpio,
    );
    final co2 = ReciclajeState.calcularCo2(_material!, kg);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.amarillo, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vista previa: ganarás $puntos puntos y evitarás ≈ ${co2.toStringAsFixed(1)} kg de CO₂.',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.verdeOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.texto,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar reciclaje'),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1) DropdownButtonFormField
                DropdownButtonFormField<MaterialReciclable>(
                  key: ValueKey('material$_reinicios'),
                  value: _material,
                  isExpanded: true,
                  decoration: AppTheme.campo('Material reciclado', Icons.category),
                  items: catalogoMateriales
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Row(
                            children: [
                              Icon(m.icono, color: m.color, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(m.nombre,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (m) => setState(() => _material = m),
                  validator: (m) => m == null ? 'Selecciona un material' : null,
                ),
                if (_material != null) ...[
                  const SizedBox(height: 10),
                  ContenedorInfo(tipo: _material!.contenedor),
                ],
                const SizedBox(height: 16),

                // 2) TextFormField numérico
                TextFormField(
                  controller: _kgCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: AppTheme.campo(
                    'Peso aproximado (kg)',
                    Icons.scale,
                    ayuda: 'Ej: 2.5',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa el peso en kg';
                    }
                    final kg = parsearKg(v);
                    if (kg == null) return 'Escribe un número válido (ej: 2.5)';
                    if (kg <= 0) return 'El peso debe ser mayor que 0';
                    if (kg > 200) return 'El máximo por registro es 200 kg';
                    return null;
                  },
                ),

                // 3) Slider
                _titulo('Cantidad de objetos: ${_objetos.round()}'),
                Slider(
                  value: _objetos,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_objetos.round()}',
                  activeColor: AppColors.verde,
                  onChanged: (v) => setState(() => _objetos = v),
                ),

                // 4) SegmentedButton
                _titulo('¿A quién se lo entregaste?'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<LugarEntrega>(
                    showSelectedIcon: false,
                    segments: LugarEntrega.values
                        .map(
                          (l) => ButtonSegment(
                            value: l,
                            label: Text(l.etiquetaCorta),
                          ),
                        )
                        .toList(),
                    selected: {_lugar},
                    onSelectionChanged: (s) => setState(() => _lugar = s.first),
                  ),
                ),
                if (_lugar == LugarEntrega.reciclador)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      '¡Apoyar al reciclador de oficio da +20 % de puntos!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.verdeOscuro,
                      ),
                    ),
                  ),

                // 5) Switch
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.verde,
                  title: const Text('Material limpio y seco'),
                  subtitle: const Text('Da +10 % de puntos'),
                  value: _limpio,
                  onChanged: (v) => setState(() => _limpio = v),
                ),

                // 6) Selector de fecha
                OutlinedButton.icon(
                  onPressed: _elegirFecha,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('Fecha: ${fechaCorta(_fecha)}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: AppColors.verde,
                    side: const BorderSide(color: AppColors.verde),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 7) Nota opcional
                TextFormField(
                  controller: _notaCtrl,
                  maxLength: 80,
                  decoration: AppTheme.campo(
                    'Nota (opcional)',
                    Icons.edit_note,
                  ),
                ),

                // 8) Checkbox de confirmación
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.verde,
                  title: const Text('Confirmo que separé los residuos correctamente'),
                  value: _confirmado,
                  onChanged: (v) => setState(() {
                    _confirmado = v ?? false;
                    if (_confirmado) _errorConfirmacion = false;
                  }),
                ),
                if (_errorConfirmacion)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      'Debes confirmar para poder guardar',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),

                _vistaPrevia(),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar registro'),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _limpiar,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Limpiar formulario'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
