import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../transactions/presentation/transactions_controller.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/utils/vn_money_formatter.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _filter = 'month';

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
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsControllerProvider);
    final cats = ref.watch(categoriesControllerProvider);

    return Scaffold(
         appBar: AppBar(title: const Text('Báo cáo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
                     padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: SizedBox(
                 width: double.infinity,
                 child: SegmentedButton<String>(
                            showSelectedIcon: false,
                   style: ButtonStyle(
                                 textStyle: const WidgetStatePropertyAll(
                                    TextStyle(
                                       fontSize: 13,
                                       fontWeight: FontWeight.w700,
                                       height: 1.0,
                                    ),
                                 ),
                                 padding: const WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                                 ),
                                 minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
                                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                 visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                         if (states.contains(WidgetState.selected)) return AppColors.primary;
                         return Colors.transparent;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                         if (states.contains(WidgetState.selected)) return Colors.white;
                         return AppColors.textPrimary;
                      }),
                   ),
                   segments: const [
                                 ButtonSegment(
                                    value: 'day',
                                    label: Text('Ngày', maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
                                 ),
                                 ButtonSegment(
                                    value: 'week',
                                    label: Text('Tuần', maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
                                 ),
                                 ButtonSegment(
                                    value: 'month',
                                    label: Text('Tháng', maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
                                 ),
                                 ButtonSegment(
                                    value: 'year',
                                    label: Text('Năm', maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
                                 ),
                   ],
                   selected: {_filter},
                   onSelectionChanged: (val) => setState(() => _filter = val.first),
                 ),
              ),
            ),
          ),
          Expanded(
            child: state.when(
              data: (transactions) {
                 final filtered = transactions.where((t) {
                   final now = DateTime.now();
                            if (_filter == 'day') {
                               return now.day == t.date.day && now.month == t.date.month && now.year == t.date.year;
                            }
                   if (_filter == 'week') return now.difference(t.date).inDays <= 7;
                   if (_filter == 'month') return now.month == t.date.month && now.year == t.date.year;
                   return now.year == t.date.year;
                 }).toList();

                 double income = 0;
                 double expense = 0;
                 Map<String, double> expensesByCat = {};
                 
                 for (var t in filtered) {
                    if (t.type == 'income') income += t.amount;
                    if (t.type == 'expense') {
                       expense += t.amount;
                       expensesByCat[t.categoryId] = (expensesByCat[t.categoryId] ?? 0) + t.amount;
                    }
                 }

                         if (filtered.isEmpty) {
                              return const EmptyStateView(
                                 title: 'Chưa có dữ liệu',
                                 subtitle: 'Không có giao dịch trong kỳ bạn đã chọn.',
                                 asset: 'assets/illustrations/empty_state.svg',
                              );
                         }

                         final sortedCatEntries = expensesByCat.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                         final maxBase = income > expense ? income : expense;

                 return CustomScrollView(
                   slivers: [
                      SliverToBoxAdapter(
                         child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                                        child: Row(
                                           children: [
                                              Expanded(
                                                 child: _OverviewCard(
                                                    label: 'Thu nhập',
                                                    value: VnMoneyFormatter.money(income),
                                                    color: AppColors.income,
                                                 ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                 child: _OverviewCard(
                                                    label: 'Chi tiêu',
                                                    value: VnMoneyFormatter.money(expense),
                                                    color: AppColors.expense,
                                                 ),
                                              ),
                                           ],
                                        ),
                                     ),
                                 ),
                                 SliverToBoxAdapter(
                                     child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                                        child: const Text(
                                           'Tổng quan thu chi',
                                           style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                        ),
                         )
                      ),
                      SliverToBoxAdapter(
                                     child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16),
                                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                                        decoration: BoxDecoration(
                                           color: Theme.of(context).cardTheme.color,
                                           borderRadius: BorderRadius.circular(16),
                                           border: Border.all(
                                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                           ),
                                        ),
                                        child: SizedBox(
                                             height: 220,
                                             child: BarChart(
                                                BarChartData(
                                                   alignment: BarChartAlignment.spaceAround,
                                                   maxY: maxBase <= 0 ? 100000 : (maxBase * 1.2),
                                                   gridData: FlGridData(
                                                      show: true,
                                                      drawVerticalLine: false,
                                                      horizontalInterval: (maxBase <= 0 ? 50000 : (maxBase / 3))
                                                            .clamp(50000, double.infinity)
                                                            .toDouble(),
                                                      getDrawingHorizontalLine: (value) => FlLine(
                                                         color: AppColors.border,
                                                         strokeWidth: 1,
                                                      ),
                                                   ),
                                                   borderData: FlBorderData(show: false),
                                                   barGroups: [
                                                                               BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: income, color: AppColors.income, width: 26, borderRadius: BorderRadius.circular(7))]),
                                                                               BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: expense, color: AppColors.expense, width: 26, borderRadius: BorderRadius.circular(7))]),
                                                   ],
                                                   titlesData: FlTitlesData(
                                                       show: true,
                                                       bottomTitles: AxisTitles(
                                                            sideTitles: SideTitles(
                                                                showTitles: true,
                                                                getTitlesWidget: (v, m) => Padding(
                                                                   padding: const EdgeInsets.only(top: 8),
                                                                   child: Text(v == 0 ? 'Thu' : 'Chi'),
                                                                ),
                                                            )
                                                                                 ),
                                                                                 leftTitles: AxisTitles(
                                                                                     sideTitles: SideTitles(
                                                                                        showTitles: true,
                                                                                        reservedSize: 44,
                                                                                        getTitlesWidget: (value, meta) {
                                                                                           return Text(
                                                                                              value <= 0 ? '' : '${(value / 1000).round()}k',
                                                                                              style: const TextStyle(
                                                                                                 fontSize: 10,
                                                                                                 color: AppColors.textSecondary,
                                                                                              ),
                                                                                           );
                                                                                        },
                                                                                     ),
                                                                                 ),
                                                                                 rightTitles: const AxisTitles(
                                                                                     sideTitles: SideTitles(showTitles: false),
                                                                                 ),
                                                                                 topTitles: const AxisTitles(
                                                                                     sideTitles: SideTitles(showTitles: false),
                                                                                 ),
                                                   )
                                                )
                                             )
                                        ),
                                     ),
                      ),
                                 SliverToBoxAdapter(
                                    child: Padding(
                                                         padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                       child: Row(
                                          children: [
                                             _LegendDot(color: AppColors.income, label: 'Thu nhập: ${VnMoneyFormatter.money(income)}'),
                                             const SizedBox(width: 12),
                                             _LegendDot(color: AppColors.expense, label: 'Chi tiêu: ${VnMoneyFormatter.money(expense)}'),
                                          ],
                                       ),
                                    ),
                                 ),
                      SliverToBoxAdapter(
                         child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                                        child: const Text(
                                           'Chi tiêu theo danh mục',
                                           style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                        ),
                         )
                      ),
                      SliverList(
                         delegate: SliverChildBuilderDelegate((context, index) {
                                          final catId = sortedCatEntries[index].key;
                                          final amount = sortedCatEntries[index].value;
                                          final categoryList = cats.valueOrNull ?? [];
                                          String catName = 'Khác';
                                          if (categoryList.isNotEmpty) {
                                             final found = categoryList.where((c) => c.id == catId);
                                             catName = found.isNotEmpty ? found.first.name : categoryList.first.name;
                                          }
                                          catName = _vnCategoryName(catName);
                                          final ratio = expense <= 0 ? 0.0 : (amount / expense).clamp(0.0, 1.0);
                            return Container(
                               margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                              decoration: BoxDecoration(
                                                 color: Theme.of(context).cardTheme.color,
                                                 borderRadius: BorderRadius.circular(16),
                                                 border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                                              ),
                                              child: Column(
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                       Row(
                                                          children: [
                                                             CircleAvatar(
                                                                radius: 18,
                                                                backgroundColor: AppColors.expense.withValues(alpha: 0.12),
                                                                child: const Icon(Icons.category_rounded, color: AppColors.expense, size: 18),
                                                             ),
                                                             const SizedBox(width: 10),
                                                             Expanded(
                                                                child: Text(catName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                             ),
                                                             Text(
                                                                VnMoneyFormatter.money(amount),
                                                                style: const TextStyle(
                                                                   color: AppColors.expense,
                                                                   fontWeight: FontWeight.bold,
                                                                   fontSize: 15,
                                                                ),
                                                             ),
                                                          ],
                                                       ),
                                                       const SizedBox(height: 8),
                                                       ClipRRect(
                                                          borderRadius: BorderRadius.circular(99),
                                                          child: LinearProgressIndicator(
                                                             value: ratio,
                                                             minHeight: 7,
                                                             backgroundColor: AppColors.border,
                                                             valueColor: const AlwaysStoppedAnimation<Color>(AppColors.expense),
                                                          ),
                                                       ),
                                                    ],
                                              ),
                            );
                                     }, childCount: sortedCatEntries.length)
                      )
                   ]
                 );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
                     error: (err, stack) => Center(child: Text('Lỗi: $err')),
            )
          )
        ]
      )
    );
  }
}

class _LegendDot extends StatelessWidget {
   final Color color;
   final String label;

   const _LegendDot({required this.color, required this.label});

   @override
   Widget build(BuildContext context) {
      return Expanded(
         child: Row(
            children: [
               Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
               ),
               const SizedBox(width: 6),
               Expanded(
                  child: Text(
                     label,
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                     style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
               ),
            ],
         ),
      );
   }
}

class _OverviewCard extends StatelessWidget {
   final String label;
   final String value;
   final Color color;

   const _OverviewCard({
      required this.label,
      required this.value,
      required this.color,
   });

   @override
   Widget build(BuildContext context) {
      return Container(
         constraints: const BoxConstraints(minHeight: 82),
         padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
         decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
               color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            ),
         ),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                  label,
                  style: const TextStyle(
                     color: AppColors.textSecondary,
                     fontWeight: FontWeight.w600,
                     fontSize: 12,
                  ),
               ),
               const SizedBox(height: 8),
               Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                     color: color,
                     fontWeight: FontWeight.w800,
                     fontSize: 15,
                     height: 1.05,
                  ),
               ),
            ],
         ),
      );
   }
}
