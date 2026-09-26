import '../../domain/entities/meal_log.dart';

class FoodFixtures {
  FoodFixtures._();

  static const List<FoodItem> library = [
    // Breakfast
    FoodItem(id: 'f_01', name: 'Oatmeal', portion: '1 cup', category: 'Breakfast', calories: 158, protein: 6, carbs: 27, fat: 3),
    FoodItem(id: 'f_02', name: 'Scrambled Eggs', portion: '2 large', category: 'Breakfast', calories: 182, protein: 12, carbs: 2, fat: 14),
    FoodItem(id: 'f_03', name: 'Whole Wheat Toast', portion: '1 slice', category: 'Breakfast', calories: 75, protein: 4, carbs: 13, fat: 1),
    FoodItem(id: 'f_04', name: 'Blueberry Pancakes', portion: '2 small', category: 'Breakfast', calories: 210, protein: 5, carbs: 38, fat: 5),
    FoodItem(id: 'f_05', name: 'Greek Yogurt with Honey', portion: '¾ cup', category: 'Breakfast', calories: 140, protein: 15, carbs: 16, fat: 2),
    FoodItem(id: 'f_06', name: 'Poached Egg on Toast', portion: '1 egg + toast', category: 'Breakfast', calories: 155, protein: 10, carbs: 14, fat: 6),

    // Soups & Mains
    FoodItem(id: 'f_07', name: 'Vegetable Minestrone Soup', portion: '1 bowl', category: 'Soups & Mains', calories: 165, protein: 7, carbs: 28, fat: 3),
    FoodItem(id: 'f_08', name: 'Chicken Noodle Soup', portion: '1 bowl', category: 'Soups & Mains', calories: 140, protein: 13, carbs: 15, fat: 3),
    FoodItem(id: 'f_09', name: 'Baked Salmon Fillet', portion: '4 oz', category: 'Soups & Mains', calories: 234, protein: 25, carbs: 0, fat: 14),
    FoodItem(id: 'f_10', name: 'Roast Turkey Breast', portion: '3 oz', category: 'Soups & Mains', calories: 135, protein: 24, carbs: 0, fat: 3),
    FoodItem(id: 'f_11', name: 'Beef Pot Roast', portion: '3.5 oz', category: 'Soups & Mains', calories: 260, protein: 28, carbs: 4, fat: 15),
    FoodItem(id: 'f_12', name: 'Tender Meatloaf with Gravy', portion: '1 slice', category: 'Soups & Mains', calories: 245, protein: 18, carbs: 12, fat: 14),
    FoodItem(id: 'f_13', name: 'Baked Cod with Lemon Herb', portion: '4 oz', category: 'Soups & Mains', calories: 120, protein: 23, carbs: 1, fat: 2),
    FoodItem(id: 'f_14', name: 'Vegetarian Shepherd\'s Pie', portion: '1 cup', category: 'Soups & Mains', calories: 210, protein: 8, carbs: 32, fat: 6),

    // Sides & Salads
    FoodItem(id: 'f_15', name: 'Steamed Broccoli Florets', portion: '1 cup', category: 'Sides & Salads', calories: 55, protein: 4, carbs: 11, fat: 1),
    FoodItem(id: 'f_16', name: 'Mashed Potatoes with Milk', portion: '½ cup', category: 'Sides & Salads', calories: 115, protein: 2, carbs: 20, fat: 3),
    FoodItem(id: 'f_17', name: 'Glazed Carrots', portion: '½ cup', category: 'Sides & Salads', calories: 45, protein: 1, carbs: 10, fat: 1),
    FoodItem(id: 'f_18', name: 'Sweet Potato Puree', portion: '½ cup', category: 'Sides & Salads', calories: 125, protein: 2, carbs: 28, fat: 1),
    FoodItem(id: 'f_19', name: 'Garden Green Salad', portion: '1.5 cups', category: 'Sides & Salads', calories: 60, protein: 2, carbs: 8, fat: 3),
    FoodItem(id: 'f_20', name: 'Sauteed Spinach with Garlic', portion: '½ cup', category: 'Sides & Salads', calories: 40, protein: 3, carbs: 4, fat: 2),
    FoodItem(id: 'f_21', name: 'Buttered Green Beans', portion: '½ cup', category: 'Sides & Salads', calories: 50, protein: 2, carbs: 6, fat: 3),

    // Fruits & Snacks
    FoodItem(id: 'f_22', name: 'Banana', portion: '1 medium', category: 'Fruits & Snacks', calories: 105, protein: 1, carbs: 27, fat: 0),
    FoodItem(id: 'f_23', name: 'Apple Slices with Cinnamon', portion: '1 cup', category: 'Fruits & Snacks', calories: 65, protein: 0, carbs: 17, fat: 0),
    FoodItem(id: 'f_24', name: 'Fresh Strawberries', portion: '1 cup', category: 'Fruits & Snacks', calories: 50, protein: 1, carbs: 12, fat: 0),
    FoodItem(id: 'f_25', name: 'Peach Compote', portion: '½ cup', category: 'Fruits & Snacks', calories: 85, protein: 1, carbs: 21, fat: 0),
    FoodItem(id: 'f_26', name: 'Cottage Cheese with Fruit', portion: '½ cup', category: 'Fruits & Snacks', calories: 120, protein: 14, carbs: 8, fat: 3),
    FoodItem(id: 'f_27', name: 'Hummus with Soft Pita', portion: '3 tbsp + pita', category: 'Fruits & Snacks', calories: 160, protein: 6, carbs: 22, fat: 6),

    // Beverages
    FoodItem(id: 'f_28', name: 'Earl Grey Tea', portion: '1 cup', category: 'Beverages', calories: 2, protein: 0, carbs: 0, fat: 0),
    FoodItem(id: 'f_29', name: 'Chamomile Herbal Tea', portion: '1 cup', category: 'Beverages', calories: 2, protein: 0, carbs: 0, fat: 0),
    FoodItem(id: 'f_30', name: 'Fresh Orange Juice', portion: '6 oz', category: 'Beverages', calories: 85, protein: 1, carbs: 20, fat: 0),
    FoodItem(id: 'f_31', name: 'Whole Milk', portion: '8 oz', category: 'Beverages', calories: 149, protein: 8, carbs: 12, fat: 8),
    FoodItem(id: 'f_32', name: 'Fortified Protein Shake', portion: '8 oz', category: 'Beverages', calories: 180, protein: 20, carbs: 16, fat: 3),
    FoodItem(id: 'f_33', name: 'Hydration Electrolyte Water', portion: '8 oz', category: 'Beverages', calories: 10, protein: 0, carbs: 2, fat: 0),

    // Desserts
    FoodItem(id: 'f_34', name: 'Warm Baked Apple Crisp', portion: '½ cup', category: 'Desserts', calories: 175, protein: 2, carbs: 32, fat: 5),
    FoodItem(id: 'f_35', name: 'Vanilla Custard Pudding', portion: '½ cup', category: 'Desserts', calories: 140, protein: 4, carbs: 22, fat: 4),
    FoodItem(id: 'f_36', name: 'Blueberry Gelatin Cup', portion: '1 cup', category: 'Desserts', calories: 80, protein: 2, carbs: 19, fat: 0),
    FoodItem(id: 'f_37', name: 'Soft Rice Pudding with Raisins', portion: '½ cup', category: 'Desserts', calories: 160, protein: 4, carbs: 30, fat: 3),
  ];
}
