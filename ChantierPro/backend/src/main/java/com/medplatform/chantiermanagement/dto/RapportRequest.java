package com.medplatform.chantiermanagement.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class RapportRequest {

    @NotBlank(message = "Le contenu est obligatoire")
    private String contenu;

    private LocalDate dateRapport;

    @NotNull(message = "Le chantier est obligatoire")
    private Long chantierId;

    @NotNull(message = "L'auteur est obligatoire")
    private Long auteurId;
}
