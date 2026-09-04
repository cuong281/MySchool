import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/services/report_api.dart';
import 'package:myfschools/services/api_client.dart';

void main() {
  group('ReportApi Service Tests', () {
    test('ReportApi instance is singleton', () {
      final a = ReportApi.instance;
      final b = ReportApi.instance;
      expect(identical(a, b), isTrue);
    });

    test('ApiClient timeoutDuration is configured to 15 seconds', () {
      expect(ApiClient.timeoutDuration, equals(const Duration(seconds: 15)));
    });
  });
}
