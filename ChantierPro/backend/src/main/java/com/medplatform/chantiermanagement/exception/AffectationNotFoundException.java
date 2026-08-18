package com.medplatform.chantiermanagement.exception;

public class AffectationNotFoundException extends RuntimeException {

    public AffectationNotFoundException(Long id) {
        super("Affectation non trouvée avec l'id : " + id);
    }
}
