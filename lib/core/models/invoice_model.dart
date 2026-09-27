class InvoiceModel {
  final String id;
  final String driverId;
  final double amount;
  final String status; // 'pending', 'paid', 'overdue'
  final String pixCopyPaste;
  final String? pixQrCode;
  final DateTime dueDate;
  final DateTime? paidAt;
  final DateTime createdAt;

  InvoiceModel({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.status,
    required this.pixCopyPaste,
    this.pixQrCode,
    required this.dueDate,
    this.paidAt,
    required this.createdAt,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      pixCopyPaste: json['pix_copy_paste'] as String? ?? '',
      pixQrCode: json['pix_qr_code'] as String?,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : DateTime.now().add(const Duration(days: 3)),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'amount': amount,
      'status': status,
      'pix_copy_paste': pixCopyPaste,
      'pix_qr_code': pixQrCode,
      'due_date': dueDate.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  InvoiceModel copyWith({
    String? status,
    DateTime? paidAt,
  }) {
    return InvoiceModel(
      id: id,
      driverId: driverId,
      amount: amount,
      status: status ?? this.status,
      pixCopyPaste: pixCopyPaste,
      pixQrCode: pixQrCode,
      dueDate: dueDate,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt,
    );
  }
}
