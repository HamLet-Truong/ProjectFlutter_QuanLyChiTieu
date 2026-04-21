import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/vn_money_formatter.dart';
import 'transactions_controller.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../categories/domain/category.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _type = 'expense';
  String? _catId;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_catId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục giao dịch')),
      );
      return;
    }

    final amount = VnMoneyFormatter.parseToInt(_amountCtrl.text).toDouble();
    if (amount <= 0) return;
    ref.read(transactionsControllerProvider.notifier)
       .addTransaction(
          amount,
          _noteCtrl.text,
          _type,
          _catId!,
          date: _selectedDate,
       )
       .then((_) {
           if (mounted) context.pop();
       });
  }

  String get _typeHint {
    return _type == 'expense'
        ? 'Ghi lại khoản chi để kiểm soát ngân sách tốt hơn'
        : 'Ghi lại khoản thu để theo dõi dòng tiền chính xác';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catsState = ref.watch(categoriesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm giao dịch mới')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _typeHint,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Chi tiêu')),
                    ButtonSegment(value: 'income', label: Text('Thu nhập')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (val) {
                    setState(() {
                      _type = val.first;
                      _catId = null;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
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
                      const Text(
                        'Số tiền',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _amountCtrl,
                        decoration: const InputDecoration(
                          hintText: '0',
                          suffixText: 'đ',
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.end,
                        inputFormatters: [VnMoneyInputFormatter()],
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền';
                          final parsed = VnMoneyFormatter.parseToInt(v);
                          if (parsed <= 0) return 'Số tiền không hợp lệ';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickDate,
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        const Text(
                          'Ngày giao dịch',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Danh mục',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 10),
                catsState.when(
                  data: (cats) {
                    final filtered = cats.where((c) => c.type == _type).toList();
                    if (filtered.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Chưa có danh mục phù hợp.'),
                      );
                    }
                    return _CategoryGrid(
                      categories: filtered,
                      selectedId: _catId,
                      onSelected: (id) => setState(() => _catId = id),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Không tải được danh mục: $e'),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    hintText: 'Ví dụ: Cà phê, gửi xe, tiền điện...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Lưu giao dịch'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final crossAxisCount = compact ? 2 : 3;

        return GridView.builder(
          itemCount: categories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: compact ? 2.35 : 2.05,
          ),
          itemBuilder: (context, index) {
            final c = categories[index];
            final selected = c.id == selectedId;
            final color = _hexToColor(c.colorHex);

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(c.id),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.14)
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? color
                        : Theme.of(context).dividerColor.withValues(alpha: 0.12),
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c.name.isEmpty ? '?' : c.name.characters.first.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _vnCategoryName(c.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
