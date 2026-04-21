import '../../../core/network/api_service.dart';
import '../domain/budget.dart';

class BudgetsRemoteDataSource {
  final ApiService _api;

  BudgetsRemoteDataSource(this._api);

  Future<List<BudgetEntity>> fetchBudgets() async {
    final res = await _api.get('/budgets');
    final list = (res as Map<String, dynamic>)['budgets'] as List<dynamic>;
    return list
        .map((item) => BudgetEntity.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> createBudget(BudgetEntity budget) async {
    await _api.post('/budgets', body: {
      'categoryId': budget.categoryId,
      'limitAmount': budget.limitAmount,
      'startDate': budget.startDate.toIso8601String(),
      'endDate': budget.endDate.toIso8601String(),
    });
  }

  Future<void> updateBudget(BudgetEntity budget) async {
    await _api.put('/budgets/${budget.id}', body: {
      'categoryId': budget.categoryId,
      'limitAmount': budget.limitAmount,
      'startDate': budget.startDate.toIso8601String(),
      'endDate': budget.endDate.toIso8601String(),
    });
  }

  Future<void> deleteBudget(String id) async {
    await _api.delete('/budgets/$id');
  }
}
