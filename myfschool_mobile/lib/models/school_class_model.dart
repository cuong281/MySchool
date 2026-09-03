class SchoolClassModel {
  final int id;
  final String className;
  final String status;

  SchoolClassModel({
    required this.id,
    required this.className,
    required this.status,
  });

  factory SchoolClassModel.fromJson(Map<String, dynamic> json) {
    return SchoolClassModel(
      id: json['id'] as int,
      className: json['className'] as String,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'className': className,
      'status': status,
    };
  }
}
