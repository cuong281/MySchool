package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Integer> {

    // Tim user bang so dien thoai, chi lay user dang active
    Optional<User> findByPhoneNumberAndIsActiveTrue(String phoneNumber);

    Optional<User> findByUsername(String username);

    Optional<User> findByIdAndIsActiveTrue(Integer id);
}
