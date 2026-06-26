// services/simple_auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  static const String _usersKey = 'usuarios_app';
  static const String _currentUserKey = 'usuario_actual';
  static const int _maxUsers = 100;

  // ✅ MÉTODO PARA OBTENER EL USUARIO ACTUAL
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);

      if (userJson != null) {
        return json.decode(userJson);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario actual: $e');
      return null;
    }
  }

  // ✅ MÉTODO PARA OBTENER SOLO EL NOMBRE
  Future<String> getCurrentUserName() async {
    final user = await getCurrentUser();
    return user?['nombre'] ?? 'Usuario';
  }

  // ✅ MÉTODO PARA OBTENER SOLO EL EMAIL
  Future<String> getCurrentUserEmail() async {
    final user = await getCurrentUser();
    return user?['email'] ?? 'email@ejemplo.com';
  }

  // ✅ MÉTODO PARA OBTENER SOLO EL ROL
  Future<String> getCurrentUserRole() async {
    final user = await getCurrentUser();
    return user?['role'] ?? 'user';
  }

  // Registrar nuevo usuario (MANTENER ESTE MÉTODO)
  Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarios = await _getUsuarios();

      if (usuarios.length >= _maxUsers) {
        return {
          'success': false,
          'message': 'Límite máximo de usuarios alcanzado',
        };
      }

      if (usuarios.any((user) => user['email'] == email.toLowerCase().trim())) {
        return {'success': false, 'message': 'El email ya está registrado'};
      }

      final nuevoUsuario = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'nombre': nombre,
        'email': email.toLowerCase().trim(),
        'password': password,
        'role': 'user', // ✅ AGREGAR ROL POR DEFECTO
        'fechaRegistro': DateTime.now().toIso8601String(),
      };

      usuarios.add(nuevoUsuario);
      await prefs.setString(_usersKey, json.encode(usuarios));

      // ✅ GUARDAR COMO USUARIO ACTUAL INMEDIATAMENTE
      await prefs.setString(_currentUserKey, json.encode(nuevoUsuario));

      return {'success': true, 'message': 'Registro exitoso'};
    } catch (e) {
      return {'success': false, 'message': 'Error en el registro: $e'};
    }
  }

  // Iniciar sesión (MANTENER ESTE MÉTODO)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final usuarios = await _getUsuarios();

      final usuario = usuarios.firstWhere(
        (user) =>
            user['email'] == email.toLowerCase().trim() &&
            user['password'] == password,
        orElse: () => {},
      );

      if (usuario.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentUserKey, json.encode(usuario));
        return {'success': true, 'user': usuario};
      }

      return {'success': false, 'message': 'Email o contraseña incorrectos'};
    } catch (e) {
      return {'success': false, 'message': 'Error en el login: $e'};
    }
  }

  // ✅ MÉTODO PARA GUARDAR USUARIO DE GOOGLE
  Future<void> saveGoogleUser(String nombre, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final googleUser = {
        'id': 'google_${DateTime.now().millisecondsSinceEpoch}',
        'nombre': nombre,
        'email': email,
        'password': 'google_auth', // Contraseña especial para usuarios Google
        'role': 'user',
        'fechaRegistro': DateTime.now().toIso8601String(),
        'provider': 'google', // Identificar que viene de Google
      };

      // Guardar como usuario actual
      await prefs.setString(_currentUserKey, json.encode(googleUser));

      // También guardar en la lista de usuarios si no existe
      final usuarios = await _getUsuarios();
      if (!usuarios.any((user) => user['email'] == email)) {
        usuarios.add(googleUser);
        await prefs.setString(_usersKey, json.encode(usuarios));
      }

      print('✅ Usuario de Google guardado: $nombre');
    } catch (e) {
      print('Error al guardar usuario de Google: $e');
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Verificar si está logueado
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_currentUserKey);
  }

  // Obtener todos los usuarios
  Future<List<dynamic>> _getUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final usuariosJson = prefs.getString(_usersKey);
    return usuariosJson != null ? json.decode(usuariosJson) : [];
  }
}
