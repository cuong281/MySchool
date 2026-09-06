-- V6: Clean up dummy Sunday attendance records on 2026-09-06
DELETE FROM Attendances WHERE AttendanceDate <= '2026-09-06';
