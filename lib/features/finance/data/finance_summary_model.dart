class FinanceSummary {
  final double totalRevenue;
  final double totalPaid;
  final double clientDebt;
  final double productionCost;
  final double purchaseCost;
  final double salariesPaid;
  final double totalExpenses;
  final double supplierDebt;
  final int month;
  final int year;

  const FinanceSummary({
    this.totalRevenue = 0,
    this.totalPaid = 0,
    this.clientDebt = 0,
    this.productionCost = 0,
    this.purchaseCost = 0,
    this.salariesPaid = 0,
    this.totalExpenses = 0,
    this.supplierDebt = 0,
    this.month = 0,
    this.year = 0,
  });

  double get totalCosts =>
      productionCost + purchaseCost + salariesPaid + totalExpenses;

  double get netProfit => totalRevenue - totalCosts;

  double get marginPercent =>
      totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;

  String get monthLabel {
    const m = ['','Jan','Fév','Mar','Avr','Mai','Juin','Juil','Aoû','Sep','Oct','Nov','Déc'];
    return '${m[month]} $year';
  }
}
