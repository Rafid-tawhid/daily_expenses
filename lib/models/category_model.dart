class Category {
  final int id;
  final int userId;
  final String name;
  final String icon;
  final String color;
  final double? budgetLimit;
  final bool isDefault;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    this.budgetLimit,
    this.isDefault = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      budgetLimit: json['budget_limit'] != null
          ? (json['budget_limit'] as num).toDouble()
          : null,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'budget_limit': budgetLimit,
      'is_default': isDefault,
    };
  }
}