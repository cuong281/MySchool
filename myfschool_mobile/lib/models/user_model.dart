class UserModel {
  final int? id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final List<String> roles;
  String get role => roles.isNotEmpty ? roles.first : 'Student';
  String get fullName => '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : username;
  final int? studentId;
  final String studentCode;
  final int? classId;
  final String className;
  final int? teacherId;
  final String? dateOfBirth;
  final String? gender;
  final String? address;

  bool get isTeacher => roles.any((r) => r.toLowerCase().contains('teacher'));
  bool get isAdmin => roles.any((r) => r.toLowerCase().contains('admin'));
  bool get isStudent => !isAdmin && !isTeacher;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.roles,
    this.studentId,
    required this.studentCode,
    this.classId,
    required this.className,
    this.teacherId,
    this.dateOfBirth,
    this.gender,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'roles': roles,
      'studentId': studentId,
      'studentCode': studentCode,
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['userId'] ?? map['id'] ?? map['userID'],
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      roles: (map['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Student'],
      studentId: map['studentId'] ?? map['studentID'],
      studentCode: map['studentCode'] ?? '',
      classId: map['classId'] ?? map['classID'],
      className: map['className'] ?? '',
      teacherId: map['teacherId'] ?? map['teacherID'],
      dateOfBirth: map['dateOfBirth']?.toString(),
      gender: map['gender']?.toString(),
      address: map['address']?.toString(),
    );
  }
}
