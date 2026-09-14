package com.jetbrains.grade;

import com.jetbrains.grade.dto.GradeBatchImportItemDTO;
import com.jetbrains.grade.dto.GradeBatchImportRequest;
import com.jetbrains.grade.dto.GradeBatchImportResponse;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.*;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.service.GradeService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class GradeBatchImportTest {

    @Autowired
    private GradeService gradeService;

    @Autowired
    private GradeRepository gradeRepository;

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private SchoolClassRepository schoolClassRepository;

    @Autowired
    private SchoolYearRepository schoolYearRepository;

    @Autowired
    private UserRepository userRepository;

    private User adminUser;
    private User studentUser;
    private SchoolClass testClass;
    private Subject testSubject;
    private SchoolYear testYear;
    private List<Student> testStudents;

    @BeforeEach
    public void setUp() {
        adminUser = userRepository.findByUsername("admin").orElse(null);
        studentUser = userRepository.findByUsername("student1").orElse(null);

        List<SchoolClass> classes = schoolClassRepository.findAll();
        assertFalse(classes.isEmpty(), "Classes should exist in seeded database");
        testClass = classes.get(0);

        List<Subject> subjects = subjectRepository.findAll();
        assertFalse(subjects.isEmpty(), "Subjects should exist in seeded database");
        testSubject = subjects.get(0);

        testYear = schoolYearRepository.findAll().get(0);
        testStudents = studentRepository.findBySchoolClassId(testClass.getId());
        assertFalse(testStudents.isEmpty(), "Students should exist for class");

        // Set Security Context to Admin by default
        if (adminUser != null) {
            setAuthUser(adminUser);
        }
    }

    @AfterEach
    public void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void setAuthUser(User user) {
        CustomUserDetails userDetails = new CustomUserDetails(user);
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    public void testBatchImportMidterm_UpsertAndPreserveOtherFields() {
        Student s1 = testStudents.get(0);

        // 1. First import: Midterm score = 8.0
        GradeBatchImportRequest reqMidterm = GradeBatchImportRequest.builder()
                .importType("IMPORT_MIDTERM")
                .classId(testClass.getId())
                .subjectId(testSubject.getId())
                .schoolYearId(testYear.getId())
                .semester(1)
                .items(List.of(
                        GradeBatchImportItemDTO.builder()
                                .studentId(s1.getId())
                                .score(8.0)
                                .rowNumber(1)
                                .build()
                ))
                .build();

        GradeBatchImportResponse res1 = gradeService.batchImport(reqMidterm);
        assertTrue(res1.isSuccess());
        assertEquals(0, res1.getFailedCount());

        Grade g1 = gradeRepository.findByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(
                s1.getId(), testSubject.getId(), testYear.getId(), 1).orElseThrow();
        assertEquals(8.0, g1.getMidtermScore());

        // 2. Second import: Final score = 9.0 (Must NOT wipe midterm score!)
        GradeBatchImportRequest reqFinal = GradeBatchImportRequest.builder()
                .importType("IMPORT_FINAL")
                .classId(testClass.getId())
                .subjectId(testSubject.getId())
                .schoolYearId(testYear.getId())
                .semester(1)
                .items(List.of(
                        GradeBatchImportItemDTO.builder()
                                .studentId(s1.getId())
                                .score(9.0)
                                .rowNumber(1)
                                .build()
                ))
                .build();

        GradeBatchImportResponse res2 = gradeService.batchImport(reqFinal);
        assertTrue(res2.isSuccess());
        assertEquals(1, res2.getUpdatedCount());

        Grade g2 = gradeRepository.findByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(
                s1.getId(), testSubject.getId(), testYear.getId(), 1).orElseThrow();
        assertEquals(8.0, g2.getMidtermScore(), "Midterm score must be preserved!");
        assertEquals(9.0, g2.getFinalScore(), "Final score must be updated!");
        assertNotNull(g2.getAverageScore(), "Average score should be recalculated!");
        assertNotNull(g2.getLetterGrade(), "Letter grade should be set!");
    }

    @Test
    public void testBatchImport_ScoreOutOfRange_RollsBackAll() {
        Student s1 = testStudents.get(0);

        GradeBatchImportRequest req = GradeBatchImportRequest.builder()
                .importType("IMPORT_MIDTERM")
                .classId(testClass.getId())
                .subjectId(testSubject.getId())
                .schoolYearId(testYear.getId())
                .semester(1)
                .items(List.of(
                        GradeBatchImportItemDTO.builder()
                                .studentId(s1.getId())
                                .score(12.5) // INVALID SCORE
                                .rowNumber(25)
                                .build()
                ))
                .build();

        GradeBatchImportResponse res = gradeService.batchImport(req);
        assertFalse(res.isSuccess());
        assertEquals(1, res.getFailedCount());
        assertFalse(res.getErrors().isEmpty());
        assertEquals(25, res.getErrors().get(0).getRowNumber());
        assertTrue(res.getErrors().get(0).getMessage().contains("0.0 đến 10.0"));
    }

    @Test
    public void testBatchImport_DuplicateInRequest_FailsValidation() {
        Student s1 = testStudents.get(0);

        GradeBatchImportRequest req = GradeBatchImportRequest.builder()
                .importType("IMPORT_MIDTERM")
                .classId(testClass.getId())
                .subjectId(testSubject.getId())
                .schoolYearId(testYear.getId())
                .semester(1)
                .items(List.of(
                        GradeBatchImportItemDTO.builder()
                                .studentId(s1.getId())
                                .score(7.0)
                                .rowNumber(1)
                                .build(),
                        GradeBatchImportItemDTO.builder()
                                .studentId(s1.getId())
                                .score(8.0) // DUPLICATE SAME STUDENT IN SAME REQUEST
                                .rowNumber(2)
                                .build()
                ))
                .build();

        GradeBatchImportResponse res = gradeService.batchImport(req);
        assertFalse(res.isSuccess());
        assertTrue(res.getErrors().stream().anyMatch(e -> e.getField().equals("duplicate")));
    }

    @Test
    public void testBatchImport_StudentRole_Denied() {
        if (studentUser != null) {
            setAuthUser(studentUser);
            GradeBatchImportRequest req = GradeBatchImportRequest.builder()
                    .importType("IMPORT_MIDTERM")
                    .classId(testClass.getId())
                    .subjectId(testSubject.getId())
                    .semester(1)
                    .items(List.of(
                            GradeBatchImportItemDTO.builder()
                                    .studentId(testStudents.get(0).getId())
                                    .score(8.0)
                                    .build()
                    ))
                    .build();

            assertThrows(AccessDeniedException.class, () -> gradeService.batchImport(req));
        }
    }
}
