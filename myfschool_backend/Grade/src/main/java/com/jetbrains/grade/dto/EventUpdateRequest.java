package com.jetbrains.grade.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EventUpdateRequest {

    @NotBlank(message = "Tiêu đề không được để trống")
    @Size(max = 200, message = "Tiêu đề tối đa 200 ký tự")
    private String title;

    @Size(max = 1000, message = "Mô tả tối đa 1000 ký tự")
    private String description;

    private LocalDateTime startAt;

    private LocalDateTime endAt;

    @Size(max = 255, message = "Địa điểm tối đa 255 ký tự")
    private String location;

    @Size(max = 50, message = "Danh mục tối đa 50 ký tự")
    private String category;

    @Size(max = 50, message = "Trạng thái tối đa 50 ký tự")
    private String status;
}
