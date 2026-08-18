package com.medplatform.chantiermanagement.exception;

public class TacheNotFoundException extends RuntimeException {

    public TacheNotFoundException(Long id) {
        super("Tache non trouvée avec l'id : " + id);
    }
}
