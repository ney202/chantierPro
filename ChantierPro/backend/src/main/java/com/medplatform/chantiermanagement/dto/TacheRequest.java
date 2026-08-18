package com.medplatform.chantiermanagement.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class TacheRequest {

    @NotBlank(message = "Le titre est obligatoire")
    private String titre;

    private String description;

    private LocalDate dateDebut;

    private LocalDate dateFin;

    private String priorite;

    private String categorie;

    @NotNull(message = "Le chantier est obligatoire")
    private Long chantierId;
}