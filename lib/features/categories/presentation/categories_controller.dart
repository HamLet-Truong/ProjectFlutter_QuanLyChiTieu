import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../domain/category.dart';
import '../data/category_repository.dart';

part 'categories_controller.g.dart';

@riverpod
class CategoriesController extends _$CategoriesController {
  @override
  FutureOr<List<CategoryEntity>> build() async {
    return ref.read(categoryRepositoryProvider).getCategories();
  }

  Future<void> addCategory(String name, String type) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.saveCategory(CategoryEntity(
        id: const Uuid().v4(),
        name: name,
        iconPath: 'category',
        colorHex: '#000000',
        type: type,
      ));
      return repository.getCategories();
    });
  }

  Future<void> removeCategory(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.deleteCategory(id);
      return repository.getCategories();
    });
  }

  Future<void> editCategory(CategoryEntity category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.updateCategory(category);
      return repository.getCategories();
    });
  }
}
