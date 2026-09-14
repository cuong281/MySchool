-- Support Teacher Leave Requests
ALTER TABLE LeaveRequests MODIFY COLUMN StudentID INT NULL;

ALTER TABLE LeaveRequests ADD COLUMN TeacherID INT DEFAULT NULL AFTER StudentID;

ALTER TABLE LeaveRequests ADD CONSTRAINT FK_LeaveRequests_Teacher FOREIGN KEY (TeacherID) REFERENCES Teachers(TeacherID);

CREATE INDEX IX_LeaveRequests_TeacherID ON LeaveRequests(TeacherID);
