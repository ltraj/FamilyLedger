import 'package:family_ledger/core/constants/enums.dart';

/// A financial movement between the user and a person.
class TransactionModel {
  const TransactionModel({
    this.id,
    required this.personId,
    required this.amount,
    required this.transactionType,
    this.categoryId,
    this.remark,
    this.attachmentPath,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier. Null when the transaction has not yet been persisted.
  final int? id;

  /// ID of the person this transaction belongs to.
  final int personId;

  /// Monetary amount (always a positive value).
  final double amount;

  /// Type of transaction determining balance impact.
  final TransactionType transactionType;

  /// Optional ID of the expense category.
  final int? categoryId;

  /// Free-text note for the transaction.
  final String? remark;

  /// Local file path to an attachment (receipt, bill, etc.).
  final String? attachmentPath;

  /// Date the transaction occurred (user-facing date).
  final DateTime date;

  /// Timestamp when the record was created.
  final DateTime createdAt;

  /// Timestamp when the record was last updated.
  final DateTime updatedAt;

  TransactionModel copyWith({
    int? id,
    int? personId,
    double? amount,
    TransactionType? transactionType,
    int? categoryId,
    String? remark,
    String? attachmentPath,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      categoryId: categoryId ?? this.categoryId,
      remark: remark ?? this.remark,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'personId': personId,
    'amount': amount,
    'transactionType': transactionType.name,
    'categoryId': categoryId,
    'remark': remark,
    'attachmentPath': attachmentPath,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int?,
      personId: json['personId'] as int,
      amount: (json['amount'] as num).toDouble(),
      transactionType: TransactionType.values.byName(
        json['transactionType'] as String,
      ),
      categoryId: json['categoryId'] as int?,
      remark: json['remark'] as String?,
      attachmentPath: json['attachmentPath'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          id == other.id &&
          personId == other.personId &&
          amount == other.amount &&
          transactionType == other.transactionType &&
          categoryId == other.categoryId &&
          remark == other.remark &&
          attachmentPath == other.attachmentPath &&
          date == other.date &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    amount,
    transactionType,
    categoryId,
    remark,
    attachmentPath,
    date,
    createdAt,
    updatedAt,
  );
}
