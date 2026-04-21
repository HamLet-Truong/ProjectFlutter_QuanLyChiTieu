import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/user.dart';
import '../data/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<User?> build() async {
    return _fetchUser();
  }

  Future<User?> _fetchUser() async {
    final repository = ref.read(authRepositoryProvider);
    return repository.getUser();
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.registerUser(
        name: name,
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.loginUser(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.deleteUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.updateUserProfile(
        userId: currentUser.id,
        name: name,
        email: email,
      );
    });
  }
}
