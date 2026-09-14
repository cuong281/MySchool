

class Grade {
  // ── Fields khớp tên camelCase với JSON key từ Spring Boot ─────────────
  // Spring Boot / Jackson tự chuyển tên field Java → JSON key giữ nguyên
  final int?    id;          // null khi tạo mới (DB tự sinh)
  final int     studentId;
  final String  studentName;
  final String  className;
  final String  subjectCode;
  final String  subjectName;
  final String  academicYear;
  final int     semester;
  final double? attendanceScore;
  final double? midtermScore;
  final double? finalScore;

  // 3 field dưới: computed bởi Spring Boot / SQL, trả về sau save
  // Không cần gửi lên server khi POST/PUT
  final double? averageScore;
  final String? letterGrade;
  final double? gpa4;

  const Grade({
    this.id,                   // optional — null khi ADD mới
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.subjectCode,
    required this.subjectName,
    required this.academicYear,
    required this.semester,
    this.attendanceScore,
    this.midtermScore,
    this.finalScore,
    this.averageScore,
    this.letterGrade,
    this.gpa4,
  });

  // ── fromJson
  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id:              (json['id']             as num?)?.toInt(),
      studentId:       (json['studentId']      as num?)?.toInt()    ?? 0,
      studentName:      json['studentName']     as String? ?? '',
      className:        json['className']       as String? ?? '',
      subjectCode:      json['subjectCode']     as String? ?? '',
      subjectName:      json['subjectName']     as String? ?? '',
      academicYear:     json['academicYear']    as String? ?? '',
      semester:        (json['semester']        as num?)?.toInt()    ?? 1,
      attendanceScore: (json['attendanceScore'] as num?)?.toDouble(),
      midtermScore:    (json['midtermScore']    as num?)?.toDouble(),
      finalScore:      (json['finalScore']      as num?)?.toDouble(),
      averageScore:    (json['averageScore']    as num?)?.toDouble(),
      letterGrade:      json['letterGrade']     as String?,
      gpa4:            (json['gpa4']            as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'studentId':       studentId,
      'studentName':     studentName,
      'className':       className,
      'subjectCode':     subjectCode,
      'subjectName':     subjectName,
      'academicYear':    academicYear,
      'semester':        semester,
      'attendanceScore': attendanceScore,
      'midtermScore':    midtermScore,
      'finalScore':      finalScore,
      if (averageScore != null) 'averageScore': averageScore,
      if (letterGrade != null) 'letterGrade': letterGrade,
      if (gpa4 != null) 'gpa4': gpa4,
    };
  }

  Grade copyWith({
    int?    id,
    int?    studentId,
    String? studentName,
    String? className,
    String? subjectCode,
    String? subjectName,
    String? academicYear,
    int?    semester,
    double? attendanceScore,
    double? midtermScore,
    double? finalScore,
    double? averageScore,
    String? letterGrade,
    double? gpa4,
  }) {
    return Grade(
      id:              id              ?? this.id,
      studentId:       studentId       ?? this.studentId,
      studentName:     studentName     ?? this.studentName,
      className:       className       ?? this.className,
      subjectCode:     subjectCode     ?? this.subjectCode,
      subjectName:     subjectName     ?? this.subjectName,
      academicYear:    academicYear    ?? this.academicYear,
      semester:        semester        ?? this.semester,
      attendanceScore: attendanceScore ?? this.attendanceScore,
      midtermScore:    midtermScore    ?? this.midtermScore,
      finalScore:      finalScore      ?? this.finalScore,
      averageScore:    averageScore    ?? this.averageScore,
      letterGrade:     letterGrade     ?? this.letterGrade,
      gpa4:            gpa4            ?? this.gpa4,
    );
  }

  // ── toString: để debug dễ hơn ─────────────────────────────────────────
  @override
  String toString() =>
      'Grade(id:$id, student:$studentName, '
      'subject:$subjectCode, avg:$averageScore, rank:$letterGrade)';
}