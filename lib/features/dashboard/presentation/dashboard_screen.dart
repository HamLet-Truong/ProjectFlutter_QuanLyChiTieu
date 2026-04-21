import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/vn_money_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../transactions/presentation/transactions_controller.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../transactions/domain/transaction.dart';
import '../../budget/presentation/budget_controller.dart';
import '../../settings/data/settings_local_storage.dart';

final profileAvatarPathProvider = FutureProvider.autoDispose<String?>((ref) async {
   return SettingsLocalStorage.getProfileAvatarPath();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tState = ref.watch(transactionsControllerProvider);
    final cState = ref.watch(categoriesControllerProvider);
      final bState = ref.watch(budgetControllerProvider);
      final authState = ref.watch(authControllerProvider);
      final avatarPath = ref.watch(profileAvatarPathProvider).valueOrNull;
      final displayName = authState.valueOrNull?.name.trim();

    return Scaffold(
      body: SafeArea(
            child: RefreshIndicator(
               onRefresh: () async {
                  ref.invalidate(transactionsControllerProvider);
                  ref.invalidate(categoriesControllerProvider);
               },
               child: tState.when(
                  data: (transactions) {
                     double income = 0;
                     double expense = 0;
                     for (final t in transactions) {
                        if (t.type == 'income') income += t.amount;
                        if (t.type == 'expense') expense += t.amount;
                     }

                     final balance = income - expense;
                     final recent = transactions.take(6).toList();
                     final trendData = _buildSevenDayNetSeries(transactions);
                     final budgets = bState.valueOrNull ?? [];
                     double budgetLimit = 0;
                     double budgetSpent = 0;
                     final now = DateTime.now();
                     for (final budget in budgets) {
                        if (now.isBefore(budget.startDate) || now.isAfter(budget.endDate)) {
                           continue;
                        }
                        budgetLimit += budget.limitAmount;
                        for (final tx in transactions) {
                           if (tx.type != 'expense') continue;
                           if (tx.categoryId != budget.categoryId) continue;
                           if (tx.date.isAfter(budget.startDate) && tx.date.isBefore(budget.endDate)) {
                              budgetSpent += tx.amount;
                           }
                        }
                     }
                     final budgetRemaining = budgetLimit > 0 ? (budgetLimit - budgetSpent) : null;

                     return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                           SliverToBoxAdapter(
                              child: Padding(
                                 padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                                 child: _DashboardHeader(
                                    userName: (displayName == null || displayName.isEmpty)
                                          ? 'Bạn'
                                          : displayName,
                                    avatarPath: avatarPath,
                                 ),
                              ),
                           ),
                           SliverToBoxAdapter(
                              child: Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 16),
                                 child: _BalanceCardProxy(
                                    balance: balance,
                                    income: income,
                                    expense: expense,
                                    budgetRemaining: budgetRemaining,
                                 ),
                              ),
                           ),
                           SliverToBoxAdapter(
                              child: Padding(
                                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                 child: _QuickActionsRow(
                                    onAdd: () => context.push('/transaction-add'),
                                    onTransactions: () => context.go('/transactions'),
                                    onCategories: () => context.push('/categories'),
                                    onReports: () => context.go('/reports'),
                                 ),
                              ),
                           ),
                           SliverToBoxAdapter(
                              child: Padding(
                                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                 child: _TrendCard(
                                    trendData: trendData,
                                    totalIncome: income,
                                    totalExpense: expense,
                                 ),
                              ),
                           ),
                           SliverToBoxAdapter(
                              child: Padding(
                                 padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                                 child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                       const Text(
                                          'Giao dịch gần đây',
                                          style: TextStyle(
                                             fontSize: 18,
                                             fontWeight: FontWeight.w800,
                                          ),
                                       ),
                                       TextButton(
                                          onPressed: () => context.go('/transactions'),
                                          child: const Text(
                                             'Xem tất cả',
                                             style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                             ),
                                          ),
                                       ),
                                    ],
                                 ),
                              ),
                           ),
                           if (recent.isEmpty)
                              const SliverToBoxAdapter(
                                 child: Padding(
                                    padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                                    child: EmptyStateView(
                                       title: 'Chưa có giao dịch',
                                      subtitle: 'Nhấn Thêm để ghi lại giao dịch đầu tiên của bạn.',
                                    ),
                                 ),
                              ),
                           if (recent.isNotEmpty)
                              SliverPadding(
                                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
                                 sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                       (context, i) {
                                          final t = recent[i];
                                          final cats = cState.valueOrNull ?? [];
                                          final cat = cats.isNotEmpty
                                                ? cats.firstWhere(
                                                      (c) => c.id == t.categoryId,
                                                      orElse: () => cats.first,
                                                   )
                                                : null;
                                          if (cat == null) return const SizedBox.shrink();

                                          var showDate = true;
                                          if (i > 0) {
                                             final prevT = recent[i - 1];
                                             if (t.date.day == prevT.date.day &&
                                                   t.date.month == prevT.date.month &&
                                                   t.date.year == prevT.date.year) {
                                                showDate = false;
                                             }
                                          }

                                          return Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                                if (showDate)
                                                   Padding(
                                                      padding: const EdgeInsets.only(
                                                         top: 16,
                                                         bottom: 8,
                                                      ),
                                                      child: Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                         decoration: BoxDecoration(
                                                           color: Theme.of(context).cardTheme.color,
                                                           borderRadius: BorderRadius.circular(999),
                                                           border: Border.all(
                                                             color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                                           ),
                                                         ),
                                                         child: Text(
                                                            _formatRelativeDate(t.date),
                                                            style: const TextStyle(
                                                               fontWeight: FontWeight.w700,
                                                               color: AppColors.textSecondary,
                                                               fontSize: 12,
                                                            ),
                                                         ),
                                                      ),
                                                   ),
                                                _RecentTransactionCard(
                                                  transaction: t,
                                                  categoryName: cat.name,
                                                  categoryColorHex: cat.colorHex,
                                                  onDelete: () => ref
                                                      .read(transactionsControllerProvider.notifier)
                                                      .removeTransaction(t.id),
                                                ),
                                             ],
                                          );
                                       },
                                       childCount: recent.length,
                                    ),
                                 ),
                              ),
                        ],
                     );
                  },
                  loading: () => const Center(
                     child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, s) => EmptyStateView(
                     title: 'Không tải được dữ liệu',
                     subtitle: e.toString(),
                     asset: 'assets/illustrations/error_state.svg',
                  ),
               ),
            ),
      ),
    );
  }

  String _formatRelativeDate(DateTime d) {
      final now = DateTime.now();
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
         return 'Hôm nay';
      }

      final yesterday = now.subtract(const Duration(days: 1));
      if (d.year == yesterday.year &&
            d.month == yesterday.month &&
            d.day == yesterday.day) {
         return 'Hôm qua';
      }

      return DateFormat('dd/MM/yyyy').format(d);
  }

   List<double> _buildSevenDayNetSeries(List<TransactionEntity> transactions) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
      final map = <DateTime, double>{};

      for (var i = 0; i < 7; i++) {
         final day = start.add(Duration(days: i));
         map[DateTime(day.year, day.month, day.day)] = 0;
      }

      for (final tx in transactions) {
         final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
         final existing = map[dayKey];
         if (existing == null) continue;
         map[dayKey] = tx.type == 'income'
               ? existing + tx.amount
               : existing - tx.amount;
      }

      return map.values.toList();
   }
}

