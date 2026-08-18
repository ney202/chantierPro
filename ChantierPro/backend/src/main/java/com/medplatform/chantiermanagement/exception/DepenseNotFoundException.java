package com.medplatform.chantiermanagement.exception;

public class DepenseNotFoundException extends RuntimeException {

    public DepenseNotFoundException(Long id) {
        super("Dépense non trouvée avec l'id : " + id);
    }
}
