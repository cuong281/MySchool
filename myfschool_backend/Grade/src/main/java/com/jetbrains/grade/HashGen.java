package com.jetbrains.grade;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class HashGen {
    public static void main(String[] args) {
        System.out.println("========== HASH FOR 123456 ==========");
        System.out.println(new BCryptPasswordEncoder().encode("123456"));
        System.out.println("=====================================");
    }
}
