class StakeTransaction {
  const StakeTransaction({
    required this.transactionId,
    required this.status,
    this.geniusReference,
    this.paymentUrl,
    this.amountXof,
    this.feesXof,
  });

  final String transactionId;
  final String? geniusReference;
  final String? paymentUrl;
  final String status;
  final double? amountXof;
  final double? feesXof;

  factory StakeTransaction.fromJson(Map<String, dynamic> json) {
    return StakeTransaction(
      transactionId: json['transactionId'] as String,
      geniusReference: json['geniusReference'] as String?,
      paymentUrl: json['paymentUrl'] as String?,
      status: json['status'] as String,
      amountXof: _parseDouble(json['amountXof']),
      feesXof: _parseDouble(json['feesXof']),
    );
  }

  /// Prisma serializes `Decimal` fields as JSON strings, not numbers — this
  /// accepts either (same convention as `QuestModel._parseDouble`).
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw ArgumentError('Expected a number or numeric string, got: $value');
  }

  @override
  bool operator ==(Object other) =>
      other is StakeTransaction &&
      other.transactionId == transactionId &&
      other.geniusReference == geniusReference &&
      other.paymentUrl == paymentUrl &&
      other.status == status &&
      other.amountXof == amountXof &&
      other.feesXof == feesXof;

  @override
  int get hashCode =>
      Object.hash(transactionId, geniusReference, paymentUrl, status, amountXof, feesXof);
}
