class PaymentModel {
  final String id;
  final String tableName;
  final double amount;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final DateTime createdAt;
  final String? notes;
  final String? transactionId;
  final String method; // 'cash', 'card', 'mobile', vs.

  PaymentModel({
    required this.id,
    required this.tableName,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.notes,
    this.transactionId,
    required this.method,
  });

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      tableName: json['tableName'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      transactionId: json['transactionId'] as String?,
      method: json['method'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableName': tableName,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'transactionId': transactionId,
      'method': method,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? tableName,
    double? amount,
    String? status,
    DateTime? createdAt,
    String? notes,
    String? transactionId,
    String? method,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      transactionId: transactionId ?? this.transactionId,
      method: method ?? this.method,
    );
  }
}
