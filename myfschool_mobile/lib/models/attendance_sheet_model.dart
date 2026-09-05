class AttendanceSheetStudentModel {
  final int studentId;
  final String studentName;
  final String studentCode;
  String? currentStatus; // 'PRESENT', 'EXCUSED_ABSENCE', 'UNEXCUSED_ABSENCE', 'LATE'
  final bool hasApprovedLeave;
  final int? leaveRequestId;
  final String? leaveReason;
  String? note;

  // Local state for override handling
  bool overrideLeave;
  String? overrideReason;

  AttendanceSheetStudentModel({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.currentStatus,
    this.hasApprovedLeave = false,
    this.leaveRequestId,
    this.leaveReason,
    this.note,
    this.overrideLeave = false,
    this.overrideReason,
  });

  factory AttendanceSheetStudentModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSheetStudentModel(
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String? ?? '',
      studentCode: json['studentCode'] as String? ?? '',
      currentStatus: json['currentStatus'] as String?,
      hasApprovedLeave: json['hasApprovedLeave'] as bool? ?? false,
      leaveRequestId: json['leaveRequestId'] as int?,
      leaveReason: json['leaveReason'] as String?,
      note: json['note'] as String?,
      overrideLeave: false,
      overrideReason: null,
    );
  }

  AttendanceSheetStudentModel copyWith({
    int? studentId,
    String? studentName,
    String? studentCode,
    String? currentStatus,
    bool? hasApprovedLeave,
    int? leaveRequestId,
    String? leaveReason,
    String? note,
    bool? overrideLeave,
    String? overrideReason,
  }) {
    return AttendanceSheetStudentModel(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentCode: studentCode ?? this.studentCode,
      currentStatus: currentStatus ?? this.currentStatus,
      hasApprovedLeave: hasApprovedLeave ?? this.hasApprovedLeave,
      leaveRequestId: leaveRequestId ?? this.leaveRequestId,
      leaveReason: leaveReason ?? this.leaveReason,
      note: note ?? this.note,
      overrideLeave: overrideLeave ?? this.overrideLeave,
      overrideReason: overrideReason ?? this.overrideReason,
    );
  }
}

class AttendanceSheetModel {
  final int classId;
  final String className;
  final int? subjectId;
  final String? subjectName;
  final int slotNumber;
  final String? startTime;
  final String? endTime;
  final String attendanceDate;
  final bool canEdit;
  final String? lockReason;
  final int totalStudents;
  final List<AttendanceSheetStudentModel> students;

  AttendanceSheetModel({
    required this.classId,
    required this.className,
    this.subjectId,
    this.subjectName,
    required this.slotNumber,
    this.startTime,
    this.endTime,
    required this.attendanceDate,
    required this.canEdit,
    this.lockReason,
    required this.totalStudents,
    required this.students,
  });

  factory AttendanceSheetModel.fromJson(Map<String, dynamic> json) {
    final list = json['students'] as List<dynamic>? ?? [];
    return AttendanceSheetModel(
      classId: json['classId'] as int,
      className: json['className'] as String? ?? '',
      subjectId: json['subjectId'] as int?,
      subjectName: json['subjectName'] as String?,
      slotNumber: json['slotNumber'] as int? ?? 1,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      attendanceDate: json['attendanceDate'] as String? ?? '',
      canEdit: json['canEdit'] as bool? ?? false,
      lockReason: json['lockReason'] as String?,
      totalStudents: json['totalStudents'] as int? ?? 0,
      students: list
          .map((e) => AttendanceSheetStudentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AttendanceBatchItem {
  final int studentId;
  final String status;
  final String? note;
  final bool overrideLeave;
  final String? overrideReason;

  AttendanceBatchItem({
    required this.studentId,
    required this.status,
    this.note,
    this.overrideLeave = false,
    this.overrideReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'status': status,
      if (note != null && note!.isNotEmpty) 'note': note,
      'overrideLeave': overrideLeave,
      if (overrideReason != null && overrideReason!.isNotEmpty)
        'overrideReason': overrideReason,
    };
  }
}

class AttendanceBatchRequest {
  final int classId;
  final int? subjectId;
  final int slotNumber;
  final String attendanceDate;
  final List<AttendanceBatchItem> items;

  AttendanceBatchRequest({
    required this.classId,
    this.subjectId,
    required this.slotNumber,
    required this.attendanceDate,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      if (subjectId != null) 'subjectId': subjectId,
      'slotNumber': slotNumber,
      'attendanceDate': attendanceDate,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class LeaveConflictError {
  final int status;
  final String error;
  final String message;
  final int? studentId;
  final int? leaveRequestId;

  LeaveConflictError({
    required this.status,
    required this.error,
    required this.message,
    this.studentId,
    this.leaveRequestId,
  });

  factory LeaveConflictError.fromJson(Map<String, dynamic> json) {
    return LeaveConflictError(
      status: json['status'] as int? ?? 409,
      error: json['error'] as String? ?? 'CONFLICT_APPROVED_LEAVE',
      message: json['message'] as String? ?? 'Học sinh có đơn nghỉ phép được duyệt.',
      studentId: json['studentId'] as int?,
      leaveRequestId: json['leaveRequestId'] as int?,
    );
  }
}
