import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';

import '../domain/ahorro_model.dart';
import 'ahorro_provider.dart';

class ClienteAhorroFormScreen extends ConsumerStatefulWidget {
  const ClienteAhorroFormScreen({super.key, this.cliente});

  final ClienteAhorro? cliente;

  @override
  ConsumerState<ClienteAhorroFormScreen> createState() => _ClienteAhorroFormScreenState();
}

class _ClienteAhorroFormScreenState extends ConsumerState<ClienteAhorroFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _direccionController;
  late final TextEditingController _passwordController;
  late final TextEditingController _montoInicialController;

  DateTime? _fechaNacimiento;
  bool _guardando = false;
  bool _mostrarPassword = false;

  bool get _isEditing => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente?.nombre ?? '');
    _usernameController = TextEditingController(text: widget.cliente?.username ?? '');
    _emailController = TextEditingController(text: widget.cliente?.email ?? '');
    _telefonoController = TextEditingController(text: widget.cliente?.telefono ?? '');
    _direccionController = TextEditingController(text: widget.cliente?.direccion ?? '');
    _passwordController = TextEditingController();
    _montoInicialController = TextEditingController();
    final fecha = widget.cliente?.fechaNacimiento;
    if (fecha != null && fecha.isNotEmpty) {
      _fechaNacimiento = DateTime.tryParse(fecha);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _passwordController.dispose();
    _montoInicialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: FinatiolAppBar(
        title: Text(_isEditing ? 'Editar cliente' : 'Alta de cliente'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF103D7A), Color(0xFF1C6DD0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          color: Colors.white, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        _isEditing
                            ? 'Actualiza el expediente del cliente'
                            : 'Crea la cuenta digital del nuevo cliente',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Incluye datos de contacto, acceso al portal y apertura inicial de ahorro.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '* Campos obligatorios',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Identidad del cliente',
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _usernameController,
                      enabled: !_isEditing,
                      decoration: InputDecoration(
                        labelText:
                            _isEditing ? 'Usuario de acceso' : 'Usuario de acceso *',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo requerido';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Contacto y expediente',
                  children: [
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _direccionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        child: Text(
                          _fechaNacimiento == null
                              ? 'Seleccionar fecha'
                              : '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _isEditing ? 'Ajustes de perfil' : 'Acceso y apertura',
                  children: [
                    if (!_isEditing) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_mostrarPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña temporal *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
                            icon: Icon(_mostrarPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                          ),
                        ),
                        validator: (value) {
                          if (!_isEditing && (value == null || value.trim().length < 6)) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _montoInicialController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto inicial de apertura (opcional)',
                          prefixIcon: Icon(Icons.savings_outlined),
                          helperText:
                              'Si capturas un monto, se abonará al saldo inicial de la cuenta.',
                        ),
                      ),
                    ] else ...[
                      Text(
                        'El usuario de acceso no se modifica desde esta pantalla para mantener consistencia con autenticación.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _guardando ? null : _submit,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_isEditing ? Icons.save_outlined : Icons.person_add_alt_1),
                  label: Text(_isEditing ? 'Guardar cambios' : 'Crear cliente y cuenta'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo requerido';
    return null;
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final monto = double.tryParse(_montoInicialController.text.trim().replaceAll(',', ''));
    final request = ClienteAhorroRequest(
      nombre: _nombreController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
      fechaNacimiento: _fechaNacimiento,
      password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
      montoInicial: monto,
    );

    final notifier = ref.read(ahorroProvider.notifier);
    final success = _isEditing
        ? await notifier.actualizarCliente(widget.cliente!.id, request)
        : await notifier.crearCliente(request);

    if (!mounted) return;
    setState(() => _guardando = false);
    if (success) {
      Navigator.pop(context);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}