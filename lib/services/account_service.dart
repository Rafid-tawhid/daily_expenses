import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_model.dart';

class AccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all accounts for a user
  Future<List<Account>> getUserAccounts(int userId) async {
    try {
      final response = await _supabase
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load accounts: $e');
    }
  }

  // Create a new account
  Future<Account> createAccount(Account account) async {
    try {
      final response = await _supabase
          .from('accounts')
          .insert(account.toJson())
          .select()
          .single();

      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  // Update account balance
  Future<Account> updateBalance(int accountId, double newBalance) async {
    try {
      final response = await _supabase
          .from('accounts')
          .update({'balance': newBalance})
          .eq('id', accountId)
          .select()
          .single();

      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update balance: $e');
    }
  }

  // Delete account (soft delete)
  Future<void> deactivateAccount(int accountId) async {
    try {
      await _supabase
          .from('accounts')
          .update({'is_active': false})
          .eq('id', accountId);
    } catch (e) {
      throw Exception('Failed to deactivate account: $e');
    }
  }
}