class RewardDisciplineModel {
  final int? id;
  final int userId;
  final int? studentId;
  final String type; // Khen thưởng / Kỷ luật
  final String? typeName; // Học tập xuất sắc, Đi học muộn, etc.
  final String content;
  final String date;
  final String? decisionNumber;
  final String? userName;
  final String? className;
  final int? classId;
  final int? semester;
  final String? schoolYear;
  final String? studentCode;

  RewardDisciplineModel({
    this.id,
    required this.userId,
    this.studentId,
    required this.type,
    this.typeName,
    required this.content,
    required this.date,
    this.decisionNumber,
    this.userName,
    this.className,
    this.classId,
    this.semester,
    this.schoolYear,
    this.studentCode,
  });

  factory RewardDisciplineModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    return RewardDisciplineModel(
      id: json['id'],
      userId: userMap != null ? (userMap['id'] ?? 0) : 0,
      studentId: userMap != null ? userMap['studentId'] : null,
      userName: userMap != null ? (userMap['username'] ?? 'N/A') : 'N/A',
      className: userMap != null ? (userMap['className'] ?? 'N/A') : 'N/A',
      classId: userMap != null ? userMap['classId'] : null,
      type: json['type'] ?? '',
      typeName: json['typeName'] ?? '',
      content: json['content'] ?? '',
      date: json['date'] ?? '',
      decisionNumber: json['decisionNumber'],
      semester: json['semester'],
      schoolYear: json['schoolYear'],
      studentCode: json['studentCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'studentId': studentId,
      'type': type,
      'typeName': typeName,
      'content': content,
      'date': date,
      'decisionNumber': decisionNumber,
      'semester': semester,
      'schoolYear': schoolYear,
      'studentCode': studentCode,
    };
  }
}

