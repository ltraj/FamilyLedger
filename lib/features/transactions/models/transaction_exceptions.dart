/// Thrown when a transaction amount is missing, zero, or negative for a
/// type where the sign is implied (everything except `adjustment`, which
/// may legitimately be negative).
class InvalidTransactionAmountException implements Exception {
  const InvalidTransactionAmountException();

  String get message => 'Enter an amount greater than zero.';

  @override
  String toString() => message;
}

/// Thrown when a remark exceeds the maximum allowed length.
class RemarkTooLongException implements Exception {
  const RemarkTooLongException(this.maxLength);

  final int maxLength;

  String get message => 'Remark must be $maxLength characters or fewer.';

  @override
  String toString() => message;
}
