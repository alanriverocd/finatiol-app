class SolicitudProducto {
  const SolicitudProducto({
    required this.id,
    required this.username,
    required this.producto,
    required this.estado,
    required this.comentario,
    required this.fechaSolicitud,
  });

  final int id;
  final String username;
  final String producto;
  final String estado;
  final String comentario;
  final DateTime fechaSolicitud;

  factory SolicitudProducto.fromJson(Map<String, dynamic> json) {
    final fecha = json['fechaSolicitud'];
    return SolicitudProducto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ?? '',
      producto: (json['producto'] as String?) ?? '',
      estado: (json['estado'] as String?) ?? '',
      comentario: (json['comentario'] as String?) ?? '',
      fechaSolicitud: fecha is String
          ? DateTime.tryParse(fecha) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
