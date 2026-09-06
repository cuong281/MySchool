export type DayOfWeekVN =
  | 'MONDAY'
  | 'TUESDAY'
  | 'WEDNESDAY'
  | 'THURSDAY'
  | 'FRIDAY'
  | 'SATURDAY'
  | 'SUNDAY';

export interface SchedulePeriodDTO {
  slotNumber: number;
  startTime: string; // HH:mm
  endTime: string;   // HH:mm
  subjectId: number;
  subjectName: string;
  teacherName: string;
  roomName: string;
  classId: number;
  className: string;
}

export interface ScheduleDayDTO {
  dayOfWeek: DayOfWeekVN;
  periods: SchedulePeriodDTO[];
}
