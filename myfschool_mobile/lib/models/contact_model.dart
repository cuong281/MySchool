class Contact {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role; // e.g., "Giáo viên", "Nhà trường"
  final String subject; // e.g., "Tin học và công nghệ", "Vovinam"
  final String avatarUrl;
  final bool isTeacher;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber = '',
    required this.role,
    this.subject = '',
    this.avatarUrl = '',
    this.isTeacher = true,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
      subject: json['subject'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      isTeacher: json['isTeacher'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'subject': subject,
      'avatarUrl': avatarUrl,
      'isTeacher': isTeacher,
    };
  }
}
