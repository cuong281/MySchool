import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myfschools/models/school_class_model.dart';

class SchoolClassApi {
  static final SchoolClassApi instance = SchoolClassApi._init();
  SchoolClassApi._init();

  static const String _baseUrl = 'http://10.0.2.2:8080/api/classes';

  Future<List<SchoolClassModel>> getAllClasses() async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      print('Get Classes Status: ${response.statusCode}');
      print('Get Classes Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => SchoolClassModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get classes error: $e');
      return [];
    }
  }
}
