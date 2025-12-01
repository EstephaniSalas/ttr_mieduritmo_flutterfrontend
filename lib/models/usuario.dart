class Usuario {
  final String uid;
  final String nombre;
  final String correo;
  final bool estado;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.estado,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      uid: json['uid'] ?? json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      estado: json['estado'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nombre': nombre,
      'correo': correo,
      'estado': estado,
    };
  }
}
