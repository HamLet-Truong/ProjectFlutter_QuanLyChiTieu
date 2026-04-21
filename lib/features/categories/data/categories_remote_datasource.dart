import '../../../core/network/api_service.dart';
import '../domain/category.dart';

class CategoriesRemoteDataSource {
  final ApiService _api;

  CategoriesRemoteDataSource(this._api);

  Future<List<CategoryEntity>> fetchCategories() async {
    final res = await _api.get('/categories');
    final list = (res as Map<String, dynamic>)['categories'] as List<dynamic>;
    return list
        .map((item) => CategoryEntity.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> createCategory(CategoryEntity category) async {
    await _api.post('/categories', body: {
      'name': category.name,
      'iconPath': category.iconPath,
      'colorHex': category.colorHex,
      'type': category.type,
    });
  }

  Future<void> updateCategory(CategoryEntity category) async {
    await _api.put('/categories/${category.id}', body: {
      'name': category.name,
      'iconPath': category.iconPath,
      'colorHex': category.colorHex,
      'type': category.type,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _api.delete('/categories/$id');
  }
}
