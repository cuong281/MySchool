import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:myfschools/services/api_client.dart';
import '../models/reward_discipline_model.dart';

class RewardDisciplineService {
  static const String _endpoint = '${ApiClient.baseUrl}/rewards-discipline';

  /// Get rewards and disciplines with optional filters (role enforced by backend)
  Future<List<RewardDisciplineModel>> getRewards({
    int? classId,
    int? semester,
    String? type,
    String? schoolYear,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (classId != null) queryParams['classId'] = classId.toString();
      if (semester != null) queryParams['semester'] = semester.toString();
      if (type != null && type.isNotEmpty && type != 'Tất cả') queryParams['type'] = type;
      if (schoolYear != null && schoolYear.isNotEmpty && schoolYear != 'Tất cả') queryParams['schoolYear'] = schoolYear;

      final uri = Uri.parse(_endpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => RewardDisciplineModel.fromJson(item)).toList();
      } else {
        debugPrint('RewardDisciplineService error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('RewardDisciplineService exception: $e');
      return [];
    }
  }

  /// Get rewards and disciplines for current authenticated user (student)
  Future<List<RewardDisciplineModel>> getMyRewards({
    int? semester,
    String? type,
    String? schoolYear,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (semester != null) queryParams['semester'] = semester.toString();
      if (type != null && type.isNotEmpty && type != 'Tất cả') queryParams['type'] = type;
      if (schoolYear != null && schoolYear.isNotEmpty && schoolYear != 'Tất cả') queryParams['schoolYear'] = schoolYear;

      final uri = Uri.parse('$_endpoint/me').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => RewardDisciplineModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('getMyRewards exception: $e');
      return [];
    }
  }

  Future<List<RewardDisciplineModel>> getByUserId(int userId) async {
    try {
      final uri = Uri.parse('$_endpoint/user/$userId');
      final response = await ApiClient.instance.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => RewardDisciplineModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<RewardDisciplineModel>> getAllRewards() async {
    return getRewards();
  }

  Future<List<RewardDisciplineModel>> getByClassId(int classId) async {
    return getRewards(classId: classId);
  }
}
