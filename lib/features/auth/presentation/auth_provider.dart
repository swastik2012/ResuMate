import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HybridAuthRepository();
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _repository.authStateChanges.listen(
      (user) {
        state = AsyncValue.data(user);
      },
      onError: (err, stack) {
        state = AsyncValue.error(err, stack);
      },
    );
  }

  Future<void> signInWithGoogle({bool forceMock = false}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithGoogle(forceMock: forceMock);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
