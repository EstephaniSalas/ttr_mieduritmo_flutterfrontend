import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/usuario.dart';
import '../theme/app_colors.dart';

// Pantallas
import 'inicio_screen.dart';
import 'horario_screen.dart';

class HomeShellScreen extends StatefulWidget {
  final Usuario usuario;
  final Dio dio;

  const HomeShellScreen({
    super.key,
    required this.usuario,
    required this.dio,
  });

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0; // 0: Inicio, 1: Horario, 2.. placeholders

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // OJO: aquí cambiamos a `usuario:`
      InicioScreen(usuario: widget.usuario),
      HorarioScreen(
        usuario: widget.usuario,
        dio: widget.dio, // mismo Dio con la cookie del login
      ),
      const _PlaceholderScreen(titulo: 'Tareas'),
      const _PlaceholderScreen(titulo: 'Notas'),
      const _PlaceholderScreen(titulo: 'Estudio'),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Horario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            label: 'Tareas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sticky_note_2_outlined),
            label: 'Notas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Estudio',
          ),
        ],
      ),
    );
  }
}

// Pantallas dummy para Tareas / Notas / Estudio.
class _PlaceholderScreen extends StatelessWidget {
  final String titulo;

  const _PlaceholderScreen({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: Center(
        child: Text('Pantalla de $titulo (por implementar)'),
      ),
    );
  }
}
