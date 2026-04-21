import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_service.dart';
import '../../../core/database/database_helper.dart';
import 'categories_remote_datasource.dart';
import '../domain/category.dart';

part 'category_repository.g.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper;
  late final CategoriesRemoteDataSource _remote;

  CategoryRepository({DatabaseHelper? dbHelper, ApiService? apiService})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance {
    _remote = CategoriesRemoteDataSource(apiService ?? ApiService());
  }

  bool get _useRemote => ApiConfig.useRemoteApi;

  Future<List<CategoryEntity>> getCategories() async {
    if (_useRemote) {
      try {
        return await _remote.fetchCategories();
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((e) => CategoryEntity.fromMap(e)).toList();
  }

  Future<void> saveCategory(CategoryEntity category) async {
    if (_useRemote) {
      try {
        await _remote.createCategory(category);
        return;
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(CategoryEntity category) async {
    if (_useRemote) {
      try {
        await _remote.updateCategory(category);
        return;
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    if (_useRemote) {
      try {
        await _remote.deleteCategory(id);
        return;
      } catch (_) {}
    }

    final db = await _dbHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  return CategoryRepository();
}
