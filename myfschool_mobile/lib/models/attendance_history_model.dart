class AttendanceAtRiskStudentModel {
  final int studentId;
  final String studentName;
  final String studentCode;
  final int unexcusedCount;
  final double rate;
  final String warningNote;

  AttendanceAtRiskStudentModel({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.unexcusedCount,
    required this.rate,
    required this.warningNote,
  });

  factory AttendanceAtRiskStudentModel.fromJson(Map<String, dynamic> json) {
    return AttendanceAtRiskStudentModel(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String? ?? '',
      studentCode: json['studentCode'] as String? ?? '',
      unexcusedCount: json['unexcusedCount'] as int? ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 100.0,
      warningNote: json['warningNote'] as String? ?? '',
    );
  }
}

class AttendanceSessionSummaryModel {
  final String attendanceDate;
  final int slotNumber;
  final int? subjectId;
  final String? subjectName;
  final int presentCount;
  final int excusedCount;
  final int unexcusedCount;
  final int lateCount;
  final int totalCount;
  final bool canEdit;
  final List<String> absentStudents;

  AttendanceSessionSummaryModel({
    required this.attendanceDate,
    required this.slotNumber,
    this.subjectId,
    this.subjectName,
    required this.presentCount,
    required this.excusedCount,
    required this.unexcusedCount,
    required this.lateCount,
    required this.totalCount,
    required this.canEdit,
    required this.absentStudents,
  });

  factory AttendanceSessionSummaryModel.fromJson(Map<String, dynamic> json) {
    final absents = json['absentStudents'] as List<dynamic>? ?? [];
    return AttendanceSessionSummaryModel(
      attendanceDate: json['attendanceDate'] as String? ?? '',
      slotNumber: json['slotNumber'] as int? ?? 1,
      subjectId: json['subjectId'] as int?,
      subjectName: json['subjectName'] as String?,
      presentCount: json['presentCount'] as int? ?? 0,
      excusedCount: json['excusedCount'] as int? ?? 0,
      unexcusedCount: json['unexcusedCount'] as int? ?? 0,
      lateCount: json['lateCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      canEdit: json['canEdit'] as bool? ?? false,
      absentStudents: absents.map((e) => e.toString()).toList(),
    );
  }
}

class AttendanceClassHistoryModel {
  final int classId;
  final String className;
  final double attendanceRate;
  final int totalSessions;
  final int presentCount;
  final int excusedCount;
  final int unexcusedCount;
  final int lateCount;
  final List<AttendanceSessionSummaryModel> sessions;
  final List<AttendanceAtRiskStudentModel> atRiskStudents;

  AttendanceClassHistoryModel({
    required this.classId,
    required this.className,
    required this.attendanceRate,
    required this.totalSessions,
    required this.presentCount,
    required this.excusedCount,
    required this.unexcusedCount,
    required this.lateCount,
    required this.sessions,
    required this.atRiskStudents,
  });

  factory AttendanceClassHistoryModel.fromJson(Map<String, dynamic> json) {
    final sessionList = json['sessions'] as List<dynamic>? ?? [];
    final riskList = json['atRiskStudents'] as List<dynamic>? ?? [];
    return AttendanceClassHistoryModel(
      classId: json['classId'] as int,
      className: json['className'] as String? ?? '',
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      presentCount: json['presentCount'] as int? ?? 0,
      excusedCount: json['excusedCount'] as int? ?? 0,
      unexcusedCount: json['unexcusedCount'] as int? ?? 0,
      lateCount: json['lateCount'] as int? ?? 0,
      sessions: sessionList
          .map((e) => AttendanceSessionSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      atRiskStudents: riskList
          .map((e) => AttendanceAtRiskStudentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
