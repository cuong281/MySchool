import 'package:flutter/material.dart';

/// Model cho 1 đơn xin phép
class LeaveRequest {
  final String id;
  final String type;         // 'Xin nghỉ học' hoặc 'Xin nghỉ học dài ngày'
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final DateTime createdAt;
  final String status;       // 'Chờ duyệt', 'Đã duyệt', 'Từ chối'

  LeaveRequest({
    required this.id,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.createdAt,
    this.status = 'Chờ duyệt',
  });
}

/// Singleton lưu trữ danh sách đơn đã gửi (trong bộ nhớ)
class RequestStore {
  static final RequestStore instance = RequestStore._internal();
  RequestStore._internal();

  final List<LeaveRequest> _requests = [];

  List<LeaveRequest> get requests => List.unmodifiable(_requests);

  void add(LeaveRequest request) {
    _requests.insert(0, request); // Đơn mới nhất lên đầu
  }

  void clear() {
    _requests.clear();
  }
}
