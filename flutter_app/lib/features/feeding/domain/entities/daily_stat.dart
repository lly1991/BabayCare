class DailyStat {
  const DailyStat({
    required this.date,
    required this.totalCount,
    required this.totalAmount,
    required this.breastCount,
    required this.breastDuration,
    required this.formulaCount,
    required this.formulaAmount,
  });

  final String date;
  final int totalCount;
  final int totalAmount;
  final int breastCount;
  final int breastDuration;
  final int formulaCount;
  final int formulaAmount;
}
