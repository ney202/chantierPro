package com.medplatform.chantiermanagement.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class PhotoRequest {

    @NotBlank(message = "L'URL de la photo est obligatoire")
    private String urlPhoto;

    private LocalDate dateUpload;

    @NotNull(message = "Le rapport est obligatoire")
    private Long rapportId;
}