class _DashboardHeader extends StatelessWidget {
   final String userName;
   final String? avatarPath;

   const _DashboardHeader({
      required this.userName,
      required this.avatarPath,
   });

   @override
   Widget build(BuildContext context) {
      final todayLabel = 'Hôm nay, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}';
      final hasAvatar = avatarPath != null && avatarPath!.isNotEmpty && File(avatarPath!).existsSync();

      return Container(
         padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
         decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
               color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
         ),
         child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
               Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                     ),
                  ),
                  child: CircleAvatar(
                     radius: 23,
                     backgroundColor: AppColors.border,
                     backgroundImage: hasAvatar ? FileImage(File(avatarPath!)) : null,
                     child: hasAvatar
                           ? null
                           : const Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: AppColors.textSecondary,
                             ),
                  ),
               ),
               const SizedBox(width: 14),
               Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisAlignment: MainAxisAlignment.center,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        Text(
                           todayLabel,
                           style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                           ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                           'Chào mừng bạn quay lại',
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                           ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                           userName,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              height: 1.05,
                           ),
                        ),
                     ],
                  ),
               ),
               Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(13),
                     border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                     ),
                     color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: Material(
                     color: Colors.transparent,
                     child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () {},
                        child: const Center(
                           child: Icon(
                              Icons.notifications_none_rounded,
                              size: 20,
                              color: AppColors.textPrimary,
                           ),
                        ),
                     ),
                  ),
               ),
            ],
         ),
      );
   }
}

class _BalanceCardProxy extends StatelessWidget {
   final double balance;
   final double income;
   final double expense;
   final double? budgetRemaining;

