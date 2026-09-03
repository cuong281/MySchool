package com.jetbrains.grade.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class EventDTO {
    private Integer id;
    private String title;
    private String description;
    private String date;
    private String time;
    private String location;
    private String category;
    private String status;
    private String color;
    private String icon;
}
