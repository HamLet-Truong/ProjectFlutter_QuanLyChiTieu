import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../domain/category.dart';
import 'categories_controller.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoriesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Danh mục')),
      body: state.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyStateView(
              title: 'Chưa có danh mục',
              subtitle: 'Thêm danh mục để phân loại thu chi dễ hơn.',
            );
          }

          final expenses = categories.where((c) => c.type == 'expense').toList();
          final incomes = categories.where((c) => c.type == 'income').toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: 2,
            itemBuilder: (context, index) {
              final isExpense = index == 0;
              final sectionData = isExpense ? expenses : incomes;
              final sectionTitle = isExpense ? 'Chi tiêu' : 'Thu nhập';

              return Padding(
                padding: EdgeInsets.only(bottom: index == 0 ? 18 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (sectionData.isEmpty)
                      const Text(
                        'Chưa có mục nào.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ...sectionData.map((cat) {
                      final color = _hexToColor(cat.colorHex);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                cat.name.isEmpty ? '?' : cat.name.characters.first.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _vnCategoryName(cat.name),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isExpense ? 'Danh mục chi tiêu' : 'Danh mục thu nhập',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(9),
                              onTap: () => _openCategoryDialog(
                                context,
                                ref,
                                initial: cat,
                              ),
                              child: Ink(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(9),
                              onTap: () => ref
                                  .read(categoriesControllerProvider.notifier)
                                  .removeCategory(cat.id),
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
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Không tải được danh mục: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _openCategoryDialog(context, ref),
      ),
    );
  }

  Future<void> _openCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    CategoryEntity? initial,
  }) async {
    final ctrl = TextEditingController(text: initial?.name ?? '');
    String type = initial?.type ?? 'expense';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(initial == null ? 'Thêm danh mục' : 'Chỉnh sửa danh mục'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Chi tiêu')),
                      ButtonSegment(value: 'income', label: Text('Thu nhập')),
                    ],
                    selected: {type},
                    onSelectionChanged: (v) => setStateDialog(() => type = v.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(labelText: 'Tên danh mục'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;

                if (initial == null) {
                  ref.read(categoriesControllerProvider.notifier).addCategory(name, type);
                } else {
                  ref.read(categoriesControllerProvider.notifier).editCategory(
                        CategoryEntity(
                          id: initial.id,
                          name: name,
                          iconPath: initial.iconPath,
                          colorHex: initial.colorHex,
                          type: type,
                        ),
                      );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Lưu'),
            )
          ],
        );
      },
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

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.isEmpty) return AppColors.primary;
    final normalized = clean.length == 6 ? 'FF$clean' : clean;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return AppColors.primary;
    return Color(value);
  }
}
