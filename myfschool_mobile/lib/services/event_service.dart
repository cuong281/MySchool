import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_model.dart';

class EventService {
  static const String _baseUrl = 'http://10.0.2.2:8080/api/events';

  Future<List<EventModel>> getAllEvents() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => EventModel.fromJson(item)).toList();
    } else {
      throw 'Lỗi khi tải danh sách sự kiện';
    }
  }
}
