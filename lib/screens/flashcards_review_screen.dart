// lib/screens/flashcards_review_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/materia.dart';
import '../models/flashcard.dart';
import '../theme/app_colors.dart';

import '../services/sesion_estudio_api_service.dart';
import '../services/usuario_api_service.dart';

class FlashcardsReviewScreen extends StatefulWidget {
  final Usuario usuario;
  final Materia materia;
  final List<Flashcard> flashcards;
  final UsuarioApiService api;

  const FlashcardsReviewScreen({
    super.key,
    required this.usuario,
    required this.materia,
    required this.flashcards,
    required this.api,
  });

  @override
  State<FlashcardsReviewScreen> createState() => _FlashcardsReviewScreenState();
}

class _FlashcardsReviewScreenState extends State<FlashcardsReviewScreen> {
  late int _currentIndex;
  bool _showFront = true; // true = pregunta, false = respuesta

  Timer? _timer;
  int _elapsedSeconds = 0;

  late final SesionEstudioApiService _sesionService;
  bool _guardandoSesion = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _sesionService = SesionEstudioApiService(widget.api.dio);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showFront = true;
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showFront = true;
      });
    }
  }

  void _toggleFace() {
    setState(() {
      _showFront = !_showFront;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _finalizarSesionYSalir() async {
    if (_guardandoSesion) return;

    _timer?.cancel();
    final segundos = _elapsedSeconds;

    // Si no se estudió nada, solo salimos
    if (segundos <= 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _guardandoSesion = true;
    });

    try {
      await _sesionService.registrarSesionEstudio(
        userId: widget.usuario.uid,
        materiaId: widget.materia.id,
        duracionSegundos: segundos,
        // Si no quieres mandar fecha explícita, simplemente quita este parámetro
        fechaSesion: DateTime.now(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión de estudio registrada'),
          backgroundColor: AppColors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar sesión: $e'),
          backgroundColor: AppColors.red,
        ),
      );

      // Aun así salimos de la pantalla
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _guardandoSesion = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.flashcards.length;
    final actual = _currentIndex + 1;
    final progress = total > 0 ? actual / total : 0.0;

    final current = widget.flashcards[_currentIndex];

    return WillPopScope(
      onWillPop: () async {
        await _finalizarSesionYSalir();
        return false; // manejamos el pop manualmente
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: _finalizarSesionYSalir,
          ),
          title: Text(
            widget.materia.nombre,
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
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progreso y tiempo
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(10),
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$actual/$total',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Zona central con tarjeta y “bordes” laterales
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 0,
                            child: Container(
                              width: 40,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: Container(
                              width: 40,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleFace,
                            child: Container(
                              width: 230,
                              height: 200,
                              decoration: BoxDecoration(
                                color: const Color(0xFF005DFF),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _showFront
                                        ? current.delanteFlashcard
                                        : current.reversoFlashcard,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Icon(
                                    Icons.touch_app,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botones de navegación + terminar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundNavButton(
                        icon: Icons.arrow_back,
                        enabled: _currentIndex > 0,
                        onTap: _prevCard,
                      ),
                      _RoundNavButton(
                        icon: Icons.arrow_forward,
                        enabled: _currentIndex < total - 1,
                        onTap: _nextCard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _finalizarSesionYSalir,
                      child: const Text(
                        'Terminar repaso',
                        style: TextStyle(fontWeight: FontWeight.w600),
                        selectionColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_guardandoSesion)
              Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundNavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RoundNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
