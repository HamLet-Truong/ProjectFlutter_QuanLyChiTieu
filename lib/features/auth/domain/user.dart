import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String preferredCurrency;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.preferredCurrency,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'preferredCurrency': preferredCurrency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      preferredCurrency: map['preferredCurrency'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [id, name, email, preferredCurrency, createdAt];
}
