class AttendanceSummary {
  final int? studentId;
  final String studentName;
  final String studentCode;
  final String className;

  final int totalSessions;
  final int presentCount;
  final int excusedAbsentCount;
  final int unexcusedAbsentCount;
  final int lateCount;

  final double attendanceRate;
  final String statusNote;

  AttendanceSummary({
    this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.className,
    required this.totalSessions,
    required this.presentCount,
    required this.excusedAbsentCount,
    required this.unexcusedAbsentCount,
    required this.lateCount,
    required this.attendanceRate,
    required this.statusNote,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      studentId: json['studentId'] as int?,
      studentName: json['studentName'] as String? ?? '',
      studentCode: json['studentCode'] as String? ?? '',
      className: json['className'] as String? ?? '',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      excusedAbsentCount: (json['excusedAbsentCount'] as num?)?.toInt() ?? 0,
      unexcusedAbsentCount: (json['unexcusedAbsentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 100.0,
      statusNote: json['statusNote'] as String? ?? 'Chuyên cần tốt',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (studentId != null) 'studentId': studentId,
      'studentName': studentName,
      'studentCode': studentCode,
      'className': className,
      'totalSessions': totalSessions,
      'presentCount': presentCount,
      'excusedAbsentCount': excusedAbsentCount,
      'unexcusedAbsentCount': unexcusedAbsentCount,
      'lateCount': lateCount,
      'attendanceRate': attendanceRate,
      'statusNote': statusNote,
    };
  }
}
