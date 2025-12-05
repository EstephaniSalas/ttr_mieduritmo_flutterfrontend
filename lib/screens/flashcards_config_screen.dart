// lib/screens/flashcards_config_screen.dart
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/materia.dart';
import '../models/flashcard.dart';
import '../services/usuario_api_service.dart';
import '../services/flashcard_api_service.dart';

import '../theme/app_colors.dart';
import 'flashcards_review_screen.dart';

class FlashcardsConfigScreen extends StatefulWidget {
  final Usuario usuario;
  final Materia materia;
  final UsuarioApiService api;

  const FlashcardsConfigScreen({
    super.key,
    required this.usuario,
    required this.materia,
    required this.api,
  });

  @override
  State<FlashcardsConfigScreen> createState() => _FlashcardsConfigScreenState();
}

class _FlashcardsConfigScreenState extends State<FlashcardsConfigScreen> {
  late final FlashcardsService _flashcardsService;

  bool _cargando = false;
  String? _error;
  List<Flashcard> _flashcards = [];

  @override
  void initState() {
    super.initState();
    _flashcardsService = FlashcardsService(widget.api.dio);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarFlashcards());
  }

  Future<void> _cargarFlashcards() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista = await _flashcardsService.obtenerFlashcardsPorMateria(
        userId: widget.usuario.uid,
        materiaId: widget.materia.id,
      );
      setState(() {
        _flashcards = lista;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _agregarFlashcard() async {
    final delanteController = TextEditingController();
    final reversoController = TextEditingController();

    String? errorPregunta;
    String? errorRespuesta;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nueva flashcard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: delanteController,
                    decoration: InputDecoration(
                      labelText: 'Pregunta / Concepto (cara delantera)',
                      border: const OutlineInputBorder(),
                      errorText: errorPregunta,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reversoController,
                    decoration: InputDecoration(
                      labelText: 'Respuesta / Definición (cara trasera)',
                      border: const OutlineInputBorder(),
                      errorText: errorRespuesta,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        final delante = delanteController.text.trim();
                        final reverso = reversoController.text.trim();

                        setModalState(() {
                          errorPregunta = null;
                          errorRespuesta = null;
                        });

                        bool hayError = false;
                        if (delante.isEmpty) {
                          hayError = true;
                          setModalState(() {
                            errorPregunta =
                                'La pregunta/concepto es obligatoria';
                          });
                        }
                        if (reverso.isEmpty) {
                          hayError = true;
                          setModalState(() {
                            errorRespuesta =
                                'La respuesta/definición es obligatoria';
                          });
                        }

                        if (hayError) return;

                        Navigator.of(ctx).pop(true);
                      },
                      child: const Text('Guardar flashcard'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    try {
      final nueva = await _flashcardsService.crearFlashcard(
        userId: widget.usuario.uid,
        materiaId: widget.materia.id,
        delante: delanteController.text.trim(),
        reverso: reversoController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _flashcards.add(nueva);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashcard creada correctamente'),
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

  Future<void> _editarFlashcard(Flashcard f) async {
    final delanteController = TextEditingController(text: f.delanteFlashcard);
    final reversoController = TextEditingController(text: f.reversoFlashcard);

    String? errorGeneral;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editar flashcard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: delanteController,
                    decoration: const InputDecoration(
                      labelText: 'Pregunta / Concepto (cara delantera)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reversoController,
                    decoration: const InputDecoration(
                      labelText: 'Respuesta / Definición (cara trasera)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  if (errorGeneral != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorGeneral!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        final delante = delanteController.text.trim();
                        final reverso = reversoController.text.trim();

                        if (delante == f.delanteFlashcard &&
                            reverso == f.reversoFlashcard) {
                          setModalState(() {
                            errorGeneral =
                                'Realiza al menos un cambio antes de guardar.';
                          });
                          return;
                        }

                        if (delante.isEmpty && reverso.isEmpty) {
                          setModalState(() {
                            errorGeneral =
                                'Debes modificar la pregunta, la respuesta o ambas.';
                          });
                          return;
                        }

                        Navigator.of(ctx).pop(true);
                      },
                      child: const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    try {
      final actualizado = await _flashcardsService.actualizarFlashcard(
        userId: widget.usuario.uid,
        flashcardId: f.id,
        delante: delanteController.text.trim(),
        reverso: reversoController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        final idx = _flashcards.indexWhere((x) => x.id == f.id);
        if (idx != -1) {
          _flashcards[idx] = actualizado;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashcard actualizada correctamente'),
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

  Future<void> _confirmarEliminarFlashcard(Flashcard f) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar flashcard'),
          content: const Text(
            '¿Seguro que quieres eliminar esta flashcard?\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _flashcardsService.eliminarFlashcard(
        userId: widget.usuario.uid,
        flashcardId: f.id,
      );

      if (!mounted) return;
      setState(() {
        _flashcards.removeWhere((x) => x.id == f.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashcard eliminada'),
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

  Future<void> _confirmarEliminarTodasMateria() async {
    if (_flashcards.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar todas las flashcards de la materia'),
          content: const Text(
            'Se borrarán TODAS las flashcards de esta materia.\n\n'
            'Esta acción es permanente.\n'
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

    if (confirmar != true) return;

    try {
      await _flashcardsService.eliminarFlashcardsPorMateria(
        userId: widget.usuario.uid,
        materiaId: widget.materia.id,
      );

      if (!mounted) return;
      setState(() {
        _flashcards.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se eliminaron todas las flashcards de la materia'),
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

  @override
  Widget build(BuildContext context) {
    final materiaNombre = widget.materia.nombre;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          materiaNombre,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Image(
                image: AssetImage('assets/images/MiEduRitmo_Negro.png'),
                height: 28,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  if (_flashcards.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Primero crea al menos una flashcard para esta materia.'),
                        backgroundColor: AppColors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FlashcardsReviewScreen(
                        usuario: widget.usuario,
                        materia: widget.materia,
                        flashcards: _flashcards,
                        api: widget.api, 
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Iniciar repaso',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Flashcards',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  color: Colors.red,
                  tooltip: 'Borrar todas las flashcards de esta materia',
                  onPressed: _flashcards.isEmpty
                      ? null
                      : _confirmarEliminarTodasMateria,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: Colors.blue,
                  tooltip: 'Agregar flashcard',
                  onPressed: _agregarFlashcard,
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

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_flashcards.isEmpty) {
      return const Center(
        child: Text(
          'No hay flashcards registradas para esta materia.\nPulsa + para crear una.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _flashcards.length,
      itemBuilder: (context, index) {
        final f = _flashcards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildFlashcardRow(f, index + 1),
        );
      },
    );
  }

  Widget _buildFlashcardRow(Flashcard f, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _editarFlashcard(f),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDEFF3),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                index.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                f.delanteFlashcard,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminarFlashcard(f),
            ),
          ],
        ),
      ),
    );
  }
}
