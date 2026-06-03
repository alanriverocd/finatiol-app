import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum _AiResponseMode {
  localFast,
  localBalanced,
  cloudFree,
}

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
  final List<String> _ollamaBaseUrls = const [
    'http://127.0.0.1:11434',
    'http://localhost:11434',
    'http://10.0.2.2:11434',
  ];
  final List<String> _ollamaModelCandidates = const [
    'qwen2.5:0.5b',
    'qwen2.5:1.5b',
    'llama3.2:1b',
    'llama3.2',
  ];

  late final AnimationController _pulseController;
  late final Dio _ollamaDio;
  final TextEditingController _cloudApiKeyCtrl = TextEditingController(
    text: const String.fromEnvironment('OPENROUTER_API_KEY'),
  );

  bool _speechReady = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  bool _advancedMode = false;
  bool _continuousMode = true;
  _AiResponseMode _responseMode = _AiResponseMode.localFast;
  bool _manualStop = false;
  bool _autoResuming = false;
  bool _listenStartInProgress = false;
  DateTime? _lastListenAttemptAt;

  String _recognized = '';
  String _lastHandledPrompt = '';
  String _activeModel = 'llama3.2';
  String _activeOllamaBaseUrl = 'http://127.0.0.1:11434';
  String? _lastAdvancedError;
  DateTime? _lastOllamaHealthCheckAt;
  String _assistantMessage =
      'OpenAI Man activo. Toca el microfono y habla para iniciar la conversacion.';

  static const bool _perfLogsEnabled = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..repeat();

    _ollamaDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 20),
      ),
    );

    _setupVoice();
    _warmupAdvancedMode();
  }

  Future<void> _warmupAdvancedMode() async {
    final available = await _discoverOllamaBaseUrl();
    if (available) {
      unawaited(_preloadActiveModel());
    }
    if (!mounted) return;
    setState(() {
      _advancedMode = available;
      if (available) {
        _assistantMessage =
            'OpenAI Man conectado con Ollama. Ya puedo responder de forma mas fluida y de cualquier tema.';
      }
    });
  }

  Future<bool> _discoverOllamaBaseUrl() async {
    for (final base in _ollamaBaseUrls) {
      try {
        final response = await _ollamaDio.get(
          '$base/api/tags',
          options: Options(
            sendTimeout: const Duration(milliseconds: 1200),
            receiveTimeout: const Duration(milliseconds: 1800),
          ),
        );

        if (response.statusCode == 200) {
          _activeOllamaBaseUrl = base;
          _activeModel = _selectBestModel(response.data);
          _lastAdvancedError = null;
          return true;
        }
      } catch (_) {
        // Try next endpoint.
      }
    }

    _lastAdvancedError =
        'No pude conectar con Ollama en localhost, 127.0.0.1 o 10.0.2.2.';
    return false;
  }

  String _selectBestModel(dynamic tagsResponse) {
    final names = <String>[];
    if (tagsResponse is Map<String, dynamic>) {
      final models = tagsResponse['models'];
      if (models is List) {
        for (final item in models) {
          if (item is Map<String, dynamic>) {
            final name = item['name'];
            if (name is String && name.trim().isNotEmpty) {
              names.add(name.trim());
            }
          }
        }
      }
    }

    if (names.isEmpty) {
      return 'llama3.2';
    }

    for (final preferred in _ollamaModelCandidates) {
      final match = names.where((m) => m.startsWith(preferred)).toList();
      if (match.isNotEmpty) {
        return match.first;
      }
    }

    return names.first;
  }

  Future<void> _preloadActiveModel() async {
    try {
      await _ollamaDio.post(
        '$_activeOllamaBaseUrl/api/generate',
        data: {
          'model': _activeModel,
          'stream': false,
          'prompt': 'Hola',
          'keep_alive': '30m',
          'options': {
            'num_predict': 8,
            'temperature': 0.2,
          }
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 40),
        ),
      );
    } catch (_) {
      // Best effort preload.
    }
  }

  Future<void> _setupVoice() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        final listening = status == 'listening';
        if (_isListening != listening) {
          setState(() => _isListening = listening);
        }

        if (!listening) {
          if (_manualStop) {
            _manualStop = false;
            return;
          }
          _scheduleAutoListening();
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
    await _configureFemaleVoice();
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

  Future<void> _configureFemaleVoice() async {
    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices is! List) return;

      final voices = rawVoices.whereType<Map>().map((v) {
        final name = (v['name'] ?? '').toString();
        final locale = (v['locale'] ?? '').toString();
        final gender = (v['gender'] ?? '').toString().toLowerCase();
        return {
          'name': name,
          'locale': locale,
          'gender': gender,
          'raw': v,
        };
      }).where((v) => (v['name'] as String).isNotEmpty).toList();

      if (voices.isEmpty) return;

      Map<String, dynamic>? pick(List<Map<String, dynamic>> source) {
        if (source.isEmpty) return null;
        return source.first;
      }

      final esFemale = voices.where((v) {
        final locale = (v['locale'] as String).toLowerCase();
        final name = (v['name'] as String).toLowerCase();
        final gender = (v['gender'] as String);
        final looksFemale = gender.contains('female') ||
            name.contains('female') ||
            name.contains('mujer') ||
            name.contains('paulina') ||
            name.contains('monica') ||
            name.contains('helena') ||
            name.contains('lucia');
        return locale.startsWith('es') && looksFemale;
      }).toList();

      final anyFemale = voices.where((v) {
        final name = (v['name'] as String).toLowerCase();
        final gender = (v['gender'] as String);
        return gender.contains('female') ||
            name.contains('female') ||
            name.contains('mujer');
      }).toList();

      final anySpanish = voices.where((v) {
        final locale = (v['locale'] as String).toLowerCase();
        return locale.startsWith('es');
      }).toList();

      final selected = pick(esFemale) ?? pick(anyFemale) ?? pick(anySpanish);
      if (selected == null) return;

      final raw = selected['raw'];
      if (raw is Map) {
        final name = (raw['name'] ?? '').toString();
        final locale = (raw['locale'] ?? '').toString();
        if (name.isNotEmpty && locale.isNotEmpty) {
          await _tts.setVoice({'name': name, 'locale': locale});
        }
      }
    } catch (_) {
      // Keep default voice if platform does not expose voice metadata.
    }
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
      _manualStop = true;
      await _speech.stop();
      return;
    }

    await _startListening(showPrompt: true);
  }

  Future<void> _startListening({required bool showPrompt}) async {
    if (!_speechReady || _isThinking || _isListening || _listenStartInProgress) {
      return;
    }

    final now = DateTime.now();
    if (_lastListenAttemptAt != null &&
        now.difference(_lastListenAttemptAt!) < const Duration(milliseconds: 700)) {
      return;
    }
    _lastListenAttemptAt = now;
    _listenStartInProgress = true;

    if (_isSpeaking) {
      await _tts.stop();
    }

    setState(() {
      _recognized = '';
      if (showPrompt) {
        _assistantMessage = 'Te escucho. Habla ahora.';
      }
    });

    try {
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
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('already started') ||
          msg.contains('recognition has already started')) {
        try {
          await _speech.stop();
          await Future<void>.delayed(const Duration(milliseconds: 180));
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
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _assistantMessage =
                'El microfono estaba ocupado. Intenta hablar de nuevo en un segundo.';
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _assistantMessage =
              'No pude iniciar el microfono en este momento. Intenta nuevamente.';
        });
      }
    } finally {
      _listenStartInProgress = false;
    }
  }

  void _scheduleAutoListening() {
    if (!_continuousMode || !_speechReady || _isSpeaking || _isThinking) {
      return;
    }
    if (_isListening || _autoResuming) return;

    _autoResuming = true;
    Future<void>.delayed(const Duration(milliseconds: 420), () async {
      _autoResuming = false;
      if (!mounted) return;
      if (!_continuousMode || _isListening || _isSpeaking || _isThinking) {
        return;
      }

      await _startListening(showPrompt: false);
    });
  }

  Future<void> _consumePrompt(String prompt) async {
    if (prompt.isEmpty) return;
    if (prompt == _lastHandledPrompt && _isThinking) return;

    _lastHandledPrompt = prompt;
    await _handlePrompt(prompt);
  }

  Future<void> _handlePrompt(String prompt) async {
    if (_isThinking) return;

    final totalSw = Stopwatch()..start();

    setState(() {
      _isThinking = true;
      _assistantMessage = 'Entendido. Dame un instante para responderte mejor.';
    });

    _history.add(_ChatTurn(role: 'user', content: prompt));

    String? advancedReply;
    if (_responseMode == _AiResponseMode.cloudFree) {
      advancedReply = await _requestCloudFreeReply(prompt);
    }

    advancedReply ??= await _requestAdvancedReply(prompt);
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

    totalSw.stop();
    _perfLog('total_respuesta_ms=${totalSw.elapsedMilliseconds} modo=${_advancedMode ? 'avanzado' : 'local'} model=$_activeModel');
  }

  Future<String?> _requestAdvancedReply(String prompt) async {
    final requestSw = Stopwatch()..start();
    try {
      final now = DateTime.now();
      final shouldCheckEndpoint = !_advancedMode ||
          _lastOllamaHealthCheckAt == null ||
          now.difference(_lastOllamaHealthCheckAt!) > const Duration(seconds: 15);

      bool discovered = true;
      if (shouldCheckEndpoint) {
        final discoverSw = Stopwatch()..start();
        discovered = await _discoverOllamaBaseUrl();
        discoverSw.stop();
        _lastOllamaHealthCheckAt = now;
        _perfLog('descubrimiento_ollama_ms=${discoverSw.elapsedMilliseconds} ok=$discovered base=$_activeOllamaBaseUrl model=$_activeModel');
      }

      if (!discovered) {
        if (mounted && _advancedMode) {
          setState(() => _advancedMode = false);
        }
        requestSw.stop();
        _perfLog('advanced_fallback_local_ms=${requestSw.elapsedMilliseconds} motivo=sin_endpoint');
        return null;
      }

      final context = _history
          .skip(_history.length > 6 ? _history.length - 6 : 0)
          .map((turn) => '${turn.role == 'user' ? 'Usuario' : 'Asistente'}: ${turn.content}')
          .join('\n');

      final composedPrompt = '''
Eres OpenAI Man, un asistente de voz humano, cercano y claro.
Reglas:
- Responde en espanol natural.
- No repitas literal la pregunta del usuario.
- Responde completo, sin cortar ideas a la mitad.
- Enfocate en ayudar sobre productos, pedidos y la app FINATIOL.

Contexto reciente:
$context

Pregunta actual:
$prompt
''';

      var currentPrompt = composedPrompt;
      var rounds = 0;
      var lastDoneReason = '';
      final fullAnswer = StringBuffer();

      while (rounds < 4 && fullAnswer.length < 12000) {
        final genSw = Stopwatch()..start();
        final response = await _ollamaDio.post(
          '$_activeOllamaBaseUrl/api/generate',
          data: {
            'model': _activeModel,
            'stream': false,
            'prompt': currentPrompt,
            'keep_alive': '30m',
            'options': {
              'temperature': _responseMode == _AiResponseMode.localFast ? 0.35 : 0.55,
              'top_p': _responseMode == _AiResponseMode.localFast ? 0.8 : 0.9,
              'num_predict': _responseMode == _AiResponseMode.localFast ? 512 : 896,
              'num_ctx': _responseMode == _AiResponseMode.localFast ? 1536 : 3072,
              'repeat_penalty': 1.05,
            }
          },
        );
        genSw.stop();
        _perfLog('generacion_ollama_ms=${genSw.elapsedMilliseconds} base=$_activeOllamaBaseUrl model=$_activeModel ronda=$rounds');

        final data = response.data;
        if (data is! Map<String, dynamic>) break;

        final raw = data['response'];
        if (raw is! String || raw.trim().isEmpty) break;

        final merged = _appendWithoutOverlap(fullAnswer.toString(), raw.trim());
        if (merged.isNotEmpty) {
          fullAnswer.write(merged);
        }

        final doneReason = (data['done_reason'] ?? '').toString().toLowerCase();
        final done = data['done'] == true;
        final byTokenLimit = doneReason.contains('length') || doneReason.contains('max');
        final textNow = fullAnswer.toString().trim();
        final looksCut = _looksIncomplete(textNow);

        lastDoneReason = doneReason;
        rounds += 1;

        if (!(byTokenLimit || (!done && looksCut))) {
          break;
        }

        final tail = textNow.length > 900 ? textNow.substring(textNow.length - 900) : textNow;
        currentPrompt = '''
Continua exactamente desde donde te quedaste.
No repitas lo ya dicho.
Conserva el mismo idioma y tono.

Ultimo fragmento ya generado:
$tail
''';
      }

      final finalText = fullAnswer.toString().trim();
      if (finalText.isNotEmpty) {
        if (mounted && !_advancedMode) {
          setState(() => _advancedMode = true);
        }
        _lastAdvancedError = null;
        requestSw.stop();
        _perfLog('advanced_ok_total_ms=${requestSw.elapsedMilliseconds} chars=${finalText.length} rondas=$rounds done_reason=$lastDoneReason');
        return finalText;
      }
    } catch (e) {
      _lastAdvancedError = e.toString();
      if (mounted && _advancedMode) {
        setState(() => _advancedMode = false);
      }
      requestSw.stop();
      _perfLog('advanced_error_total_ms=${requestSw.elapsedMilliseconds} error=${e.toString()}');
    }

    requestSw.stop();
    _perfLog('advanced_empty_total_ms=${requestSw.elapsedMilliseconds}');

    return null;
  }

  Future<String?> _requestCloudFreeReply(String prompt) async {
    final sw = Stopwatch()..start();
    final apiKey = _cloudApiKeyCtrl.text.trim();
    if (apiKey.isEmpty) {
      _lastAdvancedError =
          'Para modo nube gratis agrega tu API key gratuita de OpenRouter.';
      sw.stop();
      _perfLog('cloud_skip_ms=${sw.elapsedMilliseconds} motivo=sin_api_key');
      return null;
    }

    try {
      final context = _history
          .skip(_history.length > 6 ? _history.length - 6 : 0)
          .map((turn) => '${turn.role == 'user' ? 'Usuario' : 'Asistente'}: ${turn.content}')
          .join('\n');

      var rounds = 0;
      var finishReason = '';
      final fullAnswer = StringBuffer();
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content':
              'Eres OpenAI Man. Responde en espanol natural, completo y sin repetir literal la pregunta.'
        },
        {
          'role': 'user',
          'content': 'Contexto reciente:\n$context\n\nPregunta actual: $prompt'
        }
      ];

      while (rounds < 4 && fullAnswer.length < 12000) {
        final response = await _ollamaDio.post(
          'https://openrouter.ai/api/v1/chat/completions',
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'HTTP-Referer': 'https://finatiol.local',
              'X-Title': 'FINATIOL OpenAI Man',
            },
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 45),
          ),
          data: {
            'model': 'meta-llama/llama-3.2-3b-instruct:free',
            'temperature': 0.5,
            'max_tokens': 900,
            'messages': messages,
          },
        );

        final data = response.data;
        if (data is! Map<String, dynamic>) break;

        final choices = data['choices'];
        if (choices is! List || choices.isEmpty) break;
        final first = choices.first;
        if (first is! Map<String, dynamic>) break;

        final message = first['message'];
        if (message is! Map<String, dynamic>) break;
        final content = message['content'];
        if (content is! String || content.trim().isEmpty) break;

        final merged = _appendWithoutOverlap(fullAnswer.toString(), content.trim());
        if (merged.isNotEmpty) {
          fullAnswer.write(merged);
        }

        final reason = (first['finish_reason'] ?? '').toString().toLowerCase();
        finishReason = reason;
        final textNow = fullAnswer.toString().trim();
        final byTokenLimit = reason.contains('length') || reason.contains('max');
        final looksCut = _looksIncomplete(textNow);

        rounds += 1;
        if (!(byTokenLimit || looksCut)) {
          break;
        }

        final tail = textNow.length > 900 ? textNow.substring(textNow.length - 900) : textNow;
        messages.addAll([
          {'role': 'assistant', 'content': content.trim()},
          {
            'role': 'user',
            'content':
                'Continua exactamente desde donde te quedaste, sin repetir lo anterior. Ultimo fragmento:\n$tail'
          }
        ]);
      }

      final finalText = fullAnswer.toString().trim();
      if (finalText.isNotEmpty) {
        _lastAdvancedError = null;
        sw.stop();
        _perfLog('cloud_ok_ms=${sw.elapsedMilliseconds} model=openrouter-free chars=${finalText.length} rondas=$rounds finish_reason=$finishReason');
        return finalText;
      }
    } catch (e) {
      _lastAdvancedError = 'Nube gratis fallo: ${e.toString()}';
      sw.stop();
      _perfLog('cloud_error_ms=${sw.elapsedMilliseconds} error=${e.toString()}');
      return null;
    }

    sw.stop();
    _perfLog('cloud_empty_ms=${sw.elapsedMilliseconds}');
    return null;
  }

  void _perfLog(String msg) {
    if (!_perfLogsEnabled) return;
    debugPrint('[OpenAI Man][perf] $msg');
  }

  bool _looksIncomplete(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return false;
    final end = clean[clean.length - 1];
    return !'.!?)]}"'.contains(end);
  }

  String _appendWithoutOverlap(String existing, String next) {
    final left = existing.trimRight();
    final right = next.trimLeft();
    if (left.isEmpty) return right;
    if (right.isEmpty) return '';

    final max = math.min(left.length, right.length);
    var overlap = 0;
    for (var size = max; size >= 12; size--) {
      if (left.substring(left.length - size) == right.substring(0, size)) {
        overlap = size;
        break;
      }
    }

    if (overlap > 0) {
      return right.substring(overlap);
    }
    return right;
  }

  Future<void> _speakSmooth(String text) async {
    final chunks = _chunkText(text, 180);
    await _tts.stop();
    for (final part in chunks) {
      final phrase = part.trim();
      if (phrase.isEmpty) continue;
      await _tts.speak(phrase);
    }

    _scheduleAutoListening();
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

  @override
  void dispose() {
    _cloudApiKeyCtrl.dispose();
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
          const Positioned.fill(child: _OpenAiWomanBackground()),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC020A12), Color(0xB0021422), Color(0xCC010B14)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: _MatrixRainLayer(
              columns: 22,
              color: Color(0x6636E3FF),
              fontSize: 12,
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
                          _advancedMode
                              ? 'MODO AVANZADO (${_activeModel.split(':').first})'
                              : 'MODO LOCAL',
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.36,
                      ),
                      child: SingleChildScrollView(
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
                                'Si instalamos Ollama + llama3.2 podemos hablar mas fluido y de cualquier tema, sin pago.',
                                style: TextStyle(
                                  color: Color(0xFF86D9BA),
                                  fontSize: 12,
                                ),
                              ),
                              if (_lastAdvancedError != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Diagnostico: $_lastAdvancedError',
                                  style: const TextStyle(
                                    color: Color(0xFFB4E9D5),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xA8122E23),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x6658FFBE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            size: 18, color: Color(0xFF9EFAD0)),
                        const SizedBox(width: 8),
                        const Text(
                          'Modo IA',
                          style: TextStyle(
                            color: Color(0xFFE7FFF4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<_AiResponseMode>(
                              value: _responseMode,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF123325),
                              style: const TextStyle(color: Color(0xFFE7FFF4)),
                              items: const [
                                DropdownMenuItem(
                                  value: _AiResponseMode.localFast,
                                  child: Text('Local rapido'),
                                ),
                                DropdownMenuItem(
                                  value: _AiResponseMode.localBalanced,
                                  child: Text('Local balanceado'),
                                ),
                                DropdownMenuItem(
                                  value: _AiResponseMode.cloudFree,
                                  child: Text('Nube gratis'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _responseMode = value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_responseMode == _AiResponseMode.cloudFree) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cloudApiKeyCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'API key OpenRouter (gratis)',
                        labelStyle: const TextStyle(color: Color(0xFFBCECD9)),
                        hintText: 'sk-or-v1-...',
                        hintStyle: const TextStyle(color: Color(0x889DD9C3)),
                        filled: true,
                        fillColor: const Color(0xA8122E23),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0x6658FFBE)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0x6658FFBE)),
                        ),
                      ),
                      style: const TextStyle(color: Color(0xFFE7FFF4)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xA8122E23),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x6658FFBE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.all_inclusive_rounded,
                            size: 18, color: Color(0xFF9EFAD0)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Modo continuo (manos libres)',
                            style: TextStyle(
                              color: Color(0xFFE7FFF4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _continuousMode,
                          onChanged: (value) async {
                            setState(() => _continuousMode = value);
                            if (value && !_isListening && !_isSpeaking && !_isThinking) {
                              await _startListening(showPrompt: true);
                            }
                          },
                          activeThumbColor: const Color(0xFF52FFB6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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

class _OpenAiWomanBackground extends StatelessWidget {
  const _OpenAiWomanBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/openai_woman_bg.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1320), Color(0xFF102237), Color(0xFF07111D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );
      },
    );
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
