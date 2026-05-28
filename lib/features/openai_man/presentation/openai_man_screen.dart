import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

class OpenAiManScreen extends StatefulWidget {
  const OpenAiManScreen({super.key});

  @override
  State<OpenAiManScreen> createState() => _OpenAiManScreenState();
}

class _OpenAiManScreenState extends State<OpenAiManScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final List<_ChatTurn> _history = <_ChatTurn>[];

  late final AnimationController _pulseController;

  bool _speechReady = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  bool _advancedMode = false;

  String _recognized = '';
  String _lastHandledPrompt = '';
  String _assistantMessage =
      'OpenAI Man activo. Toca el microfono y habla para iniciar la conversacion.';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..repeat();
    _setupVoice();
  }

  Future<void> _setupVoice() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        final listening = status == 'listening';
        if (_isListening != listening) {
          setState(() => _isListening = listening);
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
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

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

    if (_isSpeaking) {
      await _tts.stop();
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
          final prompt = _recognized.trim();
          _speech.stop();
          _consumePrompt(prompt);
        }
      },
    );
  }

  Future<void> _consumePrompt(String prompt) async {
    if (prompt.isEmpty) return;
    if (prompt == _lastHandledPrompt && _isThinking) return;

    _lastHandledPrompt = prompt;
    await _handlePrompt(prompt);
  }

  Future<void> _handlePrompt(String prompt) async {
    if (_isThinking) return;

    setState(() {
      _isThinking = true;
      _assistantMessage = 'Entendido. Dame un instante para responderte mejor.';
    });

    _history.add(_ChatTurn(role: 'user', content: prompt));

    final advancedReply = await _requestAdvancedReply(prompt);
    final reply = advancedReply ?? _buildLocalReply(prompt);

    _history.add(_ChatTurn(role: 'assistant', content: reply));
    if (_history.length > 12) {
      _history.removeRange(0, _history.length - 12);
    }

    if (!mounted) return;
    setState(() {
      _assistantMessage = reply;
      _isThinking = false;
    });

    await _speakSmooth(reply);
  }

  Future<String?> _requestAdvancedReply(String prompt) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:11434',
          connectTimeout: const Duration(milliseconds: 900),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      final context = _history
          .skip(_history.length > 6 ? _history.length - 6 : 0)
          .map((turn) => '${turn.role == 'user' ? 'Usuario' : 'Asistente'}: ${turn.content}')
          .join('\n');

      final composedPrompt = '''
Eres OpenAI Man, un asistente de voz humano, cercano y claro.
Reglas:
- Responde en espanol natural.
- No repitas literal la pregunta del usuario.
- Respuestas de 1 a 3 frases, directas y fluidas.
- Enfocate en ayudar sobre productos, pedidos y la app FINATIOL.

Contexto reciente:
$context

Pregunta actual:
$prompt
''';

      final response = await dio.post(
        '/api/generate',
        data: {
          'model': 'llama3.2',
          'stream': false,
          'prompt': composedPrompt,
          'options': {
            'temperature': 0.75,
            'top_p': 0.9,
            'num_predict': 180,
          }
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final raw = data['response'];
        if (raw is String && raw.trim().isNotEmpty) {
          if (mounted && !_advancedMode) {
            setState(() => _advancedMode = true);
          }
          return raw.trim();
        }
      }
    } catch (_) {
      if (mounted && _advancedMode) {
        setState(() => _advancedMode = false);
      }
    }

    return null;
  }

  Future<void> _speakSmooth(String text) async {
    final chunks = _chunkText(text, 180);
    await _tts.stop();
    for (final part in chunks) {
      final phrase = part.trim();
      if (phrase.isEmpty) continue;
      await _tts.speak(phrase);
    }
  }

  List<String> _chunkText(String text, int maxLen) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= maxLen) return [clean];

    final pieces = <String>[];
    var remaining = clean;
    while (remaining.length > maxLen) {
      var cut = remaining.lastIndexOf('.', maxLen);
      cut = cut == -1 ? remaining.lastIndexOf(',', maxLen) : cut;
      cut = cut == -1 ? remaining.lastIndexOf(' ', maxLen) : cut;
      if (cut <= 0) cut = maxLen;

      pieces.add(remaining.substring(0, cut + 1).trim());
      remaining = remaining.substring(cut + 1).trimLeft();
    }
    if (remaining.isNotEmpty) pieces.add(remaining);
    return pieces;
  }

  String _buildLocalReply(String prompt) {
    final text = prompt.toLowerCase();

    if (text.contains('hola') || text.contains('buenas')) {
      return 'Hola. Que gusto hablar contigo. Si quieres, revisamos productos, pedidos o cualquier parte de la app paso a paso.';
    }

    if (text.contains('no entiendo') || text.contains('explica')) {
      return 'Claro. Te lo explico simple y directo: dime exactamente que parte te confunde y te lo desgloso en pasos cortos.';
    }

    if (text.contains('producto') || text.contains('catalogo')) {
      return 'Abre Escaparate, elige una categoria y compara opciones. Cuando tengas uno, entra a checkout y confirma el pedido para darle seguimiento.';
    }

    if (text.contains('pedido') || text.contains('compra')) {
      return 'Para ver estado de tus compras, entra en Mis pedidos. Si administras, usa Pedidos admin para actualizar estado y comentario.';
    }

    if (text.contains('fluido') || text.contains('conversacion')) {
      return 'Perfecto, vamos a mantener un dialogo natural. Hazme una pregunta puntual y te respondo breve, claro y sin tecnicismos.';
    }

    if (text.contains('gracias')) {
      return 'Con gusto. Cuando quieras seguimos conversando.';
    }

    return 'Entiendo tu consulta. En este momento estoy en modo local y te ayudare de forma clara. Si instalas Ollama en tu equipo, puedo responderte con un modelo mas avanzado y natural sin costo.';
  }

  double _speechLevel() {
    final wave = math.sin(_pulseController.value * math.pi * 2).abs();
    if (_isSpeaking) return 0.5 + 0.5 * wave;
    if (_isListening) return 0.25 + 0.35 * wave;
    if (_isThinking) return 0.18 + 0.2 * wave;
    return 0.06 + 0.04 * wave;
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) => _SilhouettePanel(
                  speechLevel: _speechLevel(),
                  active: _isListening || _isSpeaking || _isThinking,
                  child: const _MatrixRainLayer(
                    columns: 40,
                    color: Color(0xFF56FFBE),
                    fontSize: 14,
                  ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: _advancedMode
                              ? const Color(0x223DFFAA)
                              : const Color(0x2251A8FF),
                          border: Border.all(
                            color: _advancedMode
                                ? const Color(0x883DFFAA)
                                : const Color(0x8851A8FF),
                          ),
                        ),
                        child: Text(
                          _advancedMode ? 'MODO AVANZADO' : 'MODO LOCAL',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Color(0xFFE8FFF5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                        if (!_advancedMode) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Tip: instala Ollama + llama3.2 para respuestas mas humanas sin pago.',
                            style: TextStyle(
                              color: Color(0xFF86D9BA),
                              fontSize: 12,
                            ),
                          ),
                        ],
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
  const _SilhouettePanel({
    required this.child,
    required this.speechLevel,
    required this.active,
  });

  final Widget child;
  final double speechLevel;
  final bool active;

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
                    painter: _SilhouetteOutlinePainter(
                      speechLevel: speechLevel,
                      active: active,
                    ),
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
    return Path()
      ..moveTo(size.width * 0.24, size.height * 0.92)
      ..quadraticBezierTo(
          size.width * 0.29, size.height * 0.7, size.width * 0.41, size.height * 0.57)
      ..quadraticBezierTo(
          size.width * 0.44, size.height * 0.52, size.width * 0.44, size.height * 0.46)
      ..quadraticBezierTo(
          size.width * 0.37, size.height * 0.36, size.width * 0.39, size.height * 0.24)
      ..quadraticBezierTo(
          size.width * 0.43, size.height * 0.11, size.width * 0.50, size.height * 0.08)
      ..quadraticBezierTo(
          size.width * 0.57, size.height * 0.11, size.width * 0.61, size.height * 0.24)
      ..quadraticBezierTo(
          size.width * 0.63, size.height * 0.36, size.width * 0.56, size.height * 0.46)
      ..quadraticBezierTo(
          size.width * 0.56, size.height * 0.52, size.width * 0.59, size.height * 0.57)
      ..quadraticBezierTo(
          size.width * 0.71, size.height * 0.70, size.width * 0.76, size.height * 0.92)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SilhouetteOutlinePainter extends CustomPainter {
  _SilhouetteOutlinePainter({
    required this.speechLevel,
    required this.active,
  });

  final double speechLevel;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _FaceSilhouetteClipper().getClip(size);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = active ? const Color(0xCC58FFBE) : const Color(0x8858FFBE)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 9 : 6
      ..color = const Color(0x2258FFBE)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);

    final featurePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xBB88FFD3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x3348FFB2);

    final leftEye = Offset(size.width * 0.46, size.height * 0.29);
    final rightEye = Offset(size.width * 0.54, size.height * 0.29);
    canvas.drawCircle(leftEye, 4, featurePaint);
    canvas.drawCircle(rightEye, 4, featurePaint);

    final nosePath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.30)
      ..lineTo(size.width * 0.495, size.height * 0.34)
      ..lineTo(size.width * 0.505, size.height * 0.34);
    canvas.drawPath(nosePath, featurePaint);

    final mouthY = size.height * 0.385;
    final mouthOpen = 2.5 + (speechLevel * 11);
    final mouthRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, mouthY),
      width: size.width * 0.09,
      height: mouthOpen,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(mouthRect, const Radius.circular(6)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(mouthRect, const Radius.circular(6)),
      featurePaint,
    );

    final jawGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x7748FFB2);
    final jawPath = Path()
      ..moveTo(size.width * 0.44, size.height * 0.42)
      ..quadraticBezierTo(
          size.width * 0.50, size.height * 0.46, size.width * 0.56, size.height * 0.42);
    canvas.drawPath(jawPath, jawGlow);
  }

  @override
  bool shouldRepaint(covariant _SilhouetteOutlinePainter oldDelegate) {
    return oldDelegate.speechLevel != speechLevel ||
        oldDelegate.active != active;
  }
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

class _ChatTurn {
  const _ChatTurn({required this.role, required this.content});

  final String role;
  final String content;
}
