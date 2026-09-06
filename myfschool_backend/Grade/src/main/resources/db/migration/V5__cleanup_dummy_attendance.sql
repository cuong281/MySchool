-- V5: Cleanup legacy dummy attendance records created before official date 2026-09-06
DELETE FROM Attendances WHERE AttendanceDate < '2026-09-06';
