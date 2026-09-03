package com.jetbrains.grade;

import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class HashTest {
    @Test
    public void generateHash() {
        System.out.println("========== HASH FOR 123456 ==========");
        System.out.println(new BCryptPasswordEncoder().encode("123456"));
        System.out.println("=====================================");
    }
}
