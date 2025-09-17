class ElectricityPaymentModel {
  String userId;
  String month;
  int unitsUsed;
  double amountPaid;
  String paymentDate;
  String note;
  String? referenceId;

  static const CollectionName = 'electricity_payments';

  ElectricityPaymentModel({
    required this.userId,
    required this.month,
    required this.unitsUsed,
    required this.amountPaid,
    required this.paymentDate,
    required this.note,
    this.referenceId,
  });

  factory ElectricityPaymentModel.fromJson(Map<String, dynamic> json) {
    return ElectricityPaymentModel(
      userId: json['userId'],
      month: json['month'],
      unitsUsed: json['unitsUsed'],
      amountPaid: json['amountPaid'],
      paymentDate: json['paymentDate'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'month': month,
      'unitsUsed': unitsUsed,
      'amountPaid': amountPaid,
      'paymentDate': paymentDate,
      'note': note,      
    };
  }
}
