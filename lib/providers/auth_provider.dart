import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/auth_services.dart';

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth State class
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  bool _isInitialized = false;

  AuthNotifier(this.ref) : super(AuthState()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    // Listen to auth changes from Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen(
          (data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        print('Auth event: $event'); // For debugging

        if (event == AuthChangeEvent.signedOut) {
          // User signed out - clear user state
          state = state.copyWith(user: null, isLoading: false);
        } else if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated) {
          // User signed in or session updated - fetch user data
          if (session != null) {
            await _fetchUserData(session.user.id);
          }
        }
      },
      onError: (error) {
        print('Auth error: $error');
        state = state.copyWith(errorMessage: error.toString());
      },
    );
  }

  Future<void> _fetchUserData(String authId) async {
    state = state.copyWith(isLoading: true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getUserByAuthId(authId);
      state = state.copyWith(user: user, isLoading: false);
      print('User data fetched: ${user?.name}'); // For debugging
    } catch (e) {
      print('Error fetching user data: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Initialize auth state
  Future<void> initializeAuth() async {
    if (_isInitialized) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
      print('Auth initialized. User: ${user?.name}'); // For debugging
      _isInitialized = true;
    } catch (e) {
      print('Error initializing auth: $e');
      state = state.copyWith(
        user: null,
        isLoading: false,
        errorMessage: e.toString(),
      );
      _isInitialized = true;
    }
  }

  // Sign Up
  Future<AppUser?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signUp(
        name: name,
        email: email,
        password: password,
      );

      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Sign In
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      // State will be updated by the onAuthStateChange listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});