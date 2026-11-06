package com.tecsup.alquiler.exception;

/**
 * Recurso inexistente, propio o detectado en otro microservicio. Se traduce a 404.
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}
