/// Summary of a completed restore run, returned by [RestoreService].
class RestoreResultModel {
  const RestoreResultModel({
    required this.restoredAt,
    required this.peopleCount,
    required this.transactionCount,
    required this.categoryCount,
  });

  final DateTime restoredAt;

  final int peopleCount;
  final int transactionCount;
  final int categoryCount;
}
