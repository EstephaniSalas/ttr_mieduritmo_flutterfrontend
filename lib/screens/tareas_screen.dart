// lib/screens/tareas_screen.dart
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/materia.dart';
import '../models/tarea.dart';
import '../services/tareas_api_service.dart';
import '../services/materia_api_service.dart';
import '../services/usuario_api_service.dart';
import '../theme/app_colors.dart';
import 'add_tarea_sheet.dart';

import '../widgets/main_app_bar.dart';
import '../services/notification_service.dart';

class TareasScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioApiService api; //TOKEN

  const TareasScreen({
    super.key,
    required this.usuario,
    required this.api, //TOKEN
  });

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  late final TareasService _tareasService;
  late final MateriasService _materiasService;
  late final NotificationService _notificationService;

  late Usuario _usuario;

  List<Materia> _materias = [];

  bool _cargando = false;
  String? _error;
  List<Tarea> _tareas = [];

  // 0 = Tareas, 1 = Proyectos, 2 = Exámenes, 3 = Completado
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tareasService = TareasService(widget.api.dio); //TOKEN
    _materiasService = MateriasService(widget.api.dio);
    _notificationService = NotificationService(); 
    _usuario = widget.usuario; 
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarTareas());
  }

  Future<void> _cargarTareas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      var tareas =
          await _tareasService.obtenerTareasUsuario(widget.usuario.uid);
      tareas = await _actualizarVencidasSiAplica(tareas);

      // materias del usuario
      final materias =
          await _materiasService.getMateriasUsuario(widget.usuario.uid);

      setState(() {
        _tareas = tareas;
        _materias = materias;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  // Cambiar status Pendiente <-> Completada
  Future<void> _completarTarea(Tarea tarea) async {
    final nuevoEstatus =
        tarea.estatusTarea == 'Completada' ? 'Pendiente' : 'Completada';

    try {
      final actualizada = await _tareasService.cambiarEstatusTarea(
        userId: widget.usuario.uid,
        tareaId: tarea.id,
        estatusTarea: nuevoEstatus, // <- OJO: sin comillas
      );

      if (!mounted) return;

      setState(() {
        final idx = _tareas.indexWhere((t) => t.id == tarea.id);
        if (idx != -1) {
          _tareas[idx] = actualizada;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea actualizada'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<List<Tarea>> _actualizarVencidasSiAplica(List<Tarea> tareas) async {
    final ahora = DateTime.now();
    final List<Tarea> resultado = List.of(tareas);

    for (var i = 0; i < resultado.length; i++) {
      final t = resultado[i];

      if (t.estatusTarea != 'Pendiente') continue;
      if (!_estaVencida(t, ahora)) continue;

      try {
        final actualizada = await _tareasService.cambiarEstatusTarea(
          userId: widget.usuario.uid,
          tareaId: t.id,
          estatusTarea: 'Vencida',
        );
        resultado[i] = actualizada;
      } catch (_) {
        // si falla el PATCH, la dejamos como estaba
      }
    }

    resultado.sort((a, b) {
      final fa = a.fechaEntregaTarea;
      final fb = b.fechaEntregaTarea;
      final c = fa.compareTo(fb);
      if (c != 0) return c;
      return a.horaEntregaTarea.compareTo(b.horaEntregaTarea);
    });

    return resultado;
  }

  bool _estaVencida(Tarea t, DateTime ref) {
    final f = t.fechaEntregaTarea;
    final partes = t.horaEntregaTarea.split(':');
    final h = int.tryParse(partes.elementAt(0)) ?? 0;
    final m = int.tryParse(partes.elementAt(1)) ?? 0;

    final deadline = DateTime(f.year, f.month, f.day, h, m);
    return deadline.isBefore(ref);
  }

  // Filtro por pestaña
  List<Tarea> _filtrarPorTab() {
    if (_tabIndex == 3) {
      // Completado: todo lo que NO esté pendiente
      return _tareas
          .where((t) =>
              t.estatusTarea == 'Completada' || t.estatusTarea == 'Vencida')
          .toList();
    }

    const tipos = ['Tarea', 'Proyecto', 'Examen'];
    final tipo = tipos[_tabIndex];

    // Tareas, Proyectos, Exámenes: solo pendientes
    return _tareas
        .where((t) => t.tipoTarea == tipo && t.estatusTarea == 'Pendiente')
        .toList();
  }

  // Prioridad: entrega en los próximos 7 días
  Map<String, List<Tarea>> _splitPrioridad(List<Tarea> lista) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final limite = hoy.add(const Duration(days: 7));

    final prioridad = <Tarea>[];
    final otras = <Tarea>[];

    for (final t in lista) {
      final f = t.fechaEntregaTarea;
      final soloFecha = DateTime(f.year, f.month, f.day);

      if (soloFecha.isBefore(hoy) || soloFecha.isAfter(limite)) {
        otras.add(t);
      } else {
        prioridad.add(t);
      }
    }

    return {
      'prioridad': prioridad,
      'otras': otras,
    };
  }

  Future<void> _abrirAddTareaSheet() async {
  final nueva = await showModalBottomSheet<Tarea?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AddTareaSheet(
          tareaInicial: null,
          materias: _materias,
          onSubmit: (payload) async {
            final tarea = await _tareasService.crearTarea(
              userId: widget.usuario.uid,
              nombreTarea: payload.nombreTarea,
              materiaId: payload.materiaId,
              descripcionTarea: payload.descripcionTarea,
              tipoTarea: payload.tipoTarea,
              fechaEntrega: payload.fechaEntrega,
              horaEntrega24: payload.horaEntrega24,
            );
            
            // 🔔 NUEVO: Programar notificaciones
            final fechaHoraCompleta = DateTime(
              payload.fechaEntrega.year,
              payload.fechaEntrega.month,
              payload.fechaEntrega.day,
              int.parse(payload.horaEntrega24.split(':')[0]),
              int.parse(payload.horaEntrega24.split(':')[1]),
            );
            
            await _notificationService.programarNotificacionesTarea(
              tareaId: tarea.id,
              nombreTarea: tarea.nombreTarea,
              descripcion: tarea.descripcionTarea,
              fechaHoraEntrega: fechaHoraCompleta,
              tipoTarea: tarea.tipoTarea,
            );
            
            return tarea;
          },
        ),
      );
    },
  );

  if (!mounted) return;

  if (nueva != null) {
    setState(() {
      _tareas.add(nueva);
      _tareas.sort((a, b) {
        final fa = a.fechaEntregaTarea;
        final fb = b.fechaEntregaTarea;
        final c = fa.compareTo(fb);
        if (c != 0) return c;
        return a.horaEntregaTarea.compareTo(b.horaEntregaTarea);
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarea creada con notificaciones programadas ✅'),
        backgroundColor: AppColors.green,
      ),
    );
  }
}


 Future<void> _abrirEditarTareaSheet(Tarea tarea) async {
  final result = await showModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AddTareaSheet(
          tareaInicial: tarea,
          materias: _materias,
          onSubmit: (payload) async {
            final actualizada = await _tareasService.actualizarTarea(
              userId: widget.usuario.uid,
              tareaId: tarea.id,
              nombreTarea: payload.nombreTarea,
              materiaId: payload.materiaId,
              descripcionTarea: payload.descripcionTarea,
              tipoTarea: payload.tipoTarea,
              fechaEntrega: payload.fechaEntrega,
              horaEntrega24: payload.horaEntrega24,
            );
            
            // 🔔 NUEVO: RE-programar notificaciones
            final fechaHoraCompleta = DateTime(
              payload.fechaEntrega.year,
              payload.fechaEntrega.month,
              payload.fechaEntrega.day,
              int.parse(payload.horaEntrega24.split(':')[0]),
              int.parse(payload.horaEntrega24.split(':')[1]),
            );
            
            await _notificationService.programarNotificacionesTarea(
              tareaId: actualizada.id,
              nombreTarea: actualizada.nombreTarea,
              descripcion: actualizada.descripcionTarea,
              fechaHoraEntrega: fechaHoraCompleta,
              tipoTarea: actualizada.tipoTarea,
            );
            
            return actualizada;
          },
          onDelete: () async {
            // 🔔 NUEVO: Cancelar notificaciones antes de borrar
            await _notificationService.cancelarNotificacionesTarea(tarea.id);
            
            await _tareasService.eliminarTarea(
              userId: widget.usuario.uid,
              tareaId: tarea.id,
            );
          },
        ),
      );
    },
  );

  if (!mounted) return;

  if (result is Tarea) {
    setState(() {
      final idx = _tareas.indexWhere((t) => t.id == result.id);
      if (idx != -1) {
        _tareas[idx] = result;
      }
      _tareas.sort((a, b) {
        final fa = a.fechaEntregaTarea;
        final fb = b.fechaEntregaTarea;
        final c = fa.compareTo(fb);
        if (c != 0) return c;
        return a.horaEntregaTarea.compareTo(b.horaEntregaTarea);
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarea actualizada con notificaciones ✅'),
        backgroundColor: AppColors.green,
      ),
    );
  } else if (result == 'deleted') {
    setState(() {
      _tareas.removeWhere((t) => t.id == tarea.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarea y notificaciones eliminadas ✅'),
        backgroundColor: AppColors.green,
      ),
    );
  } else {
    await _cargarTareas();
  }
}

  Future<void> _confirmarBorrarTodas() async {
  if (_tareas.isEmpty) return;

  final confirmada = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Eliminar todas las tareas'),
        content: const Text(
          'Se borrarán TODAS las tareas de tu lista.\n\n'
          'Esta acción es permanente y dejará la sección de tareas vacía.\n'
          '¿Quieres continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar todo',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );

  if (confirmada != true) return;

  try {
    // 🔔 NUEVO: Cancelar notificaciones de todas las tareas
    for (var tarea in _tareas) {
      await _notificationService.cancelarNotificacionesTarea(tarea.id);
    }
    
    await _tareasService.eliminarTodasTareas(
      userId: widget.usuario.uid,
    );

    if (!mounted) return;
    setState(() {
      _tareas.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tareas y notificaciones eliminadas ✅'),
        backgroundColor: AppColors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.red,
      ),
    );
  }
}

  String _tituloPorTab() {
    switch (_tabIndex) {
      case 0:
        return 'Tareas';
      case 1:
        return 'Proyectos';
      case 2:
        return 'Exámenes';
      case 3:
        return 'Completado';
      default:
        return 'Tareas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tituloSeccion = _tituloPorTab();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: MainAppBar(
        usuario: _usuario,
        api: widget.api,
        subtitle: "¿Terminaste los pendientes?",
        onUsuarioActualizado: (nuevoUsuario) {
          setState(() {
            _usuario = nuevoUsuario;   // ← refresca el nombre en el header
          });
        },
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildTabs(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tituloSeccion,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  color: Colors.red,
                  tooltip: 'Borrar todas las tareas',
                  onPressed: _tareas.isEmpty ? null : _confirmarBorrarTodas,
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _abrirAddTareaSheet,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0066FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildContenido(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final labels = ['Tareas', 'Proyectos', 'Exámenes', 'Completado'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = _tabIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labels[index]),
                selected: selected,
                selectedColor: AppColors.black,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: const Color(0xFFEDEFF3),
                onSelected: (_) {
                  setState(() {
                    _tabIndex = index;
                  });
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final listaTab = _filtrarPorTab();
    if (listaTab.isEmpty) {
      return const Center(
        child: Text(
          'No hay tareas registradas en esta sección',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    if (_tabIndex == 3) {
      // Completado: separamos Completadas y Vencidas
      final completadas =
          listaTab.where((t) => t.estatusTarea == 'Completada').toList();
      final vencidas =
          listaTab.where((t) => t.estatusTarea == 'Vencida').toList();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (completadas.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 8),
                ...completadas
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildCardTarea(t, permitirCheck: true),
                        ))
                    .toList(),
              ],
              if (vencidas.isNotEmpty) ...[
                if (completadas.isNotEmpty) const SizedBox(height: 16),
                const Text(
                  'Vencidas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 8),
                ...vencidas
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildCardTarea(t, permitirCheck: false),
                        ))
                    .toList(),
              ],
            ],
          ),
        ),
      );
    }

    // Estas funciones internas no afectan el error, las dejo como están
    Widget _buildInteractiveCheckLocal(Tarea tarea) {
      final isCompleted = tarea.estatusTarea == 'Completada';

      return InkWell(
        onTap: () => _completarTarea(tarea),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCompleted ? AppColors.green : Colors.grey.shade400,
              width: 2,
            ),
            color:
                isCompleted ? AppColors.green.withOpacity(0.1) : Colors.white,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.green,
                  )
                : null,
          ),
        ),
      );
    }

    Widget _buildStatusBoxLocal(Tarea tarea) {
      IconData iconData;
      Color iconColor;

      switch (tarea.estatusTarea) {
        case 'Completada':
          iconData = Icons.check;
          iconColor = AppColors.green;
          break;
        case 'Vencida':
          iconData = Icons.close; // tachita para vencida
          iconColor = AppColors.red;
          break;
        default:
          iconData = Icons.check_box_outline_blank;
          iconColor = Colors.grey;
      }

      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFFF1F2F6),
        ),
        child: Center(
          child: Icon(
            iconData,
            size: 18,
            color: iconColor,
          ),
        ),
      );
    }

    final split = _splitPrioridad(listaTab);
    final prioridad = split['prioridad']!;
    final otras = split['otras']!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prioridad.isNotEmpty) ...[
              const Text(
                'Prioridad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Divider(),
              const SizedBox(height: 8),
              ...prioridad
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCardTarea(t, permitirCheck: true),
                      ))
                  .toList(),
            ],
            if (otras.isNotEmpty) ...[
              if (prioridad.isNotEmpty) const SizedBox(height: 16),
              const Text(
                'Todas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Divider(),
              const SizedBox(height: 8),
              ...otras
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCardTarea(t, permitirCheck: true),
                      ))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardTarea(Tarea tarea, {bool permitirCheck = false}) {
    final color = _colorPorTipo(tarea.tipoTarea);
    final inicial = _inicialMateriaOTipo(tarea);
    final fechaStr = _formatearFecha(tarea.fechaEntregaTarea);
    final horaStr = tarea.horaEntregaTarea;
    final materiaNombre = tarea.materiaNombre ?? '';

    return GestureDetector(
      onTap: () => _abrirEditarTareaSheet(tarea),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pastilla con inicial
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Contenido principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fechaStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tarea.nombreTarea,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (materiaNombre.isNotEmpty)
                    Text(
                      materiaNombre,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    horaStr.isNotEmpty
                        ? 'Vence a las $horaStr'
                        : 'Sin hora de entrega',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (permitirCheck)
              _buildInteractiveCheck(tarea)
            else
              _buildStatusBox(tarea),
          ],
        ),
      ),
    );
  }

  // NUEVO: versión a nivel de clase de _buildInteractiveCheck
  Widget _buildInteractiveCheck(Tarea tarea) {
    final isCompleted = tarea.estatusTarea == 'Completada';

    return InkWell(
      onTap: () => _completarTarea(tarea),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCompleted ? AppColors.green : Colors.grey.shade400,
            width: 2,
          ),
          color: isCompleted ? AppColors.green.withOpacity(0.1) : Colors.white,
        ),
        child: Center(
          child: isCompleted
              ? const Icon(
                  Icons.check,
                  size: 18,
                  color: AppColors.green,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStatusBox(Tarea tarea) {
    IconData iconData;
    Color iconColor;

    switch (tarea.estatusTarea) {
      case 'Completada':
        iconData = Icons.check;
        iconColor = AppColors.green;
        break;
      case 'Vencida':
        iconData = Icons.close; // tachado para vencida
        iconColor = AppColors.red;
        break;
      default:
        iconData = Icons.check_box_outline_blank;
        iconColor = Colors.grey;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFF1F2F6),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }

  Color _colorPorTipo(String tipo) {
    switch (tipo) {
      case 'Proyecto':
        return AppColors.purple;
      case 'Examen':
        return AppColors.red;
      case 'Tarea':
      default:
        return AppColors.green;
    }
  }

  Color _colorPorEstatus(String estatus) {
    switch (estatus) {
      case 'Completada':
        return AppColors.green;
      case 'Vencida':
        return AppColors.red;
      case 'Pendiente':
      default:
        return AppColors.yellow;
    }
  }

  String _inicialMateriaOTipo(Tarea tarea) {
    if ((tarea.materiaNombre ?? '').isNotEmpty) {
      return tarea.materiaNombre!.substring(0, 1).toUpperCase();
    }
    if (tarea.tipoTarea.isNotEmpty) {
      return tarea.tipoTarea.substring(0, 1).toUpperCase();
    }
    return 'T';
  }

  String _formatearFecha(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final diaSemana = dias[fecha.weekday - 1];
    final mes = meses[fecha.month - 1];

    return '$diaSemana ${fecha.day} de $mes de ${fecha.year}';
  }
}
