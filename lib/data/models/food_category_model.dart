import 'package:flutter/material.dart';

class FoodCategoryModel {
  final String id;
  final String name;
  final IconData icon;

  const FoodCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  static const List<FoodCategoryModel> categories = [
    FoodCategoryModel(
      id: 'buttermilk',
      name: 'Buttermilk',
      icon: Icons.local_drink_outlined,
    ),
    FoodCategoryModel(
      id: 'tea_coffee',
      name: 'Tea & Coffee',
      icon: Icons.coffee_outlined,
    ),
    FoodCategoryModel(
      id: 'snacks',
      name: 'Snacks',
      icon: Icons.cookie_outlined,
    ),
    FoodCategoryModel(
      id: 'lunch',
      name: 'Lunch',
      icon: Icons.lunch_dining_outlined,
    ),
    FoodCategoryModel(
      id: 'cold_drinks',
      name: 'Cold Drinks',
      icon: Icons.local_cafe_outlined,
    ),
    FoodCategoryModel(
      id: 'other',
      name: 'Other',
      icon: Icons.shopping_basket_outlined,
    ),
  ];

  static FoodCategoryModel findById(String id) {
    return categories.firstWhere(
      (category) => category.id == id,
      orElse: () => categories.last,
    );
  }
}
