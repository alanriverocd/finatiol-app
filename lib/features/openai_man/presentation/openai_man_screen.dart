import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

class OpenAiManScreen extends StatefulWidget {
  const OpenAiManScreen({super.key});

  @override
  State<OpenAiManScreen> createState() => _OpenAiManScreenState();
}

class _OpenAiManScreenState extends State<OpenAiManScreen> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechReady = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;

  String _recognized = '';
  String _assistantMessage =
      'OpenAI Man activo. Toca el microfono y habla para iniciar la conversacion.';

  @override
  void initState() {
    super.initState();
    _setupVoice();
  }

  Future<void> _setupVoice() async {
    final available = await _speech.initialize(
      onStatus: (status) async {
        if (!mounted) return;
        final listening = status == 'listening';
        if (_isListening != listening) {
          setState(() => _isListening = listening);
        }

        if (!listening && _recognized.trim().isNotEmpty && !_isThinking) {
          await _handlePrompt(_recognized.trim());
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _assistantMessage =
              'No pude activar el microfono. Verifica permisos e intenta de nuevo.';
        });
      },
    );

    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(0.95);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });

    if (!mounted) return;
    setState(() => _speechReady = available);
  }

  Future<void> _toggleListening() async {
    if (!_speechReady || _isThinking) {
      setState(() {
        _assistantMessage =
            'El reconocimiento de voz no esta listo todavia en este dispositivo.';
      });
      return;
    }

    if (_isListening) {
      await _speech.stop();
      return;
    }

    setState(() {
      _recognized = '';
      _assistantMessage = 'Te escucho. Habla ahora.';
    });

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'es_ES',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _recognized = result.recognizedWords;
        });

        if (result.finalResult && _recognized.trim().isNotEmpty) {
          _speech.stop();
        }
      },
    );
  }

  Future<void> _handlePrompt(String prompt) async {
    if (_isThinking) return;

    setState(() {
      _isThinking = true;
      _assistantMessage = 'Procesando: "$prompt"';
    });

    final reply = _buildReply(prompt);

    if (!mounted) return;
    setState(() {
      _assistantMessage = reply;
      _isThinking = false;
    });

    await _tts.stop();
    await _tts.speak(reply);
  }

  String _buildReply(String prompt) {
    final text = prompt.toLowerCase();

    if (text.contains('hola') || text.contains('buenas')) {
      return 'Hola, soy OpenAI Man. Puedo ayudarte con recomendaciones de productos, pedidos y seguimiento comercial.';
    }
    if (text.contains('producto') || text.contains('catalogo')) {
      return 'Te recomiendo ir a escaparate, filtrar por categoria y luego confirmar el pedido desde checkout para seguimiento inmediato.';
    }
    if (text.contains('pedido') || text.contains('compra')) {
      return 'Para revisar estado, entra a Mis pedidos. Si eres administrador, puedes gestionar estados desde Pedidos admin.';
    }
    if (text.contains('gracias')) {
      return 'Con gusto. Cuando quieras seguimos hablando.';
    }

    return 'Escuche: $prompt. En esta version respondo en modo asistente local. Si quieres, te conecto despues a un proveedor de IA para respuestas avanzadas.';
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02130A),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF010F09), Color(0xFF032316), Color(0xFF05170F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: _MatrixRainLayer(
              columns: 28,
              color: Color(0x9926F2A5),
              fontSize: 13,
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _SilhouettePanel(
                child: const _MatrixRainLayer(
                  columns: 40,
                  color: Color(0xFF56FFBE),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/dashboard'),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: const Color(0xFFC8FFEA),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'OpenAI Man',
                          style: TextStyle(
                            color: Color(0xFFD7FFEF),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      _StatusDot(
                        active: _isListening || _isSpeaking || _isThinking,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xCC031B12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x6658FFBE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_recognized.trim().isNotEmpty) ...[
                          const Text(
                            'Tu voz',
                            style: TextStyle(
                              color: Color(0xFF9EFAD0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _recognized,
                            style: const TextStyle(
                              color: Color(0xFFE7FFF4),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const Text(
                          'OpenAI Man',
                          style: TextStyle(
                            color: Color(0xFF9EFAD0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _assistantMessage,
                          style: const TextStyle(
                            color: Color(0xFFE7FFF4),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _toggleListening,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _isListening ? const Color(0xFF0A784D) : const Color(0xFF126A93),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(_isListening ? Icons.stop_circle_outlined : Icons.mic_none_rounded),
                      label: Text(
                        _isListening
                            ? 'Detener grabacion'
                            : _isThinking
                                ? 'Procesando...'
                                : 'Hablar con OpenAI Man',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF53FFB7) : const Color(0x667A8A83),
        shape: BoxShape.circle,
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0xAA4BFFB2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _SilhouettePanel extends StatelessWidget {
  const _SilhouettePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * 0.92;
            final height = constraints.maxHeight * 0.9;

            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  ClipPath(
                    clipper: _FaceSilhouetteClipper(),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00150B), Color(0xFF012C18), Color(0xFF00150B)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  CustomPaint(
                    size: Size(width, height),
                    painter: _SilhouetteOutlinePainter(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FaceSilhouetteClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final head = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.26),
          width: size.width * 0.28,
          height: size.height * 0.28,
        ),
      );

    final neck = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.43),
            width: size.width * 0.11,
            height: size.height * 0.12,
          ),
          const Radius.circular(18),
        ),
      );

    final torso = Path()
      ..moveTo(size.width * 0.24, size.height * 0.92)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.62, size.width * 0.44, size.height * 0.54)
      ..lineTo(size.width * 0.56, size.height * 0.54)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.62, size.width * 0.76, size.height * 0.92)
      ..close();

    final headNeck = Path.combine(PathOperation.union, head, neck);
    return Path.combine(PathOperation.union, headNeck, torso);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SilhouetteOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _FaceSilhouetteClipper().getClip(size);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xAA58FFBE)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = const Color(0x2258FFBE)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MatrixRainLayer extends StatefulWidget {
  const _MatrixRainLayer({
    required this.columns,
    required this.color,
    required this.fontSize,
  });

  final int columns;
  final Color color;
  final double fontSize;

  @override
  State<_MatrixRainLayer> createState() => _MatrixRainLayerState();
}

class _MatrixRainLayerState extends State<_MatrixRainLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_MatrixColumn> _columns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _columns = List.generate(widget.columns, (index) {
      final rng = math.Random(index * 13 + 7);
      final streamLength = 16 + rng.nextInt(14);
      final buffer = StringBuffer();
      for (var i = 0; i < streamLength; i++) {
        buffer.writeln(rng.nextBool() ? '0' : '1');
      }

      return _MatrixColumn(
        relativeX: index / widget.columns,
        speed: 0.55 + rng.nextDouble() * 1.25,
        offset: rng.nextDouble(),
        stream: buffer.toString(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _MatrixPainter(
          progress: _controller.value,
          columns: _columns,
          color: widget.color,
          fontSize: widget.fontSize,
        ),
      ),
    );
  }
}

class _MatrixPainter extends CustomPainter {
  _MatrixPainter({
    required this.progress,
    required this.columns,
    required this.color,
    required this.fontSize,
  });

  final double progress;
  final List<_MatrixColumn> columns;
  final Color color;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final column in columns) {
      final x = column.relativeX * size.width;
      textPainter.text = TextSpan(
        text: column.stream,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.08,
        ),
      );
      textPainter.layout(maxWidth: size.width);

      final travel = (progress + column.offset) % 1.0;
      final y = travel * size.height * column.speed - textPainter.height;

      textPainter.paint(canvas, Offset(x, y));
      textPainter.paint(canvas, Offset(x, y - size.height * 1.06));
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.columns != columns;
  }
}

class _MatrixColumn {
  const _MatrixColumn({
    required this.relativeX,
    required this.speed,
    required this.offset,
    required this.stream,
  });

  final double relativeX;
  final double speed;
  final double offset;
  final String stream;
}
