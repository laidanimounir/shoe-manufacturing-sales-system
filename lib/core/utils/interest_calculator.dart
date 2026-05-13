class InterestCalculator {
  InterestCalculator._();

  /// Calculate simple interest on overdue debt
  /// rate: annual interest rate (e.g., 0.05 for 5%)
  static double calculateSimpleInterest({
    required double principal,
    required double annualRate,
    required int daysOverdue,
  }) {
    return principal * annualRate * (daysOverdue / 365);
  }

  /// Calculate the total amount due including interest
  static double totalAmountDue({
    required double principal,
    required double annualRate,
    required DateTime dueDate,
  }) {
    final now = DateTime.now();
    if (now.isBefore(dueDate)) return principal;

    final daysOverdue = now.difference(dueDate).inDays;
    final interest = calculateSimpleInterest(
      principal: principal,
      annualRate: annualRate,
      daysOverdue: daysOverdue,
    );
    return principal + interest;
  }
}
