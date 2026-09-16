-- ==========================================================
-- Flyway Migration V9: Add Unique Constraints on Grades and Attendances
-- ==========================================================

-- 1. Unique constraint on Grades: one grade per student, subject, school year, and semester
ALTER TABLE Grades ADD CONSTRAINT UK_Grades_Student_Subject_Year_Semester 
    UNIQUE (StudentID, SubjectID, SchoolYearID, Semester);

-- 2. Unique constraint on Attendances: one attendance record per student, date, and slot
ALTER TABLE Attendances ADD CONSTRAINT UK_Attendances_Student_Date_Slot 
    UNIQUE (StudentID, AttendanceDate, SlotNumber);
