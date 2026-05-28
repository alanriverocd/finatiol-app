import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';

class ProductCheckoutScreen extends ConsumerStatefulWidget {
  const ProductCheckoutScreen({super.key, this.producto});

  final String? producto;

  @override
  ConsumerState<ProductCheckoutScreen> createState() =>
      _ProductCheckoutScreenState();
}

class _ProductCheckoutScreenState extends ConsumerState<ProductCheckoutScreen> {
  bool _sending = false;
  bool _sent = false;
  String? _error;

  Future<void> _confirmSolicitud(String selectedProduct) async {
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ref.read(dioProvider).post(
            AppConstants.solicitudesEndpoint,
            data: {
              'producto': selectedProduct,
              'comentario': 'Solicitud generada desde escaparate comercial',
            },
          );

      if (!mounted) return;
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud enviada para $selectedProduct')),
      );
    } on DioException catch (e) {
      String message = 'No se pudo enviar la solicitud';
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final candidate = data['message'] ?? data['mensaje'] ?? data['error'];
        if (candidate != null && candidate.toString().trim().isNotEmpty) {
          message = candidate.toString();
        }
      }

      if (!mounted) return;
      setState(() => _error = message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error inesperado al enviar solicitud');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedProduct = (widget.producto ?? '').trim();

    return Scaffold(
      appBar: const FinatiolAppBar(
        title: Text('Solicitud de producto'),
        includeHomeAction: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FB), Color(0xFFEAF0F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF103D7A), Color(0xFF2A79D8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checkout FINATIOL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        selectedProduct.isEmpty
                            ? 'No seleccionaste un producto aún'
                            : selectedProduct,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedProduct.isEmpty
                            ? 'Explora el escaparate para elegir una opción y continuar con tu contratación.'
                            : 'Confirma tu interés y un asesor de FINATIOL te dará seguimiento.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Qué sigue?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF103D7A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _StepRow(
                        index: '1',
                        text: 'Tu solicitud queda registrada con tu sesión actual.',
                      ),
                      const SizedBox(height: 8),
                      const _StepRow(
                        index: '2',
                        text: 'Recibirás un contacto comercial por correo.',
                      ),
                      const SizedBox(height: 8),
                      const _StepRow(
                        index: '3',
                        text: 'Se valida documentación y se formaliza contratación.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: selectedProduct.isEmpty || _sending || _sent
                    ? null
                    : () => _confirmSolicitud(selectedProduct),
                icon: const Icon(Icons.check_circle_outline),
                label: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_sent ? 'Solicitud confirmada' : 'Confirmar solicitud'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_sent) ...[
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/mis-solicitudes'),
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: const Text('Ver mis solicitudes'),
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.go('/escaparate'),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Ver más productos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF103D7A),
            shape: BoxShape.circle,
          ),
          child: Text(
            index,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }
}
