import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_service.dart';
import '../../../core/database/database_helper.dart';
import 'auth_remote_datasource.dart';
import '../domain/user.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  static const _sessionActiveKey = 'auth_session_active';
  final DatabaseHelper _dbHelper;
  final ApiService _api;
  late final AuthRemoteDataSource _remote;
  static const Duration _remoteAuthTimeout = Duration(seconds: 6);

  AuthRepository({DatabaseHelper? dbHelper, ApiService? apiService})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _api = apiService ?? ApiService() {
    _remote = AuthRemoteDataSource(_api);
  }

  bool get _useRemote => ApiConfig.useRemoteApi;

  Future<bool> _isSessionActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionActiveKey) ?? false;
  }

  Future<void> _setSessionActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionActiveKey, value);
  }

  Future<void> _saveLocalUser(User user) async {
    final db = await _dbHelper.database;
    await db.delete('users');
    await db.insert('users', user.toMap());
  }

  Future<User?> getUser() async {
    final hasSession = await _isSessionActive();
    if (!hasSession) return null;

    if (_useRemote) {
      try {
        final remoteUser = await _remote.me().timeout(_remoteAuthTimeout);
        if (remoteUser != null) {
          await _saveLocalUser(remoteUser);
        }
        return remoteUser;
      } catch (_) {
        await _setSessionActive(false);
        return null;
      }
    }

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    await _setSessionActive(false);

    final draftUser = User(
      id: '',
      name: name,
      email: email,
      preferredCurrency: 'VND',
      createdAt: DateTime.now(),
    );

    if (_useRemote) {
      try {
        final registered = await _remote.register(
          draftUser,
          password: password,
        );
        await _saveLocalUser(registered);
        return registered;
      } catch (_) {}
    }

    final localUser = User(
      id: draftUser.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : draftUser.id,
      name: draftUser.name,
      email: draftUser.email,
      preferredCurrency: draftUser.preferredCurrency,
      createdAt: draftUser.createdAt,
    );
    await _saveLocalUser(localUser);
    return localUser;
  }

  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    if (_useRemote) {
      final loggedIn = await _remote.login(email: email, password: password);
      await _saveLocalUser(loggedIn);
      await _setSessionActive(true);
      return loggedIn;
    }

    final current = await getUser();
    if (current == null) {
      final db = await _dbHelper.database;
      final maps = await db.query('users', limit: 1);
      if (maps.isEmpty) {
        throw Exception('Không tìm thấy tài khoản');
      }
      final fallbackUser = User.fromMap(maps.first);
      if (fallbackUser.email.toLowerCase() != email.toLowerCase()) {
        throw Exception('Không tìm thấy tài khoản');
      }
      await _setSessionActive(true);
      return fallbackUser;
    }

    if (current.email.toLowerCase() != email.toLowerCase()) {
      throw Exception('Không tìm thấy tài khoản');
    }
    await _setSessionActive(true);
    return current;
  }

  Future<void> saveUser(User user) async {
    await _saveLocalUser(user);
  }

  Future<User> updateUserProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    User? updated;

    if (_useRemote) {
      try {
        updated = await _remote.updateProfile(name: name, email: email);
      } catch (_) {}
    }

    if (updated != null) {
      await _saveLocalUser(updated);
      return updated;
    }

    final existing = await getUser();
    final localUser = User(
      id: existing?.id ?? userId,
      name: name,
      email: email,
      preferredCurrency: existing?.preferredCurrency ?? 'VND',
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    await _saveLocalUser(localUser);
    return localUser;
  }

  Future<void> deleteUser() async {
    if (_useRemote) {
      await _api.clearToken();
      final db = await _dbHelper.database;
      await db.delete('users');
    }

    await _setSessionActive(false);
  }
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository();
}
