import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:ubicasafe/core/app_theme.dart';
import 'package:ubicasafe/pages/configuracion.dart';
import 'package:ubicasafe/pages/mapapredictivo.dart';
import 'package:ubicasafe/pages/miperfil.dart';
import 'package:ubicasafe/pages/reportarrobo.dart';
import 'package:ubicasafe/services/live_audio_service.dart';

class ChatIaScreen extends StatefulWidget {
  const ChatIaScreen({super.key});

  @override
  State<ChatIaScreen> createState() => _ChatIaScreenState();
}

class _ChatIaScreenState extends State<ChatIaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _voiceController;
  final LiveAudioService _liveAudioService = LiveAudioService();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final List<String> _conversation = [];
  Timer? _timer;
  Timer? _restartListenTimer;
  StreamSubscription<LiveAudioState>? _liveStateSubscription;
  StreamSubscription<String>? _liveMessageSubscription;
  Duration _elapsed = Duration.zero;
  bool _keyboardOpen = false;
  bool _thinking = false;
  bool _speaking = true;
  bool _listening = false;
  bool _speechAvailable = false;
  bool _autoListen = true;
  String _localeId = 'es_BO';
  String _assistantLanguage = 'es';
  String _lastSubmittedSpeech = '';
  bool _micMuted = false;
  String _assistantStatus = 'Wara está escuchando...';
  String _assistantReply =
      'Estoy lista para ayudarte con reportes, zonas de riesgo o consejos de seguridad.';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _voiceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
    _initLiveAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _liveAudioService.language = _assistantLanguage;
      _liveAudioService.start();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restartListenTimer?.cancel();
    _liveStateSubscription?.cancel();
    _liveMessageSubscription?.cancel();
    _liveAudioService.dispose();
    _voiceController.dispose();
    _speech.stop();
    _tts.stop();
    _textController.dispose();
    super.dispose();
  }

  void _initLiveAudio() {
    _liveStateSubscription = _liveAudioService.states.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case LiveAudioState.connecting:
            _thinking = true;
            _listening = false;
            _speaking = true;
            _assistantStatus = 'Conectando a Wara...';
            break;
          case LiveAudioState.listening:
            _thinking = false;
            _listening = true;
            _speaking = true;
            _assistantStatus = _micMuted
                ? 'Micrófono silenciado'
                : 'Wara está escuchando...';
            break;
          case LiveAudioState.speaking:
            _thinking = false;
            _listening = false;
            _speaking = true;
            _assistantStatus = 'Wara está hablando...';
            break;
          case LiveAudioState.error:
            _thinking = false;
            _listening = false;
            _speaking = false;
            _assistantStatus = 'Live API no disponible';
            break;
          case LiveAudioState.idle:
            _thinking = false;
            _listening = false;
            _speaking = false;
            _assistantStatus = 'Llamada detenida';
            break;
        }
      });
    });
    _liveMessageSubscription = _liveAudioService.messages.listen((message) {
      if (!mounted) return;
      setState(() => _assistantReply = message);
    });
  }

  Future<void> _initVoice() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _listening = false;
            if (!_thinking) {
              _speaking = false;
              _assistantStatus = _autoListen
                  ? 'Esperando tu voz...'
                  : 'Toca el micrófono para hablar';
            }
          });
          if (_autoListen && !_thinking) {
            _scheduleListeningRestart();
          }
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _speaking = false;
          _assistantStatus = 'No pude activar el micrófono';
          _assistantReply = error.errorMsg;
        });
      },
    );

    await _configureNaturalVoice();
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.04);
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _speaking = true;
        _assistantStatus = 'Wara está hablando...';
      });
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _speaking = false;
        _assistantStatus = _autoListen
            ? 'Esperando tu voz...'
            : 'Toca el micrófono para hablar';
      });
      if (_autoListen) {
        _scheduleListeningRestart();
      }
    });
    _tts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() => _speaking = false);
    });

    if (!mounted) return;
    setState(() {
      _speaking = false;
      _assistantStatus = _speechAvailable
          ? 'Esperando tu voz...'
          : 'Micrófono no disponible';
    });
    if (_speechAvailable) {
      _scheduleListeningRestart(delay: const Duration(milliseconds: 550));
    }
  }

  Future<void> _configureNaturalVoice() async {
    final locales = await _speech.locales();
    String? preferredLocale;
    for (final locale in locales) {
      if (locale.localeId == 'es_BO' ||
          locale.localeId == 'es_ES' ||
          locale.localeId == 'es_US' ||
          locale.localeId.startsWith('es_')) {
        preferredLocale = locale.localeId;
        break;
      }
    }
    _localeId = preferredLocale ?? 'es_ES';

    await _tts.setLanguage(_localeId.replaceAll('_', '-'));
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        final spanishVoices = voices
            .whereType<Map>()
            .where((voice) => _spanishVoiceScore(voice) > 0)
            .toList();
        spanishVoices.sort(
          (a, b) => _spanishVoiceScore(b).compareTo(_spanishVoiceScore(a)),
        );
        final selected = spanishVoices.isNotEmpty
            ? spanishVoices.first
            : const <String, String>{};
        if (selected.isNotEmpty) {
          final name = selected['name']?.toString();
          final locale = (selected['locale'] ?? selected['language'])
              ?.toString();
          if (name != null && locale != null) {
            await _tts.setVoice({'name': name, 'locale': locale});
          }
        }
      }
    } catch (_) {
      // The platform TTS voice list is optional; language/rate still improve output.
    }
  }

  int _spanishVoiceScore(Map voice) {
    final locale = '${voice['locale'] ?? voice['language'] ?? ''}'
        .replaceAll('-', '_')
        .toLowerCase();
    final name = '${voice['name'] ?? voice['voice'] ?? ''}'.toLowerCase();
    final gender = '${voice['gender'] ?? ''}'.toLowerCase();

    if (!locale.startsWith('es') && !name.contains('spanish')) return 0;

    var score = 10;
    if (locale == 'es_bo') score += 18;
    if (locale == 'es_es' || locale == 'es_mx' || locale == 'es_us') {
      score += 14;
    }
    if (locale.startsWith('es_')) score += 8;

    if (gender.contains('female') || gender.contains('femenino')) score += 28;
    if (name.contains('female') || name.contains('mujer')) score += 24;
    if (name.contains('paulina') ||
        name.contains('monica') ||
        name.contains('mónica') ||
        name.contains('elvira') ||
        name.contains('sabina') ||
        name.contains('helena') ||
        name.contains('lucia') ||
        name.contains('lucía') ||
        name.contains('maria') ||
        name.contains('maría')) {
      score += 18;
    }

    if (name.contains('neural') ||
        name.contains('wavenet') ||
        name.contains('natural') ||
        name.contains('premium') ||
        name.contains('enhanced')) {
      score += 30;
    }
    if (name.contains('google')) score += 8;
    if (name.contains('compact') || name.contains('default')) score -= 8;

    return score;
  }

  void _scheduleListeningRestart({
    Duration delay = const Duration(milliseconds: 900),
  }) {
    _restartListenTimer?.cancel();
    if (!_autoListen ||
        _listening ||
        _thinking ||
        _speaking ||
        !_speechAvailable) {
      return;
    }
    _restartListenTimer = Timer(delay, () {
      if (mounted && _autoListen && !_listening && !_thinking && !_speaking) {
        _startListening();
      }
    });
  }

  void _open(Widget page) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _toggleMute() {
    HapticFeedback.lightImpact();
    setState(() {
      _micMuted = !_micMuted;
      _liveAudioService.muted = _micMuted;
      if (_micMuted) {
        _assistantStatus = 'Micrófono silenciado';
      } else {
        _assistantStatus = 'Wara está escuchando...';
      }
    });
  }

  Future<void> _setAssistantLanguage(String language) async {
    if (_assistantLanguage == language) return;

    HapticFeedback.selectionClick();
    _restartListenTimer?.cancel();
    await _speech.stop();
    await _tts.stop();
    await _liveAudioService.stop();
    _liveAudioService.language = language;

    if (!mounted) return;
    setState(() {
      _assistantLanguage = language;
      _assistantStatus = language == 'ay'
          ? 'Wara aymar arun istaskiwa...'
          : 'Wara está escuchando...';
      _assistantReply = language == 'ay'
          ? 'Jichhax aymar arun yanapt’äma.'
          : 'Ahora responderé en español.';
      _thinking = true;
      _speaking = true;
      _listening = false;
    });

    await _liveAudioService.start();
  }

  Future<void> _startListening() async {
    if (_listening || _thinking) return;

    if (!_speechAvailable) {
      await _initVoice();
      if (!_speechAvailable) return;
    }

    _restartListenTimer?.cancel();
    await _tts.stop();
    _lastSubmittedSpeech = '';
    setState(() {
      _listening = true;
      _speaking = true;
      _assistantStatus = 'Te escucho...';
      _assistantReply = 'Habla ahora. Convertiré tu voz en texto.';
    });

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        listenFor: const Duration(minutes: 2),
        localeId: _localeId,
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
      ),
      onResult: _onSpeechResult,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (words.isEmpty || !mounted) return;

    setState(() {
      _assistantReply = words;
      _assistantStatus = result.finalResult
          ? 'Voz detectada'
          : 'Escuchando: ${result.confidence.toStringAsFixed(2)}';
    });

    if (result.finalResult && words != _lastSubmittedSpeech) {
      _lastSubmittedSpeech = words;
      _speech.stop();
      _sendText(words);
    }
  }

  void _toggleKeyboard() {
    HapticFeedback.selectionClick();
    _autoListen = false;
    _restartListenTimer?.cancel();
    if (_listening) {
      _speech.stop();
    }
    setState(() => _keyboardOpen = !_keyboardOpen);
  }

  Future<void> _sendText([String? preset]) async {
    final value = (preset ?? _textController.text).trim();
    if (value.isEmpty) return;

    HapticFeedback.mediumImpact();
    _autoListen = true;
    _restartListenTimer?.cancel();
    await _speech.stop();
    await _tts.stop();
    setState(() {
      _conversation.add(value);
      _textController.clear();
      _keyboardOpen = preset == null;
      _speaking = true;
      _thinking = true;
      _assistantStatus = 'Enviando a Wara Live...';
      _assistantReply = value;
    });

    final sentByLive = await _liveAudioService.sendText(value);
    if (sentByLive) {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _speaking = true;
        _assistantStatus = 'Wara está respondiendo...';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _thinking = false;
      _speaking = false;
      _assistantStatus = 'Live API no disponible';
      _assistantReply =
          'No pude conectar con la llamada en vivo. Revisa permisos de micrófono, WebSocket o el log /api/live del backend.';
    });
  }

  String get _elapsedLabel {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.darkBackground),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 126),
                  child: Column(
                    children: [
                      Text(
                        'Hablando con Wara',
                        style: AppTextStyles.headline2.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'tu asistente de seguridad',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _LanguageSwitch(
                        value: _assistantLanguage,
                        onChanged: _setAssistantLanguage,
                      ),
                      const SizedBox(height: 10),
                      _TimerBadge(label: _elapsedLabel),
                      const SizedBox(height: 8),
                      _VoiceOrb(
                        controller: _voiceController,
                        listening: _listening,
                        talking: _speaking && !_listening && !_thinking,
                        thinking: _thinking,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _thinking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Color(0xFF9B7CFF),
                                  ),
                                )
                              : const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF9B7CFF),
                                  size: 24,
                                ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _assistantStatus,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ReplyPanel(text: _assistantReply),
                      const SizedBox(height: 8),
                      Text(
                        'Puedes hablar o seleccionar una opción rápida',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _QuickGrid(
                        onReport: () => _open(const ReportarRobo()),
                        onRisk: () => _sendText(
                          _assistantLanguage == 'ay'
                              ? 'Aka chiqax jan waltawit segura ukhama?'
                              : '¿Es segura esta zona?',
                        ),
                        onUrgent: () => _sendText(
                          _assistantLanguage == 'ay'
                              ? 'Jankaki yanapt’a munta'
                              : 'Necesito ayuda urgente',
                        ),
                        onTips: () => _sendText(
                          _assistantLanguage == 'ay'
                              ? 'Sarnaqañatakix seguridad tuqit iwxt’anaka'
                              : 'Consejos de seguridad',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _CallControls(
                        muted: _micMuted,
                        keyboardOpen: _keyboardOpen,
                        onMic: _toggleMute,
                        onHang: () => Navigator.pop(context),
                        onKeyboard: _toggleKeyboard,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _keyboardOpen
                            ? Padding(
                                key: const ValueKey('keyboard'),
                                padding: const EdgeInsets.only(top: 18),
                                child: _KeyboardPanel(
                                  controller: _textController,
                                  onSend: () => _sendText(),
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomNav(
                  onHome: () => Navigator.pop(context),
                  onMap: () => _open(const MapaPredictivo()),
                  onAi: () {},
                  onProfile: () => _open(const MiPerfilScreen()),
                  onSettings: () => _open(const ConfiguracionScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyPanel extends StatelessWidget {
  const _ReplyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageOption(
            label: 'Español',
            selected: value == 'es',
            onTap: () => onChanged('es'),
          ),
          _LanguageOption(
            label: 'Aymara',
            selected: value == 'ay',
            onTap: () => onChanged('ay'),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.accentBlue.withValues(alpha: 0.9)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected ? AppShadows.blueGlow : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({
    required this.controller,
    required this.listening,
    required this.talking,
    required this.thinking,
  });

  final AnimationController controller;
  final bool listening;
  final bool talking;
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final active = listening || talking || thinking;
        final stateColor = talking
            ? const Color(0xFF35E889)
            : listening
            ? AppColors.accentBlueLight
            : thinking
            ? const Color(0xFF9B7CFF)
            : AppColors.textSecondary;
        final secondaryColor = talking
            ? const Color(0xFF0ABF70)
            : listening
            ? const Color(0xFF2F80FF)
            : const Color(0xFF7C5CFF);

        return SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(double.infinity, 190),
                painter: _WaveformPainter(
                  progress: t,
                  active: active,
                  color: stateColor,
                  secondaryColor: secondaryColor,
                ),
              ),
              for (var i = 0; i < 5; i++)
                Transform.scale(
                  scale: 1 + (active ? ((t + i * 0.16) % 1) * 0.32 : i * 0.05),
                  child: Container(
                    width: 120 + i * 12,
                    height: 120 + i * 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.lerp(
                          stateColor,
                          secondaryColor,
                          i / 5,
                        )!.withValues(alpha: active ? 0.2 - i * 0.026 : 0.06),
                      ),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 138,
                height: 138,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      stateColor.withValues(alpha: active ? 0.95 : 0.5),
                      secondaryColor.withValues(alpha: active ? 0.75 : 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: stateColor.withValues(alpha: active ? 0.42 : 0.18),
                      blurRadius: active ? 38 : 18,
                      spreadRadius: active ? 5 : 1,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgDark,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/img/wara_assistant.jpeg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({
    required this.onReport,
    required this.onRisk,
    required this.onUrgent,
    required this.onTips,
  });

  final VoidCallback onReport;
  final VoidCallback onRisk;
  final VoidCallback onUrgent;
  final VoidCallback onTips;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.85,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _QuickAction(
          icon: Icons.shield_rounded,
          title: 'Quiero reportar algo',
          subtitle: 'Reportar un incidente',
          onTap: onReport,
        ),
        _QuickAction(
          icon: Icons.location_on_rounded,
          title: '¿Es segura esta zona?',
          subtitle: 'Consultar nivel de riesgo',
          onTap: onRisk,
        ),
        _QuickAction(
          icon: Icons.groups_rounded,
          title: 'Necesito ayuda urgente',
          subtitle: 'Asistencia inmediata',
          onTap: onUrgent,
        ),
        _QuickAction(
          icon: Icons.info_outline_rounded,
          title: 'Consejos de seguridad',
          subtitle: 'Recomendaciones útiles',
          onTap: onTips,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassWhite,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accentBlueLight, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(subtitle, style: AppTextStyles.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.muted,
    required this.keyboardOpen,
    required this.onMic,
    required this.onHang,
    required this.onKeyboard,
  });

  final bool muted;
  final bool keyboardOpen;
  final VoidCallback onMic;
  final VoidCallback onHang;
  final VoidCallback onKeyboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundControl(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
          label: muted ? 'Activar' : 'Silenciar',
          iconColor: muted ? AppColors.accentRed : null,
          onTap: onMic,
        ),
        _HangButton(onTap: onHang),
        _RoundControl(
          icon: Icons.keyboard_rounded,
          label: keyboardOpen ? 'Cerrar' : 'Teclado',
          onTap: onKeyboard,
        ),
      ],
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.glassWhite,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(icon, size: 30, color: iconColor ?? Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _HangButton extends StatelessWidget {
  const _HangButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentRed,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4B42), AppColors.accentRed],
            ),
            boxShadow: AppShadows.redGlow,
          ),
          child: const Icon(
            Icons.call_end_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }
}

class _KeyboardPanel extends StatelessWidget {
  const _KeyboardPanel({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Escribe tu consulta para Wara...',
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            height: 50,
            child: ElevatedButton(
              onPressed: onSend,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.onHome,
    required this.onMap,
    required this.onAi,
    required this.onProfile,
    required this.onSettings,
  });

  final VoidCallback onHome;
  final VoidCallback onMap;
  final VoidCallback onAi;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.glassBorder)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.location_on_rounded,
            label: 'Inicio',
            onTap: onHome,
          ),
          _NavItem(icon: Icons.map_rounded, label: 'Mapa', onTap: onMap),
          _AiNavItem(onTap: onAi),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Mi perfil',
            onTap: onProfile,
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Configuración',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 30),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: AppTextStyles.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiNavItem extends StatelessWidget {
  const _AiNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(38),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accentBlue, Color(0xFF6F57FF)],
                ),
                boxShadow: AppShadows.blueGlow,
              ),
              child: Container(
                margin: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF9B7CFF), width: 2),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFFB098FF),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Wara',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFB098FF),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.progress,
    required this.active,
    required this.color,
    required this.secondaryColor,
  });

  final double progress;
  final bool active;
  final Color color;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final paint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var side = -1; side <= 1; side += 2) {
      for (var i = 0; i < 34; i++) {
        final distance = i * 8.0 + 138;
        final x = size.width / 2 + side * distance;
        if (x < -20 || x > size.width + 20) continue;
        final phase = progress * math.pi * 2 + i * 0.48;
        final amplitude = active ? 12 + math.sin(phase).abs() * 42 : 10.0;
        final alpha = (1 - i / 40).clamp(0.18, 0.85);
        paint.color = Color.lerp(
          color,
          secondaryColor,
          i / 34,
        )!.withValues(alpha: alpha);
        canvas.drawLine(
          Offset(x, centerY - amplitude / 2),
          Offset(x, centerY + amplitude / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.color != color ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
