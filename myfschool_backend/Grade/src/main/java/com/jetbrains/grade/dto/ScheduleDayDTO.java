package com.jetbrains.grade.dto;

import com.jetbrains.grade.model.DayOfWeekVN;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduleDayDTO {
    private DayOfWeekVN dayOfWeek;
    private List<SchedulePeriodDTO> periods;
}
