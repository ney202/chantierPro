package com.medplatform.chantiermanagement.exception;

public class PhotoNotFoundException extends RuntimeException {

    public PhotoNotFoundException(Long id) {
        super("Photo non trouvée avec l'id : " + id);
    }
}
