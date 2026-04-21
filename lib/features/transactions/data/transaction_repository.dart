import '../../../core/network/api_config.dart';
import '../../../core/network/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_helper.dart';
import 'transactions_remote_datasource.dart';
import '../domain/transaction.dart';

part 'transaction_repository.g.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper;
  late final TransactionsRemoteDataSource _remote;

  TransactionRepository({DatabaseHelper? dbHelper, ApiService? apiService})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance {
    _remote = TransactionsRemoteDataSource(apiService ?? ApiService());
  }

  bool get _useRemote => ApiConfig.useRemoteApi;

  Future<List<TransactionEntity>> getTransactions() async {
    if (_useRemote) {
      try {
        return await _remote.fetchTransactions();
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((e) => TransactionEntity.fromMap(e)).toList();
  }

  Future<void> saveTransaction(TransactionEntity transaction) async {
    if (_useRemote) {
      try {
        await _remote.createTransaction(transaction);
        return;
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    if (_useRemote) {
      try {
        await _remote.updateTransaction(transaction);
        return;
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    if (_useRemote) {
      try {
        await _remote.deleteTransaction(id);
        return;
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}

@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return TransactionRepository();
}
