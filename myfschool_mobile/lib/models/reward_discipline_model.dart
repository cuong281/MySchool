class RewardDisciplineModel {
  final int? id;
  final int userId;
  final String type; // REWARD, DISCIPLINE
  final String content;
  final String date;
  final String? decisionNumber;
  final String? userName; // Added
  final String? className; // Added

  RewardDisciplineModel({
    this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.date,
    this.decisionNumber,
    this.userName,
    this.className,
  });

  factory RewardDisciplineModel.fromJson(Map<String, dynamic> json) {
    return RewardDisciplineModel(
      id: json['id'],
      userId: json['user'] != null ? json['user']['id'] : 0, 
      userName: json['user'] != null ? json['user']['username'] : 'N/A',
      className: json['user'] != null ? json['user']['className'] : 'N/A',
      type: json['type'] ?? '',
      content: json['content'] ?? '',
      date: json['date'] ?? '',
      decisionNumber: json['decisionNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'content': content,
      'date': date,
      'decisionNumber': decisionNumber,
    };
  }
}
