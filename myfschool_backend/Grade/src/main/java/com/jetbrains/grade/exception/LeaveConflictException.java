package com.jetbrains.grade.exception;

import lombok.Getter;

@Getter
public class LeaveConflictException extends RuntimeException {
    private final Integer studentId;
    private final Integer leaveRequestId;
    private final String studentName;
    private final String studentCode;

    public LeaveConflictException(Integer studentId, Integer leaveRequestId, String studentName, String studentCode, String message) {
        super(message);
        this.studentId = studentId;
        this.leaveRequestId = leaveRequestId;
        this.studentName = studentName;
        this.studentCode = studentCode;
    }
}
