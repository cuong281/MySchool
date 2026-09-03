import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/request_model.dart';

void main() {
  group('LeaveRequest', () {
    test('tao LeaveRequest voi tat ca fields', () {
      final request = LeaveRequest(
        id: '1',
        type: 'Xin nghi hoc',
        fromDate: DateTime(2026, 9, 10),
        toDate: DateTime(2026, 9, 12),
        reason: 'Bi om',
        createdAt: DateTime(2026, 9, 5),
        status: 'Cho duyet',
      );

      expect(request.id, '1');
      expect(request.type, 'Xin nghi hoc');
      expect(request.fromDate, DateTime(2026, 9, 10));
      expect(request.toDate, DateTime(2026, 9, 12));
      expect(request.reason, 'Bi om');
      expect(request.status, 'Cho duyet');
    });

    test('status mac dinh la Cho duyet', () {
      final request = LeaveRequest(
        id: '2',
        type: 'Xin nghi hoc dai ngay',
        fromDate: DateTime(2026, 9, 15),
        toDate: DateTime(2026, 9, 20),
        reason: 'Ly do ca nhan',
        createdAt: DateTime(2026, 9, 10),
      );

      expect(request.status, 'Chờ duyệt');
    });
  });

  // TC-UNIT-015
  group('RequestStore', () {
    setUp(() {
      RequestStore.instance.clear();
    });

    test('add va lay requests', () {
      final request = LeaveRequest(
        id: '1',
        type: 'Xin nghi hoc',
        fromDate: DateTime(2026, 9, 10),
        toDate: DateTime(2026, 9, 12),
        reason: 'Test',
        createdAt: DateTime(2026, 9, 5),
      );

      RequestStore.instance.add(request);

      expect(RequestStore.instance.requests.length, 1);
      expect(RequestStore.instance.requests[0].id, '1');
    });

    test('don moi nhat len dau (insert(0))', () {
      final req1 = LeaveRequest(
        id: '1',
        type: 'Xin nghi hoc',
        fromDate: DateTime(2026, 9, 10),
        toDate: DateTime(2026, 9, 12),
        reason: 'First',
        createdAt: DateTime(2026, 9, 5),
      );
      final req2 = LeaveRequest(
        id: '2',
        type: 'Xin nghi hoc',
        fromDate: DateTime(2026, 9, 15),
        toDate: DateTime(2026, 9, 16),
        reason: 'Second',
        createdAt: DateTime(2026, 9, 10),
      );

      RequestStore.instance.add(req1);
      RequestStore.instance.add(req2);

      expect(RequestStore.instance.requests[0].id, '2'); // newest first
      expect(RequestStore.instance.requests[1].id, '1');
    });

    test('clear xoa het requests', () {
      RequestStore.instance.add(LeaveRequest(
        id: '1',
        type: 'Test',
        fromDate: DateTime.now(),
        toDate: DateTime.now(),
        reason: 'Test',
        createdAt: DateTime.now(),
      ));

      expect(RequestStore.instance.requests.length, 1);

      RequestStore.instance.clear();

      expect(RequestStore.instance.requests, isEmpty);
    });

    test('requests tra ve unmodifiable list', () {
      RequestStore.instance.add(LeaveRequest(
        id: '1',
        type: 'Test',
        fromDate: DateTime.now(),
        toDate: DateTime.now(),
        reason: 'Test',
        createdAt: DateTime.now(),
      ));

      expect(
        () => RequestStore.instance.requests.add(LeaveRequest(
          id: '2',
          type: 'Test',
          fromDate: DateTime.now(),
          toDate: DateTime.now(),
          reason: 'Test',
          createdAt: DateTime.now(),
        )),
        throwsUnsupportedError,
      );
    });
  });
}
