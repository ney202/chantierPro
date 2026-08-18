package com.medplatform.chantiermanagement.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AlerteResponse {

    private Long id;
    private String message;
    private LocalDateTime dateCreation;
    private String statut;
    private Boolean lu;
    private Long chantierId;
}