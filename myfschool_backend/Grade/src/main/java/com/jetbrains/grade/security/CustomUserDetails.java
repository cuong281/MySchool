package com.jetbrains.grade.security;

import com.jetbrains.grade.model.User;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

@Getter
public class CustomUserDetails implements UserDetails {

    private final Integer userId;
    private final String username;
    private final String password;
    private final String phoneNumber;
    private final String email;
    private final boolean active;
    private final List<GrantedAuthority> authorities;
    private final Integer studentId;
    private final Integer teacherId;

    public CustomUserDetails(User user) {
        this.userId = user.getId();
        this.username = user.getUsername();
        this.password = user.getPasswordHash();
        this.phoneNumber = user.getPhoneNumber();
        this.email = user.getEmail();
        this.active = Boolean.TRUE.equals(user.getIsActive());

        this.authorities = user.getRoles().stream()
                .map(r -> {
                    String name = r.getRoleName() != null ? r.getRoleName().trim().toUpperCase() : "STUDENT";
                    return new SimpleGrantedAuthority(name.startsWith("ROLE_") ? name : "ROLE_" + name);
                })
                .collect(Collectors.toList());

        this.studentId = user.getStudent() != null ? user.getStudent().getId() : null;
        this.teacherId = user.getTeacher() != null ? user.getTeacher().getId() : null;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return active;
    }
}
