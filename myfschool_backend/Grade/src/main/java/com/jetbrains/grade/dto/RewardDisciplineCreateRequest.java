package com.jetbrains.grade.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
public class RewardDisciplineCreateRequest {

    @NotNull(message = "Mã học sinh không được để trống")
    @Positive(message = "Mã học sinh phải là số nguyên dương")
    private Integer studentId;

    @NotNull(message = "Mã loại khen thưởng / kỷ luật không được để trống")
    @Positive(message = "Mã loại phải là số nguyên dương")
    private Integer typeId;

    @NotNull(message = "Mã năm học không được để trống")
    @Positive(message = "Mã năm học phải là số nguyên dương")
    private Integer schoolYearId;

    @NotNull(message = "Học kỳ không được để trống")
    @Min(value = 1, message = "Học kỳ phải là 1 hoặc 2")
    @Max(value = 2, message = "Học kỳ phải là 1 hoặc 2")
    private Integer semester;

    @NotBlank(message = "Số quyết định không được để trống")
    @Size(max = 50, message = "Số quyết định tối đa 50 ký tự")
    private String decisionNumber;

    @NotBlank(message = "Nội dung không được để trống")
    @Size(max = 1000, message = "Nội dung tối đa 1000 ký tự")
    private String content;

    @NotNull(message = "Ngày ban hành không được để trống")
    private LocalDate issuedDate;

    private Integer fileId;
}
