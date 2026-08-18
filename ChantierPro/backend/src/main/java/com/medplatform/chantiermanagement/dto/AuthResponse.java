package com.medplatform.chantiermanagement.dto;

import com.medplatform.chantiermanagement.enums.Role;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private Long id;
    private String nom;
    private String email;
    private Role role;
    private String token;
    private String message;
}
