package com.jetbrains.grade.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceCreateRequest {

    @NotNull(message = "Mã học sinh không được để trống")
    @Positive(message = "Mã học sinh phải là số nguyên dương")
    private Integer studentId;

    @NotNull(message = "Mã lớp học không được để trống")
    @Positive(message = "Mã lớp học phải là số nguyên dương")
    private Integer classId;

    private Integer subjectId;

    @NotNull(message = "Ngày điểm danh không được để trống")
    private LocalDate attendanceDate;

    @Min(value = 1, message = "Số tiết phải từ 1 đến 12")
    @Max(value = 12, message = "Số tiết phải từ 1 đến 12")
    private Integer slotNumber;

    @NotBlank(message = "Trạng thái điểm danh không được để trống")
    @Pattern(regexp = "(?i)^(PRESENT|EXCUSED_ABSENCE|UNEXCUSED_ABSENCE|LATE)$", message = "Trạng thái điểm danh không hợp lệ. Hỗ trợ: PRESENT, EXCUSED_ABSENCE, UNEXCUSED_ABSENCE, LATE")
    private String status;

    @Size(max = 255, message = "Ghi chú không được vượt quá 255 ký tự")
    private String note;
}
