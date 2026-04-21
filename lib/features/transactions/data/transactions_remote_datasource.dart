import '../../../core/network/api_service.dart';
import '../domain/transaction.dart';

class TransactionsRemoteDataSource {
  final ApiService _api;

  TransactionsRemoteDataSource(this._api);

  Future<List<TransactionEntity>> fetchTransactions() async {
    final res = await _api.get('/transactions');
    final list = (res as Map<String, dynamic>)['transactions'] as List<dynamic>;
    return list
        .map((item) => TransactionEntity.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> createTransaction(TransactionEntity transaction) async {
    await _api.post('/transactions', body: {
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'note': transaction.note,
      'type': transaction.type,
      'categoryId': transaction.categoryId,
    });
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    await _api.put('/transactions/${transaction.id}', body: {
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'note': transaction.note,
      'type': transaction.type,
      'categoryId': transaction.categoryId,
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _api.delete('/transactions/$id');
  }
}
