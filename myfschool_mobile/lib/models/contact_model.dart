class Contact {
  final String id;
  final int? userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String role; // e.g., "Giáo viên", "Nhà trường"
  final String subject; // e.g., "Tin học và công nghệ", "Vovinam"
  final String avatarUrl;
  final bool isTeacher;
  final bool isHomeroom;
  final bool isPhonePublic;
  final String status;

  Contact({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    this.phoneNumber = '',
    required this.role,
    this.subject = '',
    this.avatarUrl = '',
    this.isTeacher = true,
    this.isHomeroom = false,
    this.isPhonePublic = false,
    this.status = 'ACTIVE',
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: (json['teacherId'] ?? json['id'] ?? '').toString(),
      userId: json['userId'] is int ? json['userId'] : (json['userId'] != null ? int.tryParse(json['userId'].toString()) : null),
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone'] ?? json['phoneNumber'] ?? '',
      role: json['roleType'] == 'HOMEROOM_TEACHER'
          ? 'GV Chủ nhiệm'
          : (json['roleType'] == 'SUBJECT_TEACHER'
              ? 'GV Bộ môn'
              : (json['role'] ?? '')),
      subject: json['subjectName'] ?? json['subject'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      isTeacher: json['isTeacher'] ?? true,
      isHomeroom: json['isHomeroom'] ?? (json['roleType'] == 'HOMEROOM_TEACHER'),
      isPhonePublic: json['isPhonePublic'] ?? false,
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'subject': subject,
      'avatarUrl': avatarUrl,
      'isTeacher': isTeacher,
      'isHomeroom': isHomeroom,
      'isPhonePublic': isPhonePublic,
      'status': status,
    };
  }
}