   const _BalanceCardProxy({
      required this.balance,
      required this.income,
      required this.expense,
      required this.budgetRemaining,
   });

  @override
  Widget build(BuildContext context) {
      final spentRate = income <= 0 ? 0.0 : (expense / income).clamp(0.0, 1.0);
      final budgetColor = (budgetRemaining ?? 0) >= 0 ? AppColors.income : AppColors.expense;

      return Stack(
         children: [
            Positioned(
               right: 12,
               top: 12,
               child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     color: AppColors.primary.withValues(alpha: 0.08),
                  ),
               ),
            ),
            Container(
               width: double.infinity,
               padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
               decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).cardTheme.color,
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  boxShadow: [
                     BoxShadow(
                        color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                     ),
                  ],
               ),
               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                           const Text(
                              'Tổng số dư',
                              style: TextStyle(
                                 color: AppColors.textSecondary,
                                 fontSize: 12,
                                 fontWeight: FontWeight.w700,
                              ),
                           ),
                           Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                 color: AppColors.primary.withValues(alpha: 0.1),
                                 borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                 'Tháng này',
                                 style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                 ),
                              ),
                           ),
                        ],
                     ),
                     const SizedBox(height: 10),
                     Text(
                        VnMoneyFormatter.money(balance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                           color: AppColors.textPrimary,
                           fontSize: 32,
                           fontWeight: FontWeight.w800,
                           letterSpacing: -1.0,
                           height: 1.06,
                        ),
                     ),
                     const SizedBox(height: 16),
                     Row(
                        children: [
                           Expanded(
                              child: _balanceStatPill(
                                    context: context,
                                 title: 'Thu nhập',
                                 amount: income,
                                 icon: Icons.south_west_rounded,
                                 color: AppColors.income,
                              ),
                           ),
                           const SizedBox(width: 10),
                           Expanded(
                              child: _balanceStatPill(
                                    context: context,
                                 title: 'Chi tiêu',
                                 amount: expense,
                                 icon: Icons.north_east_rounded,
                                 color: AppColors.expense,
                              ),
                           ),
                        ],
                     ),
                     const SizedBox(height: 14),
                     ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                           value: spentRate,
                           minHeight: 7,
                           backgroundColor: AppColors.border,
                           valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                        '${(spentRate * 100).toStringAsFixed(0)}% thu nhập đã sử dụng',
                        style: const TextStyle(
                           color: AppColors.textSecondary,
                           fontSize: 12,
                           fontWeight: FontWeight.w600,
                        ),
                     ),
                     if (budgetRemaining != null) ...[
                        const SizedBox(height: 10),
                        Container(
                           width: double.infinity,
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                           decoration: BoxDecoration(
                             color: budgetColor.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                 const Text(
                                    'Ngân sách còn lại',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                 ),
                                 Text(
                                    VnMoneyFormatter.money(budgetRemaining!),
                                    style: TextStyle(
                                       fontWeight: FontWeight.w800,
                                       color: budgetColor,
                                    ),
                                 ),
                              ],
                           ),
                        ),
                     ],
                  ],
               ),
            ),
         ],
      );
  }

   Widget _balanceStatPill({
      required BuildContext context,
      required String title,
      required double amount,
      required IconData icon,
      required Color color,
   }) {
      return Container(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
         decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
         ),
         child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
               Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                     color: color.withValues(alpha: 0.18),
                     borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 16),
               ),
               const SizedBox(width: 10),
               Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisAlignment: MainAxisAlignment.center,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        Text(
                           title,
                           style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                           ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                           VnMoneyFormatter.money(amount),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                           ),
                        ),
                     ],
                  ),
               ),
            ],
         ),
      );
   }
}

class _QuickActionsRow extends StatelessWidget {
   final VoidCallback onAdd;
   final VoidCallback onTransactions;
   final VoidCallback onCategories;
   final VoidCallback onReports;

   const _QuickActionsRow({
      required this.onAdd,
      required this.onTransactions,
      required this.onCategories,
      required this.onReports,
   });

