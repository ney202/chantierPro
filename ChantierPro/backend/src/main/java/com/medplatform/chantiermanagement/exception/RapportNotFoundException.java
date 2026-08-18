package com.medplatform.chantiermanagement.exception;

public class RapportNotFoundException extends RuntimeException {

    public RapportNotFoundException(Long id) {
        super("Rapport non trouvé avec l'id : " + id);
    }
}
