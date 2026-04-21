import '../../../core/network/api_service.dart';
import '../domain/user.dart';

class AuthRemoteDataSource {
  final ApiService _api;

  AuthRemoteDataSource(this._api);

  User _toUser(Map<String, dynamic> map) {
    return User(
      id: '${map['id']}',
      name: '${map['name']}',
      email: '${map['email']}',
      preferredCurrency: '${map['preferredCurrency'] ?? 'VND'}',
      createdAt: DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
    );
  }

  Future<User?> me() async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) return null;

    final res = await _api.get('/auth/me');
    final userMap = (res as Map<String, dynamic>)['user'] as Map<String, dynamic>;
    return _toUser(userMap);
  }

  Future<User> register(User user, {required String password}) async {
    final res = await _api.post(
      '/auth/register',
      withAuth: false,
      body: {
        'name': user.name,
        'email': user.email,
        'password': password,
      },
    );

    final payload = res as Map<String, dynamic>;
    await _api.clearToken();

    final userMap = payload['user'] as Map<String, dynamic>;
    return _toUser(userMap);
  }

  Future<User> login({required String email, required String password}) async {
    final res = await _api.post(
      '/auth/login',
      withAuth: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    final payload = res as Map<String, dynamic>;
    final token = '${payload['token'] ?? ''}';
    if (token.isNotEmpty) {
      await _api.setToken(token);
    }

    final userMap = payload['user'] as Map<String, dynamic>;
    return _toUser(userMap);
  }

  Future<User> updateProfile({required String name, required String email}) async {
    final res = await _api.put('/users/profile', body: {
      'name': name,
      'email': email,
    });

    final profile = (res as Map<String, dynamic>)['profile'] as Map<String, dynamic>;
    return _toUser(profile);
  }
}
