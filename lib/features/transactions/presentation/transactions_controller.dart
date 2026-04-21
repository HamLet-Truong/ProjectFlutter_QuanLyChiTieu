import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../domain/transaction.dart';
import '../data/transaction_repository.dart';

part 'transactions_controller.g.dart';

@riverpod
class TransactionsController extends _$TransactionsController {
  @override
  FutureOr<List<TransactionEntity>> build() async {
    return ref.read(transactionRepositoryProvider).getTransactions();
  }

  Future<void> addTransaction(
    double amount,
    String note,
    String type,
    String categoryId, {
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.saveTransaction(TransactionEntity(
        id: const Uuid().v4(),
        amount: amount,
        date: date ?? DateTime.now(),
        note: note,
        type: type,
        categoryId: categoryId,
        userId: '1', 
      ));
      return repository.getTransactions();
    });
  }

  Future<void> removeTransaction(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.deleteTransaction(id);
      return repository.getTransactions();
    });
  }

  Future<void> editTransaction(TransactionEntity transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.updateTransaction(transaction);
      return repository.getTransactions();
    });
  }
}
