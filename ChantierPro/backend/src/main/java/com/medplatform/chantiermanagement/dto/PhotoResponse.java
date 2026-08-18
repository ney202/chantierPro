package com.medplatform.chantiermanagement.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class PhotoResponse {

    private Long id;
    private String urlPhoto;
    private LocalDate dateUpload;
    private Long rapportId;
}
