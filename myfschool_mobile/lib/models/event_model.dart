class EventModel {
  final int? id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final String category;
  final String status;
  final String color;
  final String icon;

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    required this.status,
    required this.color,
    required this.icon,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      color: json['color'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'category': category,
      'status': status,
      'color': color,
      'icon': icon,
    };
  }
}
