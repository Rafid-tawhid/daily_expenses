import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all categories for a user (using user_id from public.users)
  Future<List<Category>> getUserCategories(int userId) async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('user_id', userId)
          .order('name');

      print('Categories for user $userId: $response'); // For debugging

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading categories: $e');
      throw Exception('Failed to load categories: $e');
    }
  }

  // Get default categories (from user_id = 1)
  Future<List<Category>> getDefaultCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('user_id', 1) // First user has default categories
          .order('name');

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading default categories: $e');
      throw Exception('Failed to load default categories: $e');
    }
  }

  // Create a new category
  Future<Category> createCategory(Category category) async {
    try {
      final response = await _supabase
          .from('categories')
          .insert({
        'user_id': category.userId,
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'budget_limit': category.budgetLimit,
        'is_default': false,
      })
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('Error creating category: $e');
      throw Exception('Failed to create category: $e');
    }
  }

  // Update a category
  Future<Category> updateCategory(Category category) async {
    try {
      final response = await _supabase
          .from('categories')
          .update({
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'budget_limit': category.budgetLimit,
      })
          .eq('id', category.id)
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('Error updating category: $e');
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete a category
  Future<void> deleteCategory(int categoryId) async {
    try {
      await _supabase
          .from('categories')
          .delete()
          .eq('id', categoryId);
    } catch (e) {
      print('Error deleting category: $e');
      throw Exception('Failed to delete category: $e');
    }
  }

  // Set budget limit for category
  Future<Category> setBudgetLimit(int categoryId, double limit) async {
    try {
      final response = await _supabase
          .from('categories')
          .update({'budget_limit': limit})
          .eq('id', categoryId)
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('Error setting budget limit: $e');
      throw Exception('Failed to set budget limit: $e');
    }
  }
}