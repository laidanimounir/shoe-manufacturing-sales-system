class Payment {
  final String id;
  final String? invoiceId;
  final String? clientId;
  final double amount;
  final String method;
  final DateTime? paymentDate;
  final String? notes;
  final DateTime? createdAt;

  const Payment({
    required this.id,
    this.invoiceId,
    this.clientId,
    this.amount = 0,
    this.method = 'cash',
    this.paymentDate,
    this.notes,
    this.createdAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String?,
      clientId: map['client_id'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      method: map['payment_method'] as String? ?? 'cash',
      paymentDate: map['payment_date'] != null
          ? DateTime.tryParse(map['payment_date'].toString())
          : null,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoice_id': invoiceId,
      'client_id': clientId,
      'amount': amount,
      'payment_method': method,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }

  String get methodLabel {
    switch (method) {
      case 'cash':
        return 'Espèces';
      case 'bank':
        return 'Virement';
      case 'cheque':
        return 'Chèque';
      default:
        return method;
    }
  }

  @override
  String toString() => 'Payment($amount)';
}
