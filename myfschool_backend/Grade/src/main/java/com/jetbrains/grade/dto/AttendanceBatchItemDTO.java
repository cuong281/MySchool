package com.jetbrains.grade.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceBatchItemDTO {

    @NotNull(message = "Mã học sinh không được để trống")
    @Positive(message = "Mã học sinh phải là số nguyên dương")
    private Integer studentId;

    @NotBlank(message = "Trạng thái điểm danh không được để trống")
    @Pattern(regexp = "(?i)^(PRESENT|EXCUSED_ABSENCE|UNEXCUSED_ABSENCE|LATE)$", message = "Trạng thái điểm danh không hợp lệ. Hỗ trợ: PRESENT, EXCUSED_ABSENCE, UNEXCUSED_ABSENCE, LATE")
    private String status;

    @Size(max = 255, message = "Ghi chú không được vượt quá 255 ký tự")
    private String note;

    private Boolean overrideLeave;
    private String overrideReason;
}
