import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubicasafe/pages/portada.dart';
import 'package:ubicasafe/core/app_theme.dart';

// Notifier global para el tema
ValueNotifier<bool> temaOscuroNotifier = ValueNotifier<bool>(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Dark mode por defecto (true si no hay preferencia guardada)
  temaOscuroNotifier.value = prefs.getBool('tema_oscuro') ?? true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: temaOscuroNotifier,
      builder: (context, temaOscuro, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'UbicaSafe',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: temaOscuro ? ThemeMode.dark : ThemeMode.light,
          home: const Portada(),
        );
      },
    );
  }
}
