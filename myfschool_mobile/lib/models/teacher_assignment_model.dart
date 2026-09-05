class TeacherAssignmentModel {
  final int id;
  final int? teacherId;
  final String teacherName;
  final int classId;
  final String className;
  final int? subjectId;
  final String? subjectName;
  final String? subjectCode;
  final String roleType; // HOMEROOM_TEACHER, SUBJECT_TEACHER

  TeacherAssignmentModel({
    required this.id,
    this.teacherId,
    required this.teacherName,
    required this.classId,
    required this.className,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
    required this.roleType,
  });

  bool get isHomeroom => roleType.toUpperCase() == 'HOMEROOM_TEACHER';
  bool get isSubject => roleType.toUpperCase() == 'SUBJECT_TEACHER';

  factory TeacherAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentModel(
      id: json['id'] as int? ?? 0,
      teacherId: json['teacherId'] as int?,
      teacherName: json['teacherName'] as String? ?? '',
      classId: json['classId'] as int? ?? 0,
      className: json['className'] as String? ?? '',
      subjectId: json['subjectId'] as int?,
      subjectName: json['subjectName'] as String?,
      subjectCode: json['subjectCode'] as String?,
      roleType: json['roleType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'roleType': roleType,
    };
  }
}
