package com.medplatform.chantiermanagement.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class AffectationRequest {

    @NotNull(message = "L'utilisateur est obligatoire")
    private Long utilisateurId;

    @NotNull(message = "Le chantier est obligatoire")
    private Long chantierId;

    @NotNull(message = "La date d'affectation est obligatoire")
    private LocalDate dateAffectation;
}
