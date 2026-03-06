import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/category_service.dart';
import '../models/category_model.dart';
import 'auth_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;

  print('Loading categories for user ID: $userId'); // For debugging

  if (userId == null) {
    print('No user ID found, returning empty list');
    return [];
  }

  final categoryService = ref.watch(categoryServiceProvider);
  final categories = await categoryService.getUserCategories(userId);
  print('Loaded ${categories.length} categories');
  return categories;
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  final Ref ref;

  CategoryNotifier(this.ref) : super([]);

  Future<void> loadCategories() async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      print('Cannot load categories: No user ID');
      return;
    }

    print('Loading categories for user $userId');
    final categoryService = ref.read(categoryServiceProvider);
    try {
      final categories = await categoryService.getUserCategories(userId);
      state = categories;
      print('Categories loaded: ${categories.length}');
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<Category> addCategory(Category category) async {
    final categoryService = ref.read(categoryServiceProvider);
    final newCategory = await categoryService.createCategory(category);
    state = [...state, newCategory];
    return newCategory;
  }

  Future<Category> updateCategory(Category category) async {
    final categoryService = ref.read(categoryServiceProvider);
    final updatedCategory = await categoryService.updateCategory(category);

    state = state.map((c) {
      return c.id == updatedCategory.id ? updatedCategory : c;
    }).toList();

    return updatedCategory;
  }

  Future<void> deleteCategory(int categoryId) async {
    final categoryService = ref.read(categoryServiceProvider);
    await categoryService.deleteCategory(categoryId);
    state = state.where((c) => c.id != categoryId).toList();
  }

  Future<Category> setBudgetLimit(int categoryId, double limit) async {
    final categoryService = ref.read(categoryServiceProvider);
    final updatedCategory = await categoryService.setBudgetLimit(categoryId, limit);

    state = state.map((c) {
      return c.id == updatedCategory.id ? updatedCategory : c;
    }).toList();

    return updatedCategory;
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier(ref);
});