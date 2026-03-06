import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import 'auth_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'category_provider.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;

  if (userId == null) return [];

  final transactionService = ref.watch(transactionServiceProvider);
  return transactionService.getUserTransactions(userId);
});

final recentTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;

  if (userId == null) return [];

  final transactionService = ref.watch(transactionServiceProvider);
  return transactionService.getRecentTransactions(userId);
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final Ref ref;

  TransactionNotifier(this.ref) : super([]);

  Future<void> loadTransactions() async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    final transactionService = ref.read(transactionServiceProvider);
    state = await transactionService.getUserTransactions(userId);
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    final transactionService = ref.read(transactionServiceProvider);
    final newTransaction = await transactionService.createTransaction(transaction);
    state = [newTransaction, ...state];
    return newTransaction;
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final transactionService = ref.read(transactionServiceProvider);
    final updatedTransaction = await transactionService.updateTransaction(transaction);

    state = state.map((t) {
      return t.id == updatedTransaction.id ? updatedTransaction : t;
    }).toList();

    return updatedTransaction;
  }

  Future<void> deleteTransaction(int transactionId) async {
    final transactionService = ref.read(transactionServiceProvider);
    await transactionService.deleteTransaction(transactionId);
    state = state.where((t) => t.id != transactionId).toList();
  }

  Future<Map<String, dynamic>> getMonthlySummary(DateTime month) async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null) return {};

    final transactionService = ref.read(transactionServiceProvider);
    return transactionService.getMonthlySummary(userId, month);
  }

  List<Transaction> getExpenses() {
    return state.where((t) => t.type == 'expense').toList();
  }

  List<Transaction> getIncome() {
    return state.where((t) => t.type == 'income').toList();
  }

  double getTotalExpenses() {
    return state
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalIncome() {
    return state
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
  }

  Map<int, double> getCategorySpending() {
    Map<int, double> spending = {};
    for (var t in state.where((t) => t.type == 'expense')) {
      if (t.categoryId != null) {
        spending[t.categoryId!] = (spending[t.categoryId!] ?? 0) + t.amount;
      }
    }
    return spending;
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier(ref);
});

// Summary provider
final summaryProvider = Provider<Map<String, dynamic>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final categories = ref.watch(categoryProvider);

  double totalIncome = 0;
  double totalExpense = 0;
  Map<String, double> categorySpending = {};

  for (var t in transactions) {
    if (t.type == 'income') {
      totalIncome += t.amount;
    } else {
      totalExpense += t.amount;
      if (t.category != null) {
        categorySpending[t.category!.name] =
            (categorySpending[t.category!.name] ?? 0) + t.amount;
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
});