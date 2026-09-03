import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/news_model.dart';

void main() {
  group('NewsModel', () {
    // TC-UNIT-009
    test('fromJson voi publishedDate parsing', () {
      final json = {
        'id': 1,
        'title': 'Thong bao nghi Tet',
        'content': 'Noi dung thong bao nghi Tet 2026',
        'imageUrl': 'https://example.com/image.jpg',
        'category': 'Announcement',
        'publishedDate': '2026-01-20T08:00:00.000',
      };

      final news = NewsModel.fromJson(json);

      expect(news.id, 1);
      expect(news.title, 'Thong bao nghi Tet');
      expect(news.content, 'Noi dung thong bao nghi Tet 2026');
      expect(news.imageUrl, 'https://example.com/image.jpg');
      expect(news.category, 'Announcement');
      expect(news.publishedDate.year, 2026);
      expect(news.publishedDate.month, 1);
      expect(news.publishedDate.day, 20);
    });

    test('fromJson publishedDate null fallback to now', () {
      final json = {
        'id': 2,
        'title': 'No date',
        'content': 'Content',
        'imageUrl': '',
        'category': 'Info',
        'publishedDate': null,
      };

      final news = NewsModel.fromJson(json);

      expect(news.publishedDate.year, DateTime.now().year);
    });

    test('fromJson voi gia tri thieu', () {
      final json = <String, dynamic>{};

      final news = NewsModel.fromJson(json);

      expect(news.id, 0);
      expect(news.title, '');
      expect(news.content, '');
      expect(news.imageUrl, '');
      expect(news.category, '');
    });

    test('toJson serializes publishedDate as ISO 8601', () {
      final news = NewsModel(
        id: 1,
        title: 'Test',
        content: 'Content',
        imageUrl: '',
        category: 'Info',
        publishedDate: DateTime(2026, 3, 15, 10, 30),
      );

      final json = news.toJson();

      expect(json['publishedDate'], contains('2026-03-15'));
    });
  });
}
