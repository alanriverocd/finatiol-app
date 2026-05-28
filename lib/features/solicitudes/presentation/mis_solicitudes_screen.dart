import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/solicitud_producto_model.dart';
import 'solicitudes_provider.dart';

enum _SolicitudFilter {
  todas,
  pendiente,
  aprobada,
  rechazada,
}

class MisSolicitudesScreen extends ConsumerStatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  ConsumerState<MisSolicitudesScreen> createState() =>
      _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends ConsumerState<MisSolicitudesScreen> {
  _SolicitudFilter _selectedFilter = _SolicitudFilter.todas;

  List<SolicitudProducto> _applyFilter(List<SolicitudProducto> solicitudes) {
    switch (_selectedFilter) {
      case _SolicitudFilter.todas:
        return solicitudes;
      case _SolicitudFilter.pendiente:
        return solicitudes
            .where((s) => s.estado.toUpperCase() == 'PENDIENTE')
            .toList();
      case _SolicitudFilter.aprobada:
        return solicitudes
            .where((s) => s.estado.toUpperCase() == 'APROBADA')
            .toList();
      case _SolicitudFilter.rechazada:
        return solicitudes
            .where((s) => s.estado.toUpperCase() == 'RECHAZADA')
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitudesAsync = ref.watch(misSolicitudesProvider);

    return Scaffold(
      appBar: FinatiolAppBar(
        title: const Text('Mis solicitudes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(misSolicitudesProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(misSolicitudesProvider.future),
        child: solicitudesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: 'No se pudieron cargar tus solicitudes',
            onRetry: () => ref.invalidate(misSolicitudesProvider),
          ),
          data: (solicitudes) {
            if (solicitudes.isEmpty) {
              return const _EmptyState();
            }

            final filtradas = _applyFilter(solicitudes);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _FilterBar(
                  selected: _selectedFilter,
                  onChanged: (value) =>
                      setState(() => _selectedFilter = value),
                ),
                const SizedBox(height: 12),
                if (filtradas.isEmpty)
                  _NoResultsState(filter: _selectedFilter)
                else
                  ...filtradas.map(
                    (solicitud) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SolicitudCard(
                        solicitud: solicitud,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                _SolicitudDetalleScreen(solicitud: solicitud),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  const _SolicitudCard({required this.solicitud, required this.onTap});

  final SolicitudProducto solicitud;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusUpper = solicitud.estado.toUpperCase();
    final (chipColor, textColor, icon) = switch (statusUpper) {
      'APROBADA' => (const Color(0xFFEAF8EF), const Color(0xFF0E7A35), Icons.check_circle_outline),
      'RECHAZADA' => (const Color(0xFFFDECEC), const Color(0xFFB42318), Icons.cancel_outlined),
      _ => (const Color(0xFFEEF4FF), const Color(0xFF1D4ED8), Icons.hourglass_bottom_outlined),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      solicitud.producto,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: textColor),
                        const SizedBox(width: 6),
                        Text(
                          statusUpper,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Fecha: ${FormatUtils.dateTime(solicitud.fechaSolicitud)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                solicitud.comentario.trim().isEmpty
                    ? 'Sin comentario adicional.'
                    : solicitud.comentario,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Ver detalle'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _SolicitudFilter selected;
  final ValueChanged<_SolicitudFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _SolicitudFilter.values
          .map(
            (filter) => ChoiceChip(
              label: Text(_label(filter)),
              selected: selected == filter,
              onSelected: (_) => onChanged(filter),
            ),
          )
          .toList(),
    );
  }

  String _label(_SolicitudFilter filter) {
    switch (filter) {
      case _SolicitudFilter.todas:
        return 'Todas';
      case _SolicitudFilter.pendiente:
        return 'Pendiente';
      case _SolicitudFilter.aprobada:
        return 'Aprobada';
      case _SolicitudFilter.rechazada:
        return 'Rechazada';
    }
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.filter});

  final _SolicitudFilter filter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(Icons.filter_alt_off_outlined,
                size: 40, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            Text(
              'No hay solicitudes con estado ${_label(filter)}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _label(_SolicitudFilter value) {
    switch (value) {
      case _SolicitudFilter.todas:
        return 'todas';
      case _SolicitudFilter.pendiente:
        return 'pendiente';
      case _SolicitudFilter.aprobada:
        return 'aprobada';
      case _SolicitudFilter.rechazada:
        return 'rechazada';
    }
  }
}

class _SolicitudDetalleScreen extends StatelessWidget {
  const _SolicitudDetalleScreen({required this.solicitud});

  final SolicitudProducto solicitud;

  @override
  Widget build(BuildContext context) {
    final statusUpper = solicitud.estado.toUpperCase();

    return Scaffold(
      appBar: const FinatiolAppBar(
        title: Text('Detalle de solicitud'),
        includeHomeAction: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    solicitud.producto,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(label: 'Solicitud #${solicitud.id}'),
                      _MetaChip(label: 'Estado: $statusUpper'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MetaLine(
                    label: 'Fecha de registro',
                    value: FormatUtils.dateTime(solicitud.fechaSolicitud),
                  ),
                  const SizedBox(height: 8),
                  _MetaLine(
                    label: 'Usuario',
                    value: solicitud.username,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comentario',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    solicitud.comentario.trim().isEmpty
                        ? 'Sin comentario adicional.'
                        : solicitud.comentario,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFF7FAFF),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seguimiento',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text('Tu solicitud está en seguimiento comercial. Te contactaremos por correo o teléfono.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D4ED8),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 14),
        Text(
          'Aún no tienes solicitudes registradas.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Cuando confirmes un producto desde el checkout, aparecerá aquí con su estado.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}
