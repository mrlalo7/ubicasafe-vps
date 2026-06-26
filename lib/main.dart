import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubicasafe/pages/portada.dart';

// Creamos un ValueNotifier para el tema global
ValueNotifier<bool> temaOscuroNotifier = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar el tema al iniciar la app
  final prefs = await SharedPreferences.getInstance();
  temaOscuroNotifier.value = prefs.getBool('tema_oscuro') ?? false;

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
          theme: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: temaOscuro ? ThemeMode.dark : ThemeMode.light,
          home: const Portada(),
        );
      },
    );
  }
}
