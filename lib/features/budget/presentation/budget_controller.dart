import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../domain/budget.dart';
import '../data/budget_repository.dart';

part 'budget_controller.g.dart';

@riverpod
class BudgetController extends _$BudgetController {
  @override
  FutureOr<List<BudgetEntity>> build() async {
    return ref.read(budgetRepositoryProvider).getBudgets();
  }

  Future<void> addBudget(String categoryId, double amount, DateTime start, DateTime end) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(budgetRepositoryProvider);
      await repo.saveBudget(BudgetEntity(
        id: const Uuid().v4(),
        categoryId: categoryId,
        limitAmount: amount,
        startDate: start,
        endDate: end,
      ));
      return repo.getBudgets();
    });
  }

  Future<void> removeBudget(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(budgetRepositoryProvider);
      await repo.deleteBudget(id);
      return repo.getBudgets();
    });
  }
}
