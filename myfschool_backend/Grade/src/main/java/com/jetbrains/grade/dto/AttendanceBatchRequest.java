package com.jetbrains.grade.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceBatchRequest {

    @NotNull(message = "Mã lớp học không được để trống")
    @Positive(message = "Mã lớp học phải là số nguyên dương")
    private Integer classId;

    private Integer subjectId;

    @NotNull(message = "Số tiết không được để trống")
    @Min(value = 1, message = "Số tiết phải từ 1 đến 12")
    @Max(value = 12, message = "Số tiết phải từ 1 đến 12")
    private Integer slotNumber;

    @NotNull(message = "Ngày điểm danh không được để trống")
    private LocalDate attendanceDate;

    @NotEmpty(message = "Danh sách học sinh điểm danh không được để trống")
    @Valid
    private List<@Valid AttendanceBatchItemDTO> items;
}
