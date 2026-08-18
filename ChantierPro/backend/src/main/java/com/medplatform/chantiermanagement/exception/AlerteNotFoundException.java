package com.medplatform.chantiermanagement.exception;

public class AlerteNotFoundException extends RuntimeException {

    public AlerteNotFoundException(Long id) {
        super("Alerte non trouvée avec l'id : " + id);
    }
}
