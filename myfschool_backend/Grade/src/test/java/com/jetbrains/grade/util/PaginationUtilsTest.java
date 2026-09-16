package com.jetbrains.grade.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for PaginationUtils — no Spring context required.
 */
class PaginationUtilsTest {

    // ── Defaults ─────────────────────────────────────────────────────

    @Test
    @DisplayName("null page and size → defaults (page=0, size=20)")
    void nullPageAndSize_usesDefaults() {
        Pageable p = PaginationUtils.createPageable(null, null, Sort.unsorted());
        assertEquals(0, p.getPageNumber());
        assertEquals(20, p.getPageSize());
        assertTrue(p.getSort().isUnsorted());
    }

    @Test
    @DisplayName("null page only → defaults to page 0")
    void nullPageOnly_defaultsToZero() {
        Pageable p = PaginationUtils.createPageable(null, 10, Sort.unsorted());
        assertEquals(0, p.getPageNumber());
        assertEquals(10, p.getPageSize());
    }

    @Test
    @DisplayName("null size only → defaults to size 20")
    void nullSizeOnly_defaultsToTwenty() {
        Pageable p = PaginationUtils.createPageable(3, null, Sort.unsorted());
        assertEquals(3, p.getPageNumber());
        assertEquals(20, p.getPageSize());
    }

    // ── Negative values ──────────────────────────────────────────────

    @Test
    @DisplayName("negative page → falls back to 0")
    void negativePage_fallsBackToZero() {
        Pageable p = PaginationUtils.createPageable(-1, 10, Sort.unsorted());
        assertEquals(0, p.getPageNumber());
        assertEquals(10, p.getPageSize());
    }

    @Test
    @DisplayName("negative size → falls back to default 20")
    void negativeSize_fallsBackToDefault() {
        Pageable p = PaginationUtils.createPageable(0, -5, Sort.unsorted());
        assertEquals(0, p.getPageNumber());
        assertEquals(20, p.getPageSize());
    }

    @Test
    @DisplayName("size = 0 → falls back to default 20")
    void zeroSize_fallsBackToDefault() {
        Pageable p = PaginationUtils.createPageable(0, 0, Sort.unsorted());
        assertEquals(20, p.getPageSize());
    }

    // ── MAX_SIZE clamping ────────────────────────────────────────────

    @Test
    @DisplayName("size = 101 → clamped to MAX_SIZE (100)")
    void size101_clampedToMax() {
        Pageable p = PaginationUtils.createPageable(0, 101, Sort.unsorted());
        assertEquals(100, p.getPageSize());
    }

    @Test
    @DisplayName("size = 500 → clamped to MAX_SIZE (100)")
    void size500_clampedToMax() {
        Pageable p = PaginationUtils.createPageable(0, 500, Sort.unsorted());
        assertEquals(100, p.getPageSize());
    }

    @Test
    @DisplayName("size = 100 → exactly MAX_SIZE, not clamped")
    void size100_exactlyMax() {
        Pageable p = PaginationUtils.createPageable(0, 100, Sort.unsorted());
        assertEquals(100, p.getPageSize());
    }

    // ── Valid inputs ─────────────────────────────────────────────────

    @Test
    @DisplayName("valid page=2 and size=15 → respected as-is")
    void validPageAndSize() {
        Pageable p = PaginationUtils.createPageable(2, 15, Sort.unsorted());
        assertEquals(2, p.getPageNumber());
        assertEquals(15, p.getPageSize());
    }

    // ── Sort via String overload ─────────────────────────────────────

    @Test
    @DisplayName("sortField='title' direction='asc' → ASC sort")
    void sortAsc() {
        Pageable p = PaginationUtils.createPageable(0, 10, "title", "asc");
        Sort.Order order = p.getSort().getOrderFor("title");
        assertNotNull(order);
        assertEquals(Sort.Direction.ASC, order.getDirection());
    }

    @Test
    @DisplayName("sortField='title' direction='desc' → DESC sort")
    void sortDesc() {
        Pageable p = PaginationUtils.createPageable(0, 10, "title", "desc");
        Sort.Order order = p.getSort().getOrderFor("title");
        assertNotNull(order);
        assertEquals(Sort.Direction.DESC, order.getDirection());
    }

    @Test
    @DisplayName("sortField='title' direction='DESC' (uppercase) → DESC sort")
    void sortDescCaseInsensitive() {
        Pageable p = PaginationUtils.createPageable(0, 10, "title", "DESC");
        Sort.Order order = p.getSort().getOrderFor("title");
        assertNotNull(order);
        assertEquals(Sort.Direction.DESC, order.getDirection());
    }

    @Test
    @DisplayName("blank sortField → unsorted")
    void blankSortField_unsorted() {
        Pageable p = PaginationUtils.createPageable(0, 10, "  ", null);
        assertTrue(p.getSort().isUnsorted());
    }

    @Test
    @DisplayName("null sortField → unsorted")
    void nullSortField_unsorted() {
        Pageable p = PaginationUtils.createPageable(0, 10, null, null);
        assertTrue(p.getSort().isUnsorted());
    }

    @Test
    @DisplayName("null Sort object → treated as unsorted")
    void nullSortObject_unsorted() {
        Pageable p = PaginationUtils.createPageable(0, 10, (Sort) null);
        assertTrue(p.getSort().isUnsorted());
    }
}
