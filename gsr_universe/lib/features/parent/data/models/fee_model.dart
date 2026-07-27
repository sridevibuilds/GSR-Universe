// Data Model Layer - Fee Model with Safe Type Parsing
class FeeModel {
  final int feeId;
  final double totalFee;
  final double paidAmount;
  final double pendingAmount;
  final String academicYear;
  final String className;
  final String section;
  final String status;
  final String? dueDate;
  final String? remarks;

  FeeModel({
    required this.feeId,
    required this.totalFee,
    required this.paidAmount,
    required this.pendingAmount,
    required this.academicYear,
    required this.className,
    required this.section,
    required this.status,
    this.dueDate,
    this.remarks,
  });

  /// Universal numeric parser accepting double, int, num, String ("14000", "80000.00"), or null
  static double parseNum(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '').trim();
      return double.tryParse(cleaned) ?? defaultValue;
    }
    return defaultValue;
  }

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    final double total = parseNum(json['total_fee'] ?? json['totalFee']);
    final double paid = parseNum(json['paid_amount'] ?? json['paidAmount']);
    final double pending = parseNum(json['pending_amount'] ?? json['pendingAmount'] ?? (total - paid));

    String statusStr = json['status']?.toString() ?? '';
    if (statusStr.isEmpty) {
      statusStr = pending <= 0 ? 'Paid' : 'Pending';
    }

    return FeeModel(
      feeId: json['fee_id'] is num ? (json['fee_id'] as num).toInt() : int.tryParse(json['fee_id']?.toString() ?? '0') ?? 0,
      totalFee: total,
      paidAmount: paid,
      pendingAmount: pending,
      academicYear: json['academic_year']?.toString() ?? json['year_name']?.toString() ?? '2026–2027',
      className: (json['class_name']?.toString() ?? '8').replaceAll('Class ', ''),
      section: json['section']?.toString() ?? 'B',
      status: statusStr,
      dueDate: json['due_date']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }
}
