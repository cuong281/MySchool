import 'dart:convert';

class SchedulePeriodModel {
  final int slotNumber;
  final String startTime;
  final String endTime;
  final String subjectName;
  final String teacherName;
  final String? roomName;
  final int? classId;
  final String? className;

  SchedulePeriodModel({
    required this.slotNumber,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    required this.teacherName,
    this.roomName,
    this.classId,
    this.className,
  });

  factory SchedulePeriodModel.fromMap(Map<String, dynamic> map) {
    return SchedulePeriodModel(
      slotNumber: map['slotNumber']?.toInt() ?? 0,
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      subjectName: map['subjectName'] ?? '',
      teacherName: map['teacherName'] ?? '',
      roomName: map['roomName'],
      classId: map['classId']?.toInt(),
      className: map['className'],
    );
  }

  factory SchedulePeriodModel.fromJson(String source) => 
      SchedulePeriodModel.fromMap(json.decode(source));
}

class ScheduleDayModel {
  final String dayOfWeek;
  final List<SchedulePeriodModel> periods;

  ScheduleDayModel({
    required this.dayOfWeek,
    required this.periods,
  });

  factory ScheduleDayModel.fromMap(Map<String, dynamic> map) {
    return ScheduleDayModel(
      dayOfWeek: map['dayOfWeek'] ?? '',
      periods: List<SchedulePeriodModel>.from(
        (map['periods'] ?? []).map((x) => SchedulePeriodModel.fromMap(x)),
      ),
    );
  }

  factory ScheduleDayModel.fromJson(String source) => 
      ScheduleDayModel.fromMap(json.decode(source));
}
