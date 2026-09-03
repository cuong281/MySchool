import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsApi {
  static final NewsApi instance = NewsApi._internal();
  NewsApi._internal();

  // Update base URL if needed. Assuming localhost:8080 for now.
  static const String baseUrl = 'http://10.0.2.2:8080/api/news';

  Future<List<NewsModel>> getAllNews() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => NewsModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching news: $e');
      return [];
    }
  }

  Future<NewsModel?> getNewsById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        return NewsModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('Error fetching news detail: $e');
      return null;
    }
  }
}
