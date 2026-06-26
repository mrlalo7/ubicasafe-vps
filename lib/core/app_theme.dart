import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  UBICASAFE — DESIGN SYSTEM
//  Sistema de tokens de diseño unificado
// ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Fondos
  static const bgDark = Color(0xFF080C18);
  static const bgSurface = Color(0xFF10162A);
  static const bgCard = Color(0xFF161D35);

  // Glassmorphism
  static const glassWhite = Color(0x12FFFFFF);
  static const glassBorder = Color(0x20FFFFFF);

  // Acentos primarios
  static const accentBlue = Color(0xFF4060F5);
  static const accentBlueDark = Color(0xFF2840C0);
  static const accentBlueLight = Color(0xFF6480FF);

  // Alertas / emergencias
  static const accentRed = Color(0xFFFF3B30);
  static const accentRedDark = Color(0xFFCC1F15);

  // Semáforo de riesgo
  static const safeGreen = Color(0xFF30D158);
  static const warningAmber = Color(0xFFFFD60A);
  static const dangerRed = Color(0xFFFF453A);

  // Texto
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8A9BC0);
  static const textHint = Color(0xFF4A5A80);

  // Categorías del menú (gradientes únicos)
  static const menuLocation = [Color(0xFF4060F5), Color(0xFF6A3DE8)];
  static const menuMap = [Color(0xFF00C896), Color(0xFF0080FF)];
  static const menuReport = [Color(0xFFFF3B30), Color(0xFFFF6B35)];
  static const menuProfile = [Color(0xFFBF5AF2), Color(0xFF7040D0)];
  static const menuSettings = [Color(0xFF32ADE6), Color(0xFF2070C8)];
  static const menuRate = [Color(0xFFFFAA00), Color(0xFFFF6B00)];
}

class AppGradients {
  AppGradients._();

  static const darkBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080C18), Color(0xFF0E1530), Color(0xFF080C18)],
  );

  static const headerBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4060F5), Color(0xFF2840C0)],
  );

  static const emergencyRed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3B30), Color(0xFFCC1F15)],
  );

  static const glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x18FFFFFF), Color(0x08FFFFFF)],
  );
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get blueGlow => [
    BoxShadow(
      color: AppColors.accentBlue.withOpacity(0.35),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get redGlow => [
    BoxShadow(
      color: AppColors.accentRed.withOpacity(0.45),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.30),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle headline1 = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle headline2 = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle headline3 = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle button = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentRed,
        surface: AppColors.bgSurface,
        error: AppColors.accentRed,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headline3.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.accentBlue,
            width: 1.5,
          ),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        labelStyle: AppTextStyles.label,
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgCard,
        contentTextStyle: AppTextStyles.body,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
          }
          return AppColors.glassWhite;
        }),
        side: const BorderSide(color: AppColors.glassBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
          }
          return AppColors.glassWhite;
        }),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accentBlue),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS REUTILIZABLES DEL DESIGN SYSTEM
// ─────────────────────────────────────────────

/// Panel glassmorphism estándar
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.shadows,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.glassCard,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: shadows ?? AppShadows.card,
      ),
      child: child,
    );
  }
}

/// Botón degradado premium
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final List<BoxShadow>? shadows;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.colors = const [AppColors.accentBlue, AppColors.accentBlueDark],
    this.icon,
    this.isLoading = false,
    this.height = 54,
    this.shadows,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.94,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  widget.onPressed == null
                      ? [Colors.grey.shade700, Colors.grey.shade800]
                      : widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.shadows ?? AppShadows.blueGlow,
          ),
          child: Center(
            child:
                widget.isLoading
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(widget.text, style: AppTextStyles.button),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

/// Campo de texto con estilo glassmorphism oscuro
class DarkTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextStyle? style;

  const DarkTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  State<DarkTextField> createState() => _DarkTextFieldState();
}

class _DarkTextFieldState extends State<DarkTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow:
            _isFocused
                ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        maxLines: widget.maxLines,
        textCapitalization: widget.textCapitalization,
        textAlign: widget.textAlign,
        style:
            widget.style ??
            AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon:
              widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 20)
                  : null,
          suffixIcon: widget.suffixIcon,
        ),
      ),
    );
  }
}
