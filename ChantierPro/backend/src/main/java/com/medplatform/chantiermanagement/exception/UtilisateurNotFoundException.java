package com.medplatform.chantiermanagement.exception;

public class UtilisateurNotFoundException extends RuntimeException {

    public UtilisateurNotFoundException(Long id) {
        super("Utilisateur non trouvé avec l'id : " + id);
    }
}