   @override
   Widget build(BuildContext context) {
      return LayoutBuilder(
         builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 380;
            final width = isCompact
               ? (constraints.maxWidth - 12) / 2
               : (constraints.maxWidth - 36) / 4;

            return Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  const Text(
                     'Tiện ích nhanh',
                     style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                     ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                     spacing: 12,
                     runSpacing: 12,
                     children: [
                        SizedBox(
                           width: width,
                           child: _QuickActionButton(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Thêm',
                              bgColor: const Color(0xFFEAF0FF),
                              iconColor: const Color(0xFF3457D5),
                              onTap: onAdd,
                           ),
                        ),
                        SizedBox(
                           width: width,
                           child: _QuickActionButton(
                              icon: Icons.receipt_long_rounded,
                              label: 'Lịch sử',
                              bgColor: const Color(0xFFEAFBF4),
                              iconColor: const Color(0xFF17A364),
                              onTap: onTransactions,
                           ),
                        ),
                        SizedBox(
                           width: width,
                           child: _QuickActionButton(
                              icon: Icons.category_outlined,
                              label: 'Danh mục',
                              bgColor: const Color(0xFFFFF4E7),
                              iconColor: const Color(0xFFE28C24),
                              onTap: onCategories,
                           ),
                        ),
                        SizedBox(
                           width: width,
                           child: _QuickActionButton(
                              icon: Icons.query_stats_rounded,
                              label: 'Báo cáo',
                              bgColor: const Color(0xFFFFEFF1),
                              iconColor: const Color(0xFFE25E6D),
                              onTap: onReports,
                           ),
                        ),
                     ],
                  ),
               ],
            );
         },
      );
   }
}

class _QuickActionButton extends StatelessWidget {
   final IconData icon;
   final String label;
   final Color bgColor;
   final Color iconColor;
   final VoidCallback onTap;

   const _QuickActionButton({
      required this.icon,
      required this.label,
      required this.bgColor,
      required this.iconColor,
      required this.onTap,
   });

   @override
   Widget build(BuildContext context) {
      return Material(
         color: Colors.transparent,
         child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: ConstrainedBox(
               constraints: const BoxConstraints(minHeight: 62),
               child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                     color: bgColor,
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                     ),
                  ),
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     crossAxisAlignment: CrossAxisAlignment.center,
                     children: [
                        Container(
                           width: 30,
                           height: 30,
                           decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(9),
                           ),
                           child: Icon(icon, color: iconColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                           child: Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                 fontSize: 12,
                                 fontWeight: FontWeight.w700,
                                 color: AppColors.textPrimary,
                                 height: 1.15,
                              ),
                           ),
                        ),
                     ],
                  ),
               ),
            ),
         ),
      );
   }
}

class _RecentTransactionCard extends StatelessWidget {
   final TransactionEntity transaction;
   final String categoryName;
   final String categoryColorHex;
   final VoidCallback onDelete;

   const _RecentTransactionCard({
      required this.transaction,
      required this.categoryName,
      required this.categoryColorHex,
      required this.onDelete,
   });

   @override
   Widget build(BuildContext context) {
      final isExpense = transaction.type == 'expense';
      final amountColor = isExpense ? AppColors.expense : AppColors.income;
      final color = _hexToColor(categoryColorHex);

      return Container(
         margin: const EdgeInsets.only(bottom: 8),
         padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
         decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
               color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
         ),
         child: Row(
            children: [
               Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                     color: color.withValues(alpha: 0.16),
                     borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                     child: Text(
                        categoryName.isEmpty ? '?' : categoryName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                           color: color,
                           fontWeight: FontWeight.w800,
                           fontSize: 14,
                        ),
                     ),
                  ),
               ),
               const SizedBox(width: 10),
               Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(
                           _vnCategoryName(categoryName),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                           ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                           transaction.note.trim().isEmpty
                              ? 'Không có ghi chú'
                              : transaction.note,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
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
                           color: amountColor,
                           fontWeight: FontWeight.w800,
                           fontSize: 14,
                        ),
                     ),
                     const SizedBox(height: 2),
                     Text(
                        DateFormat('HH:mm').format(transaction.date),
                        style: const TextStyle(
                           color: AppColors.textSecondary,
                           fontSize: 11,
                           fontWeight: FontWeight.w600,
                        ),
                     ),
                  ],
               ),
               const SizedBox(width: 6),
               InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: onDelete,
                  child: Ink(
                     width: 30,
                     height: 30,
                     decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: AppColors.expense.withValues(alpha: 0.1),
                     ),
                     child: Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: AppColors.expense.withValues(alpha: 0.8),
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

class _TrendCard extends StatelessWidget {
   final List<double> trendData;
   final double totalIncome;
   final double totalExpense;

   const _TrendCard({
      required this.trendData,
      required this.totalIncome,
      required this.totalExpense,
   });

