package com.jetbrains.grade.util;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

public final class PaginationUtils {

    public static final int DEFAULT_PAGE = 0;
    public static final int DEFAULT_SIZE = 20;
    public static final int MAX_SIZE = 100;

    private PaginationUtils() {
    }

    public static Pageable createPageable(Integer page, Integer size, Sort sort) {
        int pageIndex = (page != null && page >= 0) ? page : DEFAULT_PAGE;
        int pageSize = (size != null && size > 0) ? Math.min(size, MAX_SIZE) : DEFAULT_SIZE;
        Sort sortOrder = sort != null ? sort : Sort.unsorted();
        return PageRequest.of(pageIndex, pageSize, sortOrder);
    }

    public static Pageable createPageable(Integer page, Integer size, String sortField, String direction) {
        Sort sort = Sort.unsorted();
        if (sortField != null && !sortField.isBlank()) {
            Sort.Direction dir = "desc".equalsIgnoreCase(direction) ? Sort.Direction.DESC : Sort.Direction.ASC;
            sort = Sort.by(dir, sortField.trim());
        }
        return createPageable(page, size, sort);
    }
}
