import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String iconPath;
  final String colorHex;
  final String type;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.colorHex,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
      'colorHex': colorHex,
      'type': type,
    };
  }

  factory CategoryEntity.fromMap(Map<String, dynamic> map) {
    return CategoryEntity(
      id: map['id'],
      name: map['name'],
      iconPath: map['iconPath'],
      colorHex: map['colorHex'],
      type: map['type'],
    );
  }

  @override
  List<Object?> get props => [id, name, iconPath, colorHex, type];
}
