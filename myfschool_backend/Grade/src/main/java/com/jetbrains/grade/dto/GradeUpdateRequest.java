package com.jetbrains.grade.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GradeUpdateRequest {

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
