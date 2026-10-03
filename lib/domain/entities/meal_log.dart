enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast 🌅';
      case MealType.lunch:
        return 'Lunch ☀️';
      case MealType.dinner:
        return 'Dinner 🌙';
      case MealType.snack:
        return 'Snack 🍎';
    }
  }

  static MealType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
        return MealType.snack;
      case 'breakfast':
      default:
        return MealType.breakfast;
    }
  }
}

class FoodItem {
  final String id;
  final String name;
  final String portion;
  final String category;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const FoodItem({
    required this.id,
    required this.name,
    required this.portion,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'portion': portion,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      portion: json['portion'] as String? ?? '1 serving',
      category: json['category'] as String? ?? 'General',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
    );
  }
}

class MealLog {
  final String id;
  final String residentId;
  final MealType mealType;
  final DateTime timestamp;
  final List<FoodItem> items;
  final int expectedIntakePercent;
  final int actualIntakePercent;
  final String? observations;
  final String recordedBy;

  const MealLog({
    required this.id,
    required this.residentId,
    required this.mealType,
    required this.timestamp,
    required this.items,
    this.expectedIntakePercent = 100,
    required this.actualIntakePercent,
    this.observations,
    required this.recordedBy,
  });

  double get intakeRatio => actualIntakePercent / 100.0;

  int get consumedCalories => (items.fold<int>(0, (sum, item) => sum + item.calories) * intakeRatio).round();
  int get consumedProtein => (items.fold<int>(0, (sum, item) => sum + item.protein) * intakeRatio).round();
  int get consumedCarbs => (items.fold<int>(0, (sum, item) => sum + item.carbs) * intakeRatio).round();
  int get consumedFat => (items.fold<int>(0, (sum, item) => sum + item.fat) * intakeRatio).round();

  bool get isLowIntake => actualIntakePercent <= 50;

  MealLog copyWith({
    String? id,
    String? residentId,
    MealType? mealType,
    DateTime? timestamp,
    List<FoodItem>? items,
    int? expectedIntakePercent,
    int? actualIntakePercent,
    String? observations,
    String? recordedBy,
  }) {
    return MealLog(
      id: id ?? this.id,
      residentId: residentId ?? this.residentId,
      mealType: mealType ?? this.mealType,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
      expectedIntakePercent: expectedIntakePercent ?? this.expectedIntakePercent,
      actualIntakePercent: actualIntakePercent ?? this.actualIntakePercent,
      observations: observations ?? this.observations,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residentId': residentId,
      'mealType': mealType.name,
      'timestamp': timestamp.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'expectedIntakePercent': expectedIntakePercent,
      'actualIntakePercent': actualIntakePercent,
      'observations': observations,
      'recordedBy': recordedBy,
    };
  }

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] as String,
      residentId: json['residentId'] as String? ?? 'res_margaret',
      mealType: MealType.fromString(json['mealType'] as String? ?? 'breakfast'),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => FoodItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      expectedIntakePercent: (json['expectedIntakePercent'] as num?)?.toInt() ?? 100,
      actualIntakePercent: (json['actualIntakePercent'] as num?)?.toInt() ?? 100,
      observations: json['observations'] as String?,
      recordedBy: json['recordedBy'] as String? ?? 'Nurse Jane',
    );
  }
}

class NutritionTargets {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fluidMl;

  const NutritionTargets({
    this.calories = 1800,
    this.protein = 65,
    this.carbs = 220,
    this.fat = 55,
    this.fluidMl = 1800,
  });

  factory NutritionTargets.fromJson(Map<String, dynamic> json) {
    return NutritionTargets(
      calories: (json['calories'] as num?)?.toInt() ?? (json['target_calories'] as num?)?.toInt() ?? 1800,
      protein: (json['protein_g'] as num?)?.toInt() ?? (json['protein'] as num?)?.toInt() ?? (json['target_protein_g'] as num?)?.toInt() ?? 65,
      carbs: (json['carbs_g'] as num?)?.toInt() ?? (json['carbs'] as num?)?.toInt() ?? (json['target_carbs_g'] as num?)?.toInt() ?? 220,
      fat: (json['fat_g'] as num?)?.toInt() ?? (json['fat'] as num?)?.toInt() ?? (json['target_fat_g'] as num?)?.toInt() ?? 55,
      fluidMl: (json['fluid_ml'] as num?)?.toInt() ?? (json['target_fluid_ml'] as num?)?.toInt() ?? 1800,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fluid_ml': fluidMl,
    };
  }
}
