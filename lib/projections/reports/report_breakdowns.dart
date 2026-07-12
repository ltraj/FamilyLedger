import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/projection.dart';

/// One month's value in a report trend — the unit both the Monthly
/// Analysis rows and the trend charts are built from.
class TrendPoint implements Projection {
  const TrendPoint({required this.month, required this.value});

  /// First day of the month this point covers.
  final DateTime month;

  final double value;
}

/// An amount attributed to one person (own-pocket per person, etc.).
class PersonAmount implements Projection {
  const PersonAmount({required this.person, required this.amount});

  final PersonModel person;
  final double amount;
}

/// An amount attributed to one category. [category] is null for the
/// "no category" bucket — transactions that were never categorized still
/// carry real money and would silently vanish from any per-category
/// figure that dropped them.
class CategoryAmount implements Projection {
  const CategoryAmount({required this.category, required this.amount});

  final CategoryModel? category;
  final double amount;
}
