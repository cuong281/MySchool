package com.jetbrains.grade.dto;

public interface AttendanceStatusCountProjection {
    Integer getStudentId();
    String getStatus();
    Long getCount();
}