   @override
   Widget build(BuildContext context) {
      final net = totalIncome - totalExpense;
      final bool positive = net >= 0;
      final hasAnyTrend = trendData.any((v) => v != 0);

      return Container(
         padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
         decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
               color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
         ),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     const Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text(
                             'Dòng tiền',
                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 2),
                          Text(
                             'Xu hướng thu chi • 7 ngày gần đây',
                             style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                             ),
                          ),
                       ],
                     ),
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                           color: (positive ? AppColors.income : AppColors.expense)
                                 .withValues(alpha: 0.14),
                           borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                           '${positive ? '+' : '-'}${VnMoneyFormatter.money(net.abs())}',
                           style: TextStyle(
                              color: positive ? AppColors.income : AppColors.expense,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                           ),
                        ),
                     ),
                  ],
               ),
               const SizedBox(height: 14),
               if (!hasAnyTrend)
                  Container(
                     width: double.infinity,
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                     decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        ),
                     ),
                     child: const Row(
                        children: [
                           Icon(Icons.show_chart_rounded, color: AppColors.textSecondary),
                           SizedBox(width: 8),
                           Expanded(
                              child: Text(
                                 'Chưa có đủ dữ liệu để hiển thị xu hướng thu chi.',
                                 style: TextStyle(
                                   color: AppColors.textSecondary,
                                   fontSize: 12,
                                   fontWeight: FontWeight.w600,
                                 ),
                              ),
                           ),
                        ],
                     ),
                  )
               else ...[
                  SizedBox(
                     height: 78,
                     child: _TrendSparkline(data: trendData),
                  ),
                  const SizedBox(height: 10),
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: List.generate(
                        7,
                        (index) {
                           final day = DateTime.now().subtract(Duration(days: 6 - index));
                           const weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                           return Text(
                              weekDays[day.weekday - 1],
                              style: const TextStyle(
                                 fontSize: 11,
                                 color: AppColors.textSecondary,
                                 fontWeight: FontWeight.w600,
                              ),
                           );
                        },
                     ),
                  ),
               ],
            ],
         ),
      );
   }
}

class _TrendSparkline extends StatelessWidget {
   final List<double> data;

   const _TrendSparkline({required this.data});

   @override
   Widget build(BuildContext context) {
      return CustomPaint(
         painter: _TrendPainter(
            data: data,
            lineColor: AppColors.primary,
            fillColor: AppColors.primary.withValues(alpha: 0.18),
         ),
         child: const SizedBox.expand(),
      );
   }
}

class _TrendPainter extends CustomPainter {
   final List<double> data;
   final Color lineColor;
   final Color fillColor;

   const _TrendPainter({
      required this.data,
      required this.lineColor,
      required this.fillColor,
   });

   @override
   void paint(Canvas canvas, Size size) {
      if (data.isEmpty) return;
      if (data.length == 1) {
         final p = Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill;
         canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2.4, p);
         return;
      }

      final minValue = data.reduce((a, b) => a < b ? a : b);
      final maxValue = data.reduce((a, b) => a > b ? a : b);
      final range = (maxValue - minValue).abs() < 1 ? 1.0 : (maxValue - minValue);

      final points = <Offset>[];
      for (var i = 0; i < data.length; i++) {
         final x = i / (data.length - 1) * size.width;
         final normalized = (data[i] - minValue) / range;
         final y = size.height - (normalized * (size.height - 10)) - 5;
         points.add(Offset(x, y));
      }

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
         final prev = points[i - 1];
         final current = points[i];
         final controlX = (prev.dx + current.dx) / 2;
         path.cubicTo(controlX, prev.dy, controlX, current.dy, current.dx, current.dy);
      }

      final areaPath = Path.from(path)
         ..lineTo(points.last.dx, size.height)
         ..lineTo(points.first.dx, size.height)
         ..close();

      final gridPaint = Paint()
         ..color = const Color(0xFFE8ECF6)
         ..strokeWidth = 1;
      canvas.drawLine(
         Offset(0, size.height * 0.25),
         Offset(size.width, size.height * 0.25),
         gridPaint,
      );
      canvas.drawLine(
         Offset(0, size.height * 0.75),
         Offset(size.width, size.height * 0.75),
         gridPaint,
      );

      final fillPaint = Paint()
         ..color = fillColor
         ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, fillPaint);

      final linePaint = Paint()
         ..color = lineColor
         ..strokeWidth = 2.5
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);

      final dotPaint = Paint()..color = lineColor;
      canvas.drawCircle(points.last, 3.2, dotPaint);
   }

   @override
   bool shouldRepaint(covariant _TrendPainter oldDelegate) {
      return oldDelegate.data != data ||
            oldDelegate.lineColor != lineColor ||
            oldDelegate.fillColor != fillColor;
  }
}
