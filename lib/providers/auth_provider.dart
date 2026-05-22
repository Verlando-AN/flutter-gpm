import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_model.dart';
import '../models/teknisi_model.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final String? role;
  final dynamic user;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.role,
    this.user,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? role,
    dynamic user,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      role: role ?? this.role,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);

    Future.microtask(() {
      checkAuthStatus();
    });

    return const AuthState();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await _repository.getToken();
      final role = await _repository.getRole();

      if (token != null &&
          token.isNotEmpty &&
          role != null &&
          role.isNotEmpty) {
        final stored = await _repository.getStoredUser();

        dynamic userObj;

        if (stored != null) {
          if (role.toLowerCase() == 'teknisi') {
            userObj = TeknisiModel.fromJson(stored);
          } else {
            userObj = CustomerModel.fromJson(stored);
          }
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          role: role,
          user: userObj,
          error: null,
        );

        print('AUTH RESTORE USER => ${state.user}');
        print('AUTH RESTORE TYPE => ${state.user.runtimeType}');
      } else {
        state = const AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      print('CHECK AUTH ERROR => $e');

      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.login(email, password);

      print('LOGIN RESULT => $result');

      final role = (result['role'] ?? '').toString().toLowerCase();

      final dynamic userObj = result['user'];

      print('LOGIN USER => ${userObj.name}');
      print('LOGIN TYPE => ${userObj.runtimeType}');

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: role,
        user: userObj,
        error: null,
      );

      return true;
    } catch (e) {
      print('LOGIN ERROR => $e');

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.toString(),
      );

      return false;
    }
  }

  Future<bool> logout() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.logout();

      state = const AuthState(isAuthenticated: false, isLoading: false);

      print('LOGOUT COMPLETED SUCCESSFULLY');

      return true;
    } catch (e) {
      print('LOGOUT ERROR => $e');

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.toString(),
      );

      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
