import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_service.dart';
import '../../../core/database/database_helper.dart';
import 'budgets_remote_datasource.dart';
import '../domain/budget.dart';

part 'budget_repository.g.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper;
  late final BudgetsRemoteDataSource _remote;

  BudgetRepository({DatabaseHelper? dbHelper, ApiService? apiService})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance {
    _remote = BudgetsRemoteDataSource(apiService ?? ApiService());
  }

  bool get _useRemote => ApiConfig.useRemoteApi;

  Future<List<BudgetEntity>> getBudgets() async {
    if (_useRemote) {
      try {
        return await _remote.fetchBudgets();
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    final maps = await db.query('budgets');
    return maps.map((e) => BudgetEntity.fromMap(e)).toList();
  }

  Future<void> saveBudget(BudgetEntity budget) async {
    if (_useRemote) {
      try {
        await _remote.createBudget(budget);
        return;
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    await db.insert('budgets', budget.toMap());
  }

  Future<void> deleteBudget(String id) async {
    if (_useRemote) {
      try {
        await _remote.deleteBudget(id);
        return;
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}

@riverpod
BudgetRepository budgetRepository(BudgetRepositoryRef ref) => BudgetRepository();
