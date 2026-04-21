import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'budget_controller.dart';
import '../../transactions/presentation/transactions_controller.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../../core/utils/vn_money_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/theme/app_colors.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bState = ref.watch(budgetControllerProvider);
    final tState = ref.watch(transactionsControllerProvider);
    final cats = ref.watch(categoriesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ngân sách')),
      body: bState.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return const EmptyStateView(
              title: 'Chưa có ngân sách',
              subtitle: 'Tạo ngân sách để theo dõi giới hạn chi tiêu từng danh mục.',
              asset: 'assets/illustrations/empty_state.svg',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final b = budgets[index];
              final categoryList = cats.valueOrNull ?? [];
              String catName = 'Khác';
              if (categoryList.isNotEmpty) {
                final found = categoryList.where((c) => c.id == b.categoryId);
                catName = found.isNotEmpty ? found.first.name : categoryList.first.name;
              }
              catName = _vnCategoryName(catName);
              
              double spent = 0;
              final tList = tState.valueOrNull ?? [];
              for(var t in tList) {
                  if(t.categoryId == b.categoryId && t.type == 'expense' && t.date.isAfter(b.startDate) && t.date.isBefore(b.endDate)) {
                      spent += t.amount;
                  }
              }

              final progress = (spent / b.limitAmount).clamp(0.0, 1.0);
              final isOver = spent >= b.limitAmount;
              final isWarning = !isOver && progress > 0.8;
              final statusColor = isOver
                  ? AppColors.expense
                  : (isWarning ? Colors.orange : AppColors.income);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 18,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ngân sách $catName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () => ref.read(budgetControllerProvider.notifier).removeBudget(b.id),
                          child: Ink(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color: AppColors.expense.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.expense.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${VnMoneyFormatter.money(spent)} / ${VnMoneyFormatter.money(b.limitAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOver
                          ? 'Đã vượt ngân sách'
                          : (isWarning
                              ? 'Sắp chạm mức giới hạn'
                              : 'Ngân sách đang trong mức an toàn'),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Lỗi $e')),
      ),
      floatingActionButton: FloatingActionButton(
         child: const Icon(Icons.add),
         onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) {
                final ctrl = TextEditingController();
                final expenseCats = (cats.valueOrNull ?? []).where((c) => c.type == 'expense').toList();
                String? selectedCatId = expenseCats.isNotEmpty ? expenseCats.first.id : null;
                return AlertDialog(
                  title: const Text('Thêm ngân sách'),
                  content: StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedCatId,
                            decoration: const InputDecoration(labelText: 'Danh mục'),
                            items: expenseCats
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(_vnCategoryName(c.name)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setStateDialog(() => selectedCatId = value),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: ctrl,
                            decoration: const InputDecoration(labelText: 'Số tiền', suffixText: 'đ'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [VnMoneyInputFormatter()],
                          ),
                        ],
                      );
                    },
                  ),
                  actions: [
                     TextButton(
                       onPressed: () => Navigator.pop(ctx),
                       child: const Text('Hủy'),
                     ),
                     TextButton(onPressed: () {
                         if(ctrl.text.isNotEmpty && selectedCatId != null) {
                         final amount = VnMoneyFormatter.parseToInt(ctrl.text).toDouble();
                         if (amount <= 0) return;
                         ref.read(budgetControllerProvider.notifier).addBudget(selectedCatId!, amount, DateTime.now().subtract(const Duration(days: 30)), DateTime.now().add(const Duration(days: 30)));
                             Navigator.pop(ctx);
                         }
                     }, child: const Text('Lưu'))
                  ]
                );
              }
            );
         }
      )
    );
  }
}
