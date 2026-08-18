package com.medplatform.chantiermanagement.dto;

import com.medplatform.chantiermanagement.enums.Role;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UtilisateurResponse {

    private Long id;
    private String nom;
    private String email;
    private String telephone;
    private Role role;
}
