class NewsModel {
  final int id;
  final String title;
  final String content;
  final String imageUrl;
  final String category;
  final DateTime publishedDate;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.publishedDate,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      publishedDate: json['publishedDate'] != null 
          ? DateTime.parse(json['publishedDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'publishedDate': publishedDate.toIso8601String(),
    };
  }
}
