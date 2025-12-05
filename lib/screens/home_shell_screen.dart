import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_api_service.dart';
import 'inicio_screen.dart';
import 'horario_screen.dart';
import 'tareas_screen.dart';
import 'login_screen.dart';
import 'notas_screens.dart';


class HomeShellScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioApiService api;

  const HomeShellScreen({
    super.key,
    required this.usuario,
    required this.api,
  });

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) { //TOKEN
    final screens = [
      InicioScreen(
        usuario: widget.usuario,
        api: widget.api,
      ),
      HorarioScreen(
        usuario: widget.usuario,
        api: widget.api,
      ),
      TareasScreen(
        usuario: widget.usuario,
        api: widget.api,
      ),
      NotasScreen(usuario: widget.usuario, api: widget.api),
      //EstudioScreen(usuario: widget.usuario, api: widget.api),
    ];

    return Scaffold(
      drawer: _buildDrawer(context),
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: "Horario"),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tareas"),
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: "Notas"),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book), label: "Estudio"),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black87,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                widget.usuario.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Modificar mis datos"),
            onTap: () {
              // Futuro: abrir pantalla de edicion
            },
          ),

          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Cerrar sesión",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await widget.api.logout();

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(api: widget.api),
                ),
                (_) => false,
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
