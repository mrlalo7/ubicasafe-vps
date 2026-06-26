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
import 'package:ubicasafe/services/gemini_service.dart';

class ChatIaScreen extends StatefulWidget {
  const ChatIaScreen({super.key});

  @override
  State<ChatIaScreen> createState() => _ChatIaScreenState();
}

class _ChatIaScreenState extends State<ChatIaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _voiceController;
  final GeminiService _geminiService = GeminiService();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final List<String> _conversation = [];
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _keyboardOpen = false;
  bool _thinking = false;
  bool _speaking = true;
  bool _listening = false;
  bool _speechAvailable = false;
  String _lastSubmittedSpeech = '';
  String _assistantStatus = 'IA+ está escuchando...';
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
    _initVoice();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _voiceController.dispose();
    _speech.stop();
    _tts.stop();
    _textController.dispose();
    super.dispose();
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
              _assistantStatus = 'Toca el micrófono para hablar';
            }
          });
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

    await _tts.setLanguage('es-BO');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _speaking = true;
        _assistantStatus = 'IA+ está hablando...';
      });
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _speaking = false;
        _assistantStatus = 'Toca el micrófono para hablar';
      });
    });
    _tts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() => _speaking = false);
    });

    if (!mounted) return;
    setState(() {
      _assistantStatus = _speechAvailable
          ? 'Toca el micrófono para hablar'
          : 'Micrófono no disponible';
    });
  }

  void _open(Widget page) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();

    if (_listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _listening = false;
        _speaking = false;
        _assistantStatus = 'Escucha detenida';
      });
      return;
    }

    if (!_speechAvailable) {
      await _initVoice();
      if (!_speechAvailable) return;
    }

    await _tts.stop();
    _lastSubmittedSpeech = '';
    setState(() {
      _listening = true;
      _speaking = true;
      _assistantStatus = 'Te escucho...';
      _assistantReply = 'Habla ahora. Convertiré tu voz en texto.';
    });

    await _speech.listen(
      localeId: 'es_BO',
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
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
    setState(() => _keyboardOpen = !_keyboardOpen);
  }

  Future<void> _sendText([String? preset]) async {
    final value = (preset ?? _textController.text).trim();
    if (value.isEmpty) return;

    HapticFeedback.mediumImpact();
    await _tts.stop();
    setState(() {
      _conversation.add(value);
      _textController.clear();
      _keyboardOpen = preset == null;
      _speaking = true;
      _thinking = true;
      _assistantStatus = _localStatusFor(value);
      _assistantReply = 'Consultando IA+...';
    });

    final reply = await _geminiService.sendSafetyMessage(
      message: value,
      recentMessages: _conversation.reversed.skip(1).toList(),
    );

    if (!mounted) return;
    setState(() {
      _thinking = false;
      _speaking = true;
      _assistantStatus = 'IA+ respondió';
      _assistantReply = reply;
    });
    await _speak(reply);
  }

  Future<void> _speak(String text) async {
    final cleanText = text
        .replaceAll(RegExp(r'[*_`#>-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleanText.isEmpty) return;
    await _tts.speak(cleanText);
  }

  String _localStatusFor(String input) {
    final text = input.toLowerCase();
    if (text.contains('report') ||
        text.contains('robo') ||
        text.contains('incidente')) {
      return 'Preparando guía para reportar incidente...';
    }
    if (text.contains('zona') ||
        text.contains('segura') ||
        text.contains('riesgo')) {
      return 'Consultando el nivel de riesgo cercano...';
    }
    if (text.contains('ayuda') || text.contains('urgente')) {
      return 'Priorizando asistencia inmediata...';
    }
    if (text.contains('consejo') || text.contains('seguridad')) {
      return 'Generando consejos de seguridad...';
    }
    return 'Analizando tu mensaje...';
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
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 126),
                  child: Column(
                    children: [
                      const _Header(),
                      const SizedBox(height: 20),
                      Text(
                        'Hablando con IA+',
                        style: AppTextStyles.headline1.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tu asistente inteligente de seguridad',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _TimerBadge(label: _elapsedLabel),
                      const SizedBox(height: 10),
                      _VoiceOrb(
                        controller: _voiceController,
                        speaking: _speaking || _listening || _thinking,
                      ),
                      const SizedBox(height: 8),
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
                        onRisk: () => _sendText('¿Es segura esta zona?'),
                        onUrgent: () => _sendText('Necesito ayuda urgente'),
                        onTips: () => _sendText('Consejos de seguridad'),
                      ),
                      const SizedBox(height: 18),
                      _CallControls(
                        listening: _listening,
                        keyboardOpen: _keyboardOpen,
                        onMic: _toggleListening,
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/icons/ubicasafe_shield.png',
          width: 58,
          height: 58,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Ubica', style: AppTextStyles.headline1),
                    TextSpan(
                      text: 'Safe',
                      style: AppTextStyles.headline1.copyWith(
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.textSecondary,
                    size: 17,
                  ),
                  const SizedBox(width: 4),
                  Text('El Alto, Bolivia', style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 34),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accentRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '3',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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

class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({required this.controller, required this.speaking});

  final AnimationController controller;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(double.infinity, 260),
                painter: _WaveformPainter(progress: t, active: speaking),
              ),
              for (var i = 0; i < 5; i++)
                Transform.scale(
                  scale:
                      1 + (speaking ? ((t + i * 0.16) % 1) * 0.42 : i * 0.06),
                  child: Container(
                    width: 170 + i * 16,
                    height: 170 + i * 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            Color.lerp(
                              AppColors.accentBlueLight,
                              const Color(0xFF9B7CFF),
                              i / 5,
                            )!.withValues(
                              alpha: speaking ? 0.18 - i * 0.025 : 0.06,
                            ),
                      ),
                    ),
                  ),
                ),
              Container(
                width: 178,
                height: 178,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.22),
                      AppColors.bgDark.withValues(alpha: 0.78),
                    ],
                  ),
                  border: Border.all(
                    color: Color.lerp(
                      AppColors.accentBlueLight,
                      const Color(0xFF9B7CFF),
                      math.sin(t * math.pi),
                    )!,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF6F57FF,
                      ).withValues(alpha: speaking ? 0.34 : 0.16),
                      blurRadius: speaking ? 42 : 22,
                      spreadRadius: speaking ? 4 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/ubicasafe_shield.png',
                    width: 106,
                    height: 106,
                    fit: BoxFit.contain,
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
    required this.listening,
    required this.keyboardOpen,
    required this.onMic,
    required this.onHang,
    required this.onKeyboard,
  });

  final bool listening;
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
          icon: listening ? Icons.stop_rounded : Icons.mic_none_rounded,
          label: listening ? 'Detener' : 'Escuchar',
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
              child: Icon(icon, size: 30, color: Colors.white),
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
                hintText: 'Escribe tu consulta para IA+...',
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
              'IA+',
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
  const _WaveformPainter({required this.progress, required this.active});

  final double progress;
  final bool active;

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
          AppColors.accentBlueLight,
          const Color(0xFF7C5CFF),
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
    return oldDelegate.progress != progress || oldDelegate.active != active;
  }
}
