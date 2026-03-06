import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final Future<void> Function()? onDelete;
  final bool showTime;
  final String? timeString;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
    this.showTime = false,
    this.timeString,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final amountColor = isExpense ? Colors.red : Colors.green;
    final amountPrefix = isExpense ? '- ' : '+ ';
    DateTime dateTime = DateTime.parse(timeString??DateTime.now().toString());

    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog before dismissing
        if (onDelete != null) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Transaction'),
              content: Text(
                'Are you sure you want to delete this transaction?\n\n'
                    'Description: ${transaction.description}\n'
                    'Amount: \$${transaction.amount.toStringAsFixed(2)}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        }
        return false;
      },
      onDismissed: (_) {
        // This won't be called because we handle deletion in confirmDismiss
        // But we keep it for backward compatibility
        if (onDelete != null) {
          onDelete!();
        }
      },
      child: ListTile(
        onTap: onTap,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 0,
        ),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: transaction.category != null
                ? Color(
              int.parse(
                transaction.category!.color.replaceFirst('#', '0xFF'),
              ),
            ).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            transaction.category != null
                ? _getIconData(transaction.category!.icon)
                : Icons.category,
            color: transaction.category != null
                ? Color(
              int.parse(
                transaction.category!.color.replaceFirst('#', '0xFF'),
              ),
            )
                : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: showTime && timeString != null
            ? Text(
          '${transaction.category?.name ?? 'Uncategorized'}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        )
            : Text(
          transaction.category?.name ?? 'Uncategorized',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$amountPrefix\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amountColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            if (showTime && timeString != null)
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal()),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              )
            else
              Text(
                _formatDate(transaction.date),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      final difference = now.difference(date).inDays;
      if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'trending_up':
        return Icons.trending_up;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}