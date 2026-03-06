import 'category_model.dart';

class Transaction {
  final int id;
  final int userId;
  final int? categoryId;
  final double amount;
  final String description;
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String? paymentMethod;
  final bool isRecurring;
  final String? recurringFrequency;
  final String? notes;
  final DateTime createdAt;
  final Category? category;

  Transaction({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.description,
    required this.type,
    required this.date,
    this.paymentMethod,
    this.isRecurring = false,
    this.recurringFrequency,
    this.notes,
    required this.createdAt,
    this.category,
  });

  factory Transaction.fromJson(Map<String, dynamic> json, {Category? category}) {
    return Transaction(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      type: json['transaction_type'] as String,
      date: DateTime.parse(json['transaction_date'] as String),
      paymentMethod: json['payment_method'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringFrequency: json['recurring_frequency'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'transaction_type': type,
      'transaction_date': date.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'notes': notes,
    };
  }
}