import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final String note;
  final String type;
  final String categoryId;
  final String userId;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.date,
    required this.note,
    required this.type,
    required this.categoryId,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'type': type,
      'categoryId': categoryId,
      'userId': userId,
    };
  }

  factory TransactionEntity.fromMap(Map<String, dynamic> map) {
    return TransactionEntity(
      id: map['id'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      type: map['type'],
      categoryId: map['categoryId'],
      userId: map['userId'],
    );
  }

  @override
  List<Object?> get props => [id, amount, date, note, type, categoryId, userId];
}
