package com.jetbrains.grade.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GradeCreateRequest {

    @NotNull(message = "Mã học sinh không được để trống")
    @Positive(message = "Mã học sinh phải là số nguyên dương")
    private Integer studentId;

    @NotNull(message = "Mã môn học không được để trống")
    @Positive(message = "Mã môn học phải là số nguyên dương")
    private Integer subjectId;

    @NotNull(message = "Mã năm học không được để trống")
    @Positive(message = "Mã năm học phải là số nguyên dương")
    private Integer schoolYearId;

    @NotNull(message = "Học kỳ không được để trống")
    @Min(value = 1, message = "Học kỳ phải là 1 hoặc 2")
    @Max(value = 2, message = "Học kỳ phải là 1 hoặc 2")
    private Integer semester;

    @NotNull(message = "Điểm chuyên cần không được để trống")
    @Min(value = 0, message = "Điểm chuyên cần phải từ 0 đến 10")
    @Max(value = 10, message = "Điểm chuyên cần phải từ 0 đến 10")
    private Double attendanceScore;

    @NotNull(message = "Điểm giữa kỳ không được để trống")
    @Min(value = 0, message = "Điểm giữa kỳ phải từ 0 đến 10")
    @Max(value = 10, message = "Điểm giữa kỳ phải từ 0 đến 10")
    private Double midtermScore;

    @NotNull(message = "Điểm cuối kỳ không được để trống")
    @Min(value = 0, message = "Điểm cuối kỳ phải từ 0 đến 10")
    @Max(value = 10, message = "Điểm cuối kỳ phải từ 0 đến 10")
    private Double finalScore;
}
