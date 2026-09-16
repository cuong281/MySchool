package com.jetbrains.grade.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
public class LeaveRequestCreateRequest {
    private Integer userId;

    @Size(max = 50, message = "Loại đơn tối đa 50 ký tự")
    private String requestType;

    @NotNull(message = "Ngày bắt đầu không được để trống")
    private LocalDate fromDate;

    @NotNull(message = "Ngày kết thúc không được để trống")
    private LocalDate toDate;

    @NotBlank(message = "Lý do xin nghỉ không được để trống")
    @Size(min = 3, max = 1000, message = "Lý do xin nghỉ phải từ 3 đến 1000 ký tự")
    private String reason;

    private Integer fileId;
}
