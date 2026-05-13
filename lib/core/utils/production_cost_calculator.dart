class ProductionCostCalculator {
  ProductionCostCalculator._();

  /// Calculate total labor cost for a day based on present employees
  static double calculateLaborCost(List<Map<String, dynamic>> presentEmployees) {
    return presentEmployees.fold<double>(
      0,
      (sum, emp) => sum + ((emp['daily_rate'] as num?)?.toDouble() ?? 0),
    );
  }

  /// Calculate material cost per unit from recipe items
  static double calculateMaterialCostPerUnit(
      List<Map<String, dynamic>> recipeItems) {
    return recipeItems.fold<double>(
      0,
      (sum, item) {
        final qtyPerUnit =
            (item['quantity_per_unit'] as num?)?.toDouble() ?? 0;
        final unitCost =
            (item['raw_material']?['unit_cost'] as num?)?.toDouble() ?? 0;
        return sum + (qtyPerUnit * unitCost);
      },
    );
  }

  /// Calculate total production cost
  static Map<String, double> calculateProductionCost({
    required double totalLaborCost,
    required double materialCostPerUnit,
    required int totalPairsProduced,
  }) {
    if (totalPairsProduced == 0) {
      return {
        'total_labor_cost': totalLaborCost,
        'total_material_cost': 0,
        'total_cost': totalLaborCost,
        'unit_cost': 0,
      };
    }

    final totalMaterialCost = materialCostPerUnit * totalPairsProduced;
    final totalCost = totalLaborCost + totalMaterialCost;
    final unitCost = totalCost / totalPairsProduced;

    return {
      'total_labor_cost': totalLaborCost,
      'total_material_cost': totalMaterialCost,
      'total_cost': totalCost,
      'unit_cost': unitCost,
    };
  }
}
