import 'dart:convert';
import 'package:myfschools/models/school_class_model.dart';
import 'package:myfschools/services/api_client.dart';

class SchoolClassApi {
  static final SchoolClassApi instance = SchoolClassApi._init();
  SchoolClassApi._init();

  static const String _baseUrl = '${ApiClient.baseUrl}/classes';

  Future<List<SchoolClassModel>> getAllClasses() async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await ApiClient.instance.get(uri);

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
