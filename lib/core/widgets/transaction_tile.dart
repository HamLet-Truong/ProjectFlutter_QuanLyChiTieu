import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/vn_money_formatter.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/categories/domain/category.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final CategoryEntity category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TransactionTile({super.key, required this.transaction, required this.category, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    return Container(
       margin: const EdgeInsets.only(bottom: 12),
       decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
       ),
       child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
             backgroundColor: isExpense ? AppColors.expense.withValues(alpha: 0.1) : AppColors.income.withValues(alpha: 0.1),
             child: Icon(Icons.category, color: isExpense ? AppColors.expense : AppColors.income),
          ),
          title: Text(_vnCategoryName(category.name), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(transaction.note.trim().isEmpty ? 'Không có ghi chú' : transaction.note, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          trailing: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
                Text(
                   '${isExpense ? '-' : '+'}${VnMoneyFormatter.money(transaction.amount)}',
                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isExpense ? AppColors.expense : AppColors.income)
                ),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20), color: Colors.red[300], onPressed: onDelete)
             ]
          )
       )
    );
  }

   String _vnCategoryName(String raw) {
      final key = raw.toLowerCase().trim();
      const mapped = {
         'food': 'Ăn uống',
         'transport': 'Di chuyển',
         'salary': 'Lương',
         'health': 'Sức khỏe',
         'entertainment': 'Giải trí',
         'investment': 'Đầu tư',
         'shopping': 'Mua sắm',
         'bills': 'Hóa đơn',
         'house': 'Nhà ở',
         'bonus': 'Thưởng',
         'education': 'Giáo dục',
      };
      return mapped[key] ?? raw;
   }
}
