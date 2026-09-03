import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reward_discipline_model.dart';

class RewardDisciplineService {
  static const String _baseUrl = 'http://10.0.2.2:8080/api/rewards-discipline';

  Future<List<RewardDisciplineModel>> getByUserId(int userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/user/$userId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => RewardDisciplineModel.fromJson(item)).toList();
    } else {
      throw "Lỗi khi tải danh sách khen thưởng/kỷ luật";
    }
  }

  Future<List<RewardDisciplineModel>> getAllRewards() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => RewardDisciplineModel.fromJson(item)).toList();
    } else {
      throw "Lỗi khi tải tất cả khen thưởng/kỷ luật";
    }
  }

  Future<List<RewardDisciplineModel>> getByClassId(int classId) async {
    final response = await http.get(Uri.parse('$_baseUrl/class/$classId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => RewardDisciplineModel.fromJson(item)).toList();
    } else {
      throw "Lỗi khi tải khen thưởng/kỷ luật theo lớp";
    }
  }
}
