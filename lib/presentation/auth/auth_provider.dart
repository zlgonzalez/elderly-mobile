import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/http_auth_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;
  final String? pendingSignUpEmail;
  final String? lastFinalizationLink;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.infoMessage,
    this.pendingSignUpEmail,
    this.lastFinalizationLink,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    String? pendingSignUpEmail,
    String? lastFinalizationLink,
    bool clearUser = false,
    bool clearPendingSignUp = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
      pendingSignUpEmail: clearPendingSignUp
          ? null
          : (pendingSignUpEmail ?? this.pendingSignUpEmail),
      lastFinalizationLink: clearPendingSignUp
          ? null
          : (lastFinalizationLink ?? this.lastFinalizationLink),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockAuthRepository();
  }
  return HttpAuthRepository(apiClient: ref.watch(apiClientProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository, [AuthState? initialState])
      : super(initialState ?? const AuthState());

  Future<bool> selectDemoProfile(String profileId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, infoMessage: null);
    try {
      final user = await _repository.selectDemoProfile(profileId);
      state = state.copyWith(user: user, isLoading: false, clearPendingSignUp: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _cleanError(e));
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null, infoMessage: null);
    try {
      final user = await _repository.loginWithCredentials(username, password);
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false, clearPendingSignUp: true);
        return true;
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'Invalid username or password');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _cleanError(e));
      return false;
    }
  }

  Future<CaregiverSignUpInitiationResult?> initiateCaregiverSignUp(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null, infoMessage: null);
    try {
      final result = await _repository.initiateCaregiverSignUp(email);
      state = state.copyWith(
        isLoading: false,
        pendingSignUpEmail: result.email,
        lastFinalizationLink: result.finalizationLink,
        infoMessage: result.message,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _cleanError(e));
      return null;
    }
  }

  Future<CaregiverSignUpInitiationResult?> resendCaregiverSignUpCode(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null, infoMessage: null);
    try {
      final result = await _repository.resendCaregiverSignUpCode(email);
      state = state.copyWith(
        isLoading: false,
        pendingSignUpEmail: result.email,
        lastFinalizationLink: result.finalizationLink,
        infoMessage: 'A new 6-digit verification email has been sent to ${result.email}.',
      );
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _cleanError(e));
      return null;
    }
  }

  Future<bool> finalizeCaregiverSignUp({
    required String email,
    required String code,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, infoMessage: null);
    try {
      final user = await _repository.finalizeCaregiverSignUp(
        email: email,
        code: code,
        username: username,
        password: password,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        clearPendingSignUp: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _cleanError(e));
      return false;
    }
  }

  Future<List<DemoAccount>> getDemoAccounts() async {
    return _repository.getDemoAccounts();
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  String _cleanError(Object error) {
    final msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring('Exception: '.length);
    }
    return msg;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

final demoAccountsProvider = FutureProvider<List<DemoAccount>>((ref) async {
  ref.watch(appConfigProvider.select((c) => c.apiBaseUrl));
  final repo = ref.watch(authRepositoryProvider);
  return repo.getDemoAccounts();
});
