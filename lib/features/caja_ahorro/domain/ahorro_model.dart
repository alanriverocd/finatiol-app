class CuentaAhorro {
  final int id;
  final String username;
  final double saldo;
  final String fechaApertura;
  final bool activa;

  const CuentaAhorro({
    required this.id,
    required this.username,
    required this.saldo,
    required this.fechaApertura,
    required this.activa,
  });

  factory CuentaAhorro.fromJson(Map<String, dynamic> json) => CuentaAhorro(
        id: json['id'] as int,
        username: json['username'] as String,
        saldo: (json['saldo'] as num).toDouble(),
        fechaApertura: json['fechaApertura'] as String,
        activa: json['activa'] as bool,
      );
}

class MovimientoAhorro {
  final int id;
  final int cuentaId;
  final String tipo;
  final double monto;
  final String fecha;
  final String? referencia;

  const MovimientoAhorro({
    required this.id,
    required this.cuentaId,
    required this.tipo,
    required this.monto,
    required this.fecha,
    this.referencia,
  });

  factory MovimientoAhorro.fromJson(Map<String, dynamic> json) =>
      MovimientoAhorro(
        id: json['id'] as int,
        cuentaId: json['cuentaId'] as int,
        tipo: json['tipo'] as String,
        monto: (json['monto'] as num).toDouble(),
        fecha: json['fecha'] as String,
        referencia: json['referencia'] as String?,
      );
}

class SemanaAhorro {
  final int numeroSemana;
  final String fechaInicio;
  final String fechaFin;
  final bool pagado;
  final double? monto;
  final String? fechaPago;

  const SemanaAhorro({
    required this.numeroSemana,
    required this.fechaInicio,
    required this.fechaFin,
    required this.pagado,
    this.monto,
    this.fechaPago,
  });

  factory SemanaAhorro.fromJson(Map<String, dynamic> json) => SemanaAhorro(
        numeroSemana: json['numeroSemana'] as int,
        fechaInicio: json['fechaInicio'] as String,
        fechaFin: json['fechaFin'] as String,
        pagado: json['pagado'] as bool,
        monto: json['monto'] != null ? (json['monto'] as num).toDouble() : null,
        fechaPago: json['fechaPago'] as String?,
      );
}

class ClienteAhorro {
  final int id;
  final String nombre;
  final String username;
  final String email;
  final String? telefono;
  final String? direccion;
  final String? fechaNacimiento;
  final String? fechaRegistro;
  final bool activo;
  final int cuentasActivas;
  final double saldoTotal;

  const ClienteAhorro({
    required this.id,
    required this.nombre,
    required this.username,
    required this.email,
    this.telefono,
    this.direccion,
    this.fechaNacimiento,
    this.fechaRegistro,
    required this.activo,
    required this.cuentasActivas,
    required this.saldoTotal,
  });

  factory ClienteAhorro.fromJson(Map<String, dynamic> json) => ClienteAhorro(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String? ?? '',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        telefono: json['telefono'] as String?,
        direccion: json['direccion'] as String?,
        fechaNacimiento: json['fechaNacimiento'] as String?,
        fechaRegistro: json['fechaRegistro'] as String?,
        activo: json['activo'] as bool? ?? true,
        cuentasActivas: (json['cuentasActivas'] as num?)?.toInt() ?? 0,
        saldoTotal: (json['saldoTotal'] as num?)?.toDouble() ?? 0,
      );
}

class ClienteAhorroRequest {
  final String nombre;
  final String username;
  final String email;
  final String? telefono;
  final String? direccion;
  final DateTime? fechaNacimiento;
  final String? password;
  final double? montoInicial;

  const ClienteAhorroRequest({
    required this.nombre,
    required this.username,
    required this.email,
    this.telefono,
    this.direccion,
    this.fechaNacimiento,
    this.password,
    this.montoInicial,
  });

  Map<String, dynamic> toAdminPayload({bool crearCuenta = true}) => {
        'cliente': {
          'nombre': nombre,
          'username': username,
          'email': email,
          if (telefono != null && telefono!.trim().isNotEmpty)
            'telefono': telefono,
          if (direccion != null && direccion!.trim().isNotEmpty)
            'direccion': direccion,
          if (fechaNacimiento != null)
            'fechaNacimiento': fechaNacimiento!.toIso8601String().split('T').first,
        },
        if (password != null && password!.trim().isNotEmpty) 'password': password,
        'crearCuenta': crearCuenta,
        if (montoInicial != null && montoInicial! > 0) 'montoInicial': montoInicial,
        if (crearCuenta) 'referenciaApertura': 'Apertura administrada desde el panel de ahorro',
      };

  Map<String, dynamic> toUpdatePayload() => {
        'nombre': nombre,
        'username': username,
        'email': email,
        if (telefono != null && telefono!.trim().isNotEmpty) 'telefono': telefono,
        if (direccion != null && direccion!.trim().isNotEmpty) 'direccion': direccion,
        if (fechaNacimiento != null)
          'fechaNacimiento': fechaNacimiento!.toIso8601String().split('T').first,
      };
}

class AhorroDashboard {
  final ClienteAhorro? cliente;
  final List<CuentaAhorro> cuentas;
  final List<MovimientoAhorro> movimientosRecientes;
  final List<SemanaAhorro> semanasPendientes;
  final double saldoTotal;

  const AhorroDashboard({
    required this.cliente,
    required this.cuentas,
    required this.movimientosRecientes,
    required this.semanasPendientes,
    required this.saldoTotal,
  });

  factory AhorroDashboard.fromJson(Map<String, dynamic> json) => AhorroDashboard(
        cliente: json['cliente'] != null
            ? ClienteAhorro.fromJson(json['cliente'] as Map<String, dynamic>)
            : null,
        cuentas: (json['cuentas'] as List<dynamic>? ?? const [])
            .map((e) => CuentaAhorro.fromJson(e as Map<String, dynamic>))
            .toList(),
        movimientosRecientes: (json['movimientosRecientes'] as List<dynamic>? ?? const [])
            .map((e) => MovimientoAhorro.fromJson(e as Map<String, dynamic>))
            .toList(),
        semanasPendientes: (json['semanasPendientes'] as List<dynamic>? ?? const [])
            .map((e) => SemanaAhorro.fromJson(e as Map<String, dynamic>))
            .toList(),
        saldoTotal: (json['saldoTotal'] as num?)?.toDouble() ?? 0,
      );
}

