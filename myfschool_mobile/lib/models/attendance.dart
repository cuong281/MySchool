class AttendanceRecord {
  final int? id;
  final int? studentId;
  final String studentName;
  final String studentCode;
  final int? classId;
  final String className;
  final int? subjectId;
  final String subjectName;
  final DateTime attendanceDate;
  final int? slotNumber;
  final String status; // 'PRESENT', 'EXCUSED_ABSENCE', 'UNEXCUSED_ABSENCE', 'LATE'
  final String note;
  final String recordedByName;

  AttendanceRecord({
    this.id,
    this.studentId,
    required this.studentName,
    required this.studentCode,
    this.classId,
    required this.className,
    this.subjectId,
    required this.subjectName,
    required this.attendanceDate,
    this.slotNumber,
    required this.status,
    required this.note,
    required this.recordedByName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int?,
      studentId: json['studentId'] as int?,
      studentName: json['studentName'] as String? ?? '',
      studentCode: json['studentCode'] as String? ?? '',
      classId: json['classId'] as int?,
      className: json['className'] as String? ?? '',
      subjectId: json['subjectId'] as int?,
      subjectName: json['subjectName'] as String? ?? '',
      attendanceDate: json['attendanceDate'] != null
          ? DateTime.parse(json['attendanceDate'].toString())
          : DateTime.now(),
      slotNumber: json['slotNumber'] as int?,
      status: json['status'] as String? ?? 'PRESENT',
      note: json['note'] as String? ?? '',
      recordedByName: json['recordedByName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (studentId != null) 'studentId': studentId,
      'studentName': studentName,
      'studentCode': studentCode,
      if (classId != null) 'classId': classId,
      'className': className,
      if (subjectId != null) 'subjectId': subjectId,
      'subjectName': subjectName,
      'attendanceDate': attendanceDate.toIso8601String().split('T')[0],
      if (slotNumber != null) 'slotNumber': slotNumber,
      'status': status,
      'note': note,
      'recordedByName': recordedByName,
    };
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return 'Có mặt';
      case 'EXCUSED_ABSENCE':
        return 'Nghỉ có phép';
      case 'UNEXCUSED_ABSENCE':
        return 'Nghỉ không phép';
      case 'LATE':
        return 'Đi muộn';
      default:
        return status;
    }
  }
}
