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
public class NewsUpdateRequest {

    @NotBlank(message = "Tiêu đề không được để trống")
    @Size(max = 255, message = "Tiêu đề tối đa 255 ký tự")
    private String title;

    @NotBlank(message = "Nội dung không được để trống")
    private String content;

    @Size(max = 500, message = "Đường dẫn ảnh tối đa 500 ký tự")
    private String imageUrl;

    @Size(max = 100, message = "Danh mục tối đa 100 ký tự")
    private String category;

    private LocalDateTime publishedDate;

    private Boolean isActive;
}
