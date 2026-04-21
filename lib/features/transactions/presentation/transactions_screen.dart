import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'transactions_controller.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/vn_money_formatter.dart';
import '../../transactions/domain/transaction.dart';
import '../../categories/domain/category.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsControllerProvider);
    final cats = ref.watch(categoriesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch'),
      ),
      body: state.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const EmptyStateView(
              title: 'Chưa có giao dịch',
              subtitle: 'Thêm giao dịch để quản lý chi tiêu rõ ràng hơn.',
            );
          }

          final catList = cats.valueOrNull ?? [];
          final grouped = _groupTransactionsByDay(transactions, catList);
          if (grouped.isEmpty) {
            return const EmptyStateView(
              title: 'Chưa có giao dịch',
              subtitle: 'Thêm giao dịch để quản lý chi tiêu rõ ràng hơn.',
            );
          }

          final sections = grouped.entries.toList();
          final income = transactions
              .where((e) => e.type == 'income')
              .fold<double>(0, (sum, e) => sum + e.amount);
          final expense = transactions
              .where((e) => e.type == 'expense')
              .fold<double>(0, (sum, e) => sum + e.amount);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: sections.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, sectionIndex) {
              if (sectionIndex == 0) {
                return _TransactionsSummaryCard(
                  transactionCount: transactions.length,
                  income: income,
                  expense: expense,
                );
              }

              final section = sections[sectionIndex - 1];
              return _DateSection(
                date: section.key,
                items: section.value,
                onDelete: (id) => ref
                    .read(transactionsControllerProvider.notifier)
                    .removeTransaction(id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => EmptyStateView(
          title: 'Lỗi dữ liệu',
          subtitle: err.toString(),
          asset: 'assets/illustrations/error_state.svg',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transaction-add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<DateTime, List<_TransactionViewItem>> _groupTransactionsByDay(
    List<TransactionEntity> transactions,
    List<CategoryEntity> categories,
  ) {
    final grouped = <DateTime, List<_TransactionViewItem>>{};

    for (final t in transactions) {
      if (categories.isEmpty) continue;
      final cat = categories.firstWhere(
        (c) => c.id == t.categoryId,
        orElse: () => categories.first,
      );

      final dayKey = DateTime(t.date.year, t.date.month, t.date.day);
      grouped.putIfAbsent(dayKey, () => <_TransactionViewItem>[]);
      grouped[dayKey]!.add(_TransactionViewItem(transaction: t, category: cat));
    }

    return grouped;
  }
}

class _DateSection extends StatelessWidget {
  final DateTime date;
  final List<_TransactionViewItem> items;
  final ValueChanged<String> onDelete;

  const _DateSection({
    required this.date,
    required this.items,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final net = items.fold<double>(0, (sum, item) {
      final sign = item.transaction.type == 'expense' ? -1.0 : 1.0;
      return sum + (item.transaction.amount * sign);
    });
    final isPositive = net >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateHeader(date),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: (isPositive ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.12),
                ),
                child: Text(
                  '${isPositive ? '+' : '-'}${VnMoneyFormatter.money(net.abs())}',
                  style: TextStyle(
                    color: isPositive ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(
          items.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 10),
            child: _TransactionRow(
              item: items[index],
              onDelete: () => onDelete(items[index].transaction.id),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Hôm nay';
    if (target == yesterday) return 'Hôm qua';
    if (target.year == today.year && target.month == today.month) {
      return 'Tháng này • ${DateFormat('dd/MM').format(target)}';
    }
    return DateFormat('MM/yyyy • dd/MM').format(target);
  }
}

class _TransactionsSummaryCard extends StatelessWidget {
  final int transactionCount;
  final double income;
  final double expense;

  const _TransactionsSummaryCard({
    required this.transactionCount,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Giao dịch',
              value: '$transactionCount',
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Thu',
              value: VnMoneyFormatter.money(income),
              color: AppColors.income,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Chi',
              value: VnMoneyFormatter.money(expense),
              color: AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final _TransactionViewItem item;
  final VoidCallback onDelete;

  const _TransactionRow({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final transaction = item.transaction;
    final category = item.category;
    final isExpense = transaction.type == 'expense';
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final categoryColor = _hexToColor(category.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category.name.isEmpty
                          ? '?'
                          : category.name.characters.first.toUpperCase(),
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _vnCategoryName(category.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          transaction.note.trim().isEmpty
                              ? 'Không có ghi chú'
                              : transaction.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isExpense ? '-' : '+'}${VnMoneyFormatter.money(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: amountColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('HH:mm').format(transaction.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onDelete,
              child: Ink(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.expense.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.isEmpty) return AppColors.primary;

    final normalized = clean.length == 6 ? 'FF$clean' : clean;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return AppColors.primary;
    return Color(value);
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

class _TransactionViewItem {
  final TransactionEntity transaction;
  final CategoryEntity category;

  const _TransactionViewItem({
    required this.transaction,
    required this.category,
  });
}
