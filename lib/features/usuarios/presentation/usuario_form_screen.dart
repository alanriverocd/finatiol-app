import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/usuario_model.dart';
import 'usuarios_provider.dart';

class UsuarioFormScreen extends ConsumerStatefulWidget {
  final Usuario? usuario;

  const UsuarioFormScreen({super.key, this.usuario});

  @override
  ConsumerState<UsuarioFormScreen> createState() =>
      _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends ConsumerState<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.usuario?.nombre ?? '');
    _usernameController =
        TextEditingController(text: widget.usuario?.username ?? '');
    _emailController =
        TextEditingController(text: widget.usuario?.email ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = UsuarioRequest(
      nombre: _nombreController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim().isNotEmpty
          ? _passwordController.text.trim()
          : null,
    );

    final notifier = ref.read(usuariosProvider.notifier);
    final success = _isEditing
        ? await notifier.actualizar(widget.usuario!.id, request)
        : await notifier.crear(request);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FinatiolAppBar(
        title: Text(_isEditing ? 'Editar usuario' : 'Nuevo usuario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario *',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico *',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  final emailRegex =
                      RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Nueva contraseña (dejar vacío para no cambiar)'
                      : 'Contraseña *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (!_isEditing &&
                      (v == null || v.trim().length < 6)) {
                    return 'Mínimo 6 caracteres';
                  }
                  if (_isEditing &&
                      v != null &&
                      v.trim().isNotEmpty &&
                      v.trim().length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_isEditing ? Icons.save_outlined : Icons.add),
                label: Text(_isEditing ? 'Guardar cambios' : 'Crear usuario'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
