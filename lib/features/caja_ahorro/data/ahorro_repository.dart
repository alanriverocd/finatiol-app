import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/ahorro_model.dart';

class AhorroRepository {
  const AhorroRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _decodeEnvelope(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is List<int>) {
      final text = utf8.decode(raw, allowMalformed: true);
      return _decodeEnvelope(text);
    }
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    throw const FormatException('No fue posible decodificar la respuesta del servidor.');
  }

  dynamic _extractData(dynamic raw) {
    final envelope = _decodeEnvelope(raw);
    return envelope['data'];
  }

  Future<AhorroDashboard> getMiDashboard() async {
    final response = await _dio.get('${AppConstants.ahorrosEndpoint}/mi-dashboard');
    return AhorroDashboard.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ClienteAhorro> getMiPerfil() async {
    final response = await _dio.get('${AppConstants.ahorrosEndpoint}/mi-perfil');
    return ClienteAhorro.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ClienteAhorro>> getClientesAdmin() async {
    final response = await _dio.get('${AppConstants.ahorrosEndpoint}/admin/clientes');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => ClienteAhorro.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CuentaAhorro>> getCuentasAdmin() async {
    final response = await _dio.get('${AppConstants.ahorrosEndpoint}/admin/cuentas');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => CuentaAhorro.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClienteAhorro> crearClienteAdmin(ClienteAhorroRequest request) async {
    final response = await _dio.post(
      '${AppConstants.ahorrosEndpoint}/admin/clientes',
      data: request.toAdminPayload(),
    );
    return ClienteAhorro.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ClienteAhorro> actualizarClienteAdmin(int id, ClienteAhorroRequest request) async {
    final response = await _dio.put(
      '${AppConstants.ahorrosEndpoint}/admin/clientes/$id',
      data: request.toUpdatePayload(),
    );
    return ClienteAhorro.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CuentaAhorro> abrirCuentaAdmin({
    required int clienteId,
    double? montoInicial,
    String? referencia,
  }) async {
    final response = await _dio.post(
      '${AppConstants.ahorrosEndpoint}/admin/cuentas',
      data: {
        'clienteId': clienteId,
        if (montoInicial != null && montoInicial > 0) 'montoInicial': montoInicial,
        if (referencia != null && referencia.isNotEmpty) 'referencia': referencia,
      },
    );
    return CuentaAhorro.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CuentaAhorro> abrirCuenta() async {
    final response =
        await _dio.post('${AppConstants.ahorrosEndpoint}/abrir');
    return CuentaAhorro.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<List<CuentaAhorro>> getMisCuentas() async {
    final response =
        await _dio.get('${AppConstants.ahorrosEndpoint}/mis-cuentas');
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => CuentaAhorro.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CuentaAhorro> getCuentaById(int id) async {
    final response =
        await _dio.get('${AppConstants.ahorrosEndpoint}/cuenta/$id');
    return CuentaAhorro.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<MovimientoAhorro> depositar({
    required int cuentaId,
    required double monto,
    String? referencia,
  }) async {
    final response = await _dio.post(
      '${AppConstants.ahorrosEndpoint}/deposito',
      data: {
        'cuentaId': cuentaId,
        'monto': monto,
        if (referencia != null && referencia.isNotEmpty)
          'referencia': referencia,
      },
    );
    return MovimientoAhorro.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<MovimientoAhorro> retirar({
    required int cuentaId,
    required double monto,
    String? referencia,
  }) async {
    final response = await _dio.post(
      '${AppConstants.ahorrosEndpoint}/retiro',
      data: {
        'cuentaId': cuentaId,
        'monto': monto,
        if (referencia != null && referencia.isNotEmpty)
          'referencia': referencia,
      },
    );
    return MovimientoAhorro.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<List<MovimientoAhorro>> getMovimientos(int cuentaId) async {
    final response = await _dio
        .get('${AppConstants.ahorrosEndpoint}/movimientos/$cuentaId');
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => MovimientoAhorro.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SemanaAhorro>> getSemanas(int cuentaId, int anio) async {
    final response = await _dio.get(
      '${AppConstants.ahorrosEndpoint}/cuenta/$cuentaId/semanas',
      queryParameters: {'anio': anio},
      options: Options(responseType: ResponseType.bytes),
    );
    final List<dynamic> data = _extractData(response.data) as List<dynamic>;
    return data
        .map((e) => SemanaAhorro.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SemanaAhorro> registrarPago({
    required int cuentaId,
    required int anio,
    required int semana,
    required double monto,
  }) async {
    final response = await _dio.post(
      '${AppConstants.ahorrosEndpoint}/pago-semanal',
      data: {
        'cuentaId': cuentaId,
        'anio': anio,
        'numeroSemana': semana,
        'monto': monto,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return SemanaAhorro.fromJson(_extractData(response.data) as Map<String, dynamic>);
  }
}
