import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all transactions for a user
  Future<List<Transaction>> getUserTransactions(int userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            categories (*)
          ''')
          .eq('user_id', userId)
          .order('transaction_date', ascending: false);

      print('Transactions for user $userId: ${response.length}'); // For debugging

      return (response as List).map((json) {
        Category? category;
        if (json['categories'] != null && json['categories'] is Map) {
          category = Category.fromJson(json['categories']);
        }
        return Transaction.fromJson(json, category: category);
      }).toList();
    } catch (e) {
      print('Error loading transactions: $e');
      throw Exception('Failed to load transactions: $e');
    }
  }

  // Get recent transactions (last 10)
  Future<List<Transaction>> getRecentTransactions(int userId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            categories (*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) {
        Category? category;
        if (json['categories'] != null && json['categories'] is Map) {
          category = Category.fromJson(json['categories']);
        }
        return Transaction.fromJson(json, category: category);
      }).toList();
    } catch (e) {
      print('Error loading recent transactions: $e');
      throw Exception('Failed to load recent transactions: $e');
    }
  }

  // Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
      int userId,
      DateTime startDate,
      DateTime endDate
      ) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            categories (*)
          ''')
          .eq('user_id', userId)
          .gte('transaction_date', startDate.toIso8601String().split('T')[0])
          .lte('transaction_date', endDate.toIso8601String().split('T')[0])
          .order('transaction_date', ascending: false);

      return (response as List).map((json) {
        Category? category;
        if (json['categories'] != null && json['categories'] is Map) {
          category = Category.fromJson(json['categories']);
        }
        return Transaction.fromJson(json, category: category);
      }).toList();
    } catch (e) {
      print('Error loading transactions by date: $e');
      throw Exception('Failed to load transactions by date: $e');
    }
  }

  // Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory(
      int userId,
      int categoryId
      ) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            categories (*)
          ''')
          .eq('user_id', userId)
          .eq('category_id', categoryId)
          .order('transaction_date', ascending: false);

      return (response as List).map((json) {
        Category? category;
        if (json['categories'] != null && json['categories'] is Map) {
          category = Category.fromJson(json['categories']);
        }
        return Transaction.fromJson(json, category: category);
      }).toList();
    } catch (e) {
      print('Error loading transactions by category: $e');
      throw Exception('Failed to load transactions by category: $e');
    }
  }

  // Create a new transaction
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final response = await _supabase
          .from('transactions')
          .insert({
        'user_id': transaction.userId,
        'category_id': transaction.categoryId,
        'amount': transaction.amount,
        'description': transaction.description,
        'transaction_type': transaction.type,
        'transaction_date': transaction.date.toIso8601String().split('T')[0],
        'payment_method': transaction.paymentMethod,
        'is_recurring': transaction.isRecurring,
        'recurring_frequency': transaction.recurringFrequency,
        'notes': transaction.notes,
      })
          .select('''
            *,
            categories (*)
          ''')
          .single();

      Category? category;
      if (response['categories'] != null && response['categories'] is Map) {
        category = Category.fromJson(response['categories']);
      }
      return Transaction.fromJson(response, category: category);
    } catch (e) {
      print('Error creating transaction: $e');
      throw Exception('Failed to create transaction: $e');
    }
  }

  // Update a transaction
  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      final response = await _supabase
          .from('transactions')
          .update({
        'category_id': transaction.categoryId,
        'amount': transaction.amount,
        'description': transaction.description,
        'transaction_type': transaction.type,
        'transaction_date': transaction.date.toIso8601String().split('T')[0],
        'payment_method': transaction.paymentMethod,
        'is_recurring': transaction.isRecurring,
        'recurring_frequency': transaction.recurringFrequency,
        'notes': transaction.notes,
      })
          .eq('id', transaction.id)
          .select('''
            *,
            categories (*)
          ''')
          .single();

      Category? category;
      if (response['categories'] != null && response['categories'] is Map) {
        category = Category.fromJson(response['categories']);
      }
      return Transaction.fromJson(response, category: category);
    } catch (e) {
      print('Error updating transaction: $e');
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(int transactionId) async {
    try {
      await _supabase
          .from('transactions')
          .delete()
          .eq('id', transactionId);
    } catch (e) {
      print('Error deleting transaction: $e');
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // Get monthly summary
  Future<Map<String, dynamic>> getMonthlySummary(int userId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      final transactions = await getTransactionsByDateRange(
          userId,
          startOfMonth,
          endOfMonth
      );

      double totalIncome = 0;
      double totalExpense = 0;
      Map<int, double> categorySpending = {};

      for (var t in transactions) {
        if (t.type == 'income') {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
          if (t.categoryId != null) {
            categorySpending[t.categoryId!] =
                (categorySpending[t.categoryId!] ?? 0) + t.amount;
          }
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
        'categorySpending': categorySpending,
        'transactionCount': transactions.length,
      };
    } catch (e) {
      print('Error getting monthly summary: $e');
      throw Exception('Failed to get monthly summary: $e');
    }
  }
}