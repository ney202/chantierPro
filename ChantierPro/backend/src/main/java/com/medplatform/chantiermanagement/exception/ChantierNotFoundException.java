package com.medplatform.chantiermanagement.exception;

public class ChantierNotFoundException extends RuntimeException {

    public ChantierNotFoundException(Long id) {
        super("Chantier non trouvé avec l'id : " + id);
    }
}
