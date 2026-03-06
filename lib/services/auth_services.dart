import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign Up
  Future<AppUser?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create auth user
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      final User? user = authResponse.user;
      if (user == null) {
        throw Exception('Sign up failed');
      }

      // The trigger will automatically create the user in public.users
      // Wait a moment for the trigger to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch the user from public.users using auth_id
      return await getUserByAuthId(user.id);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign In
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = authResponse.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      // Fetch user from public.users using auth_id
      return await getUserByAuthId(user.id);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user from public.users using session
  Future<AppUser?> getCurrentUser() async {
    final Session? session = _supabase.auth.currentSession;
    final User? authUser = session?.user;

    if (authUser == null) return null;

    return await getUserByAuthId(authUser.id);
  }

  // Get user by auth_id (UUID from auth.users)
  Future<AppUser?> getUserByAuthId(String authId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('auth_id', authId)
          .maybeSingle();

      if (response == null) return null;

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error fetching user by auth_id: $e');
      return null;
    }
  }

  // Get user by ID (auto-increment ID)
  Future<AppUser?> getUserById(int userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error fetching user by id: $e');
      return null;
    }
  }
}