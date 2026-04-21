import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  final String id;
  final String categoryId;
  final double limitAmount;
  final DateTime startDate;
  final DateTime endDate;

  const BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() => {
      'id': id,
      'categoryId': categoryId,
      'limitAmount': limitAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
  };

  factory BudgetEntity.fromMap(Map<String, dynamic> map) => BudgetEntity(
      id: map['id'],
      categoryId: map['categoryId'],
      limitAmount: map['limitAmount'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
  );

  @override
  List<Object?> get props => [id, categoryId, limitAmount, startDate, endDate];
}
