package com.medplatform.chantiermanagement.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class AffectationResponse {

    private Long id;
    private Long utilisateurId;
    private Long chantierId;
    private LocalDate dateAffectation;
}
