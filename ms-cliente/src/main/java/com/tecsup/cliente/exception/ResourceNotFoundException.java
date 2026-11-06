package com.tecsup.cliente.exception;

/**
 * Se lanza cuando un recurso solicitado no existe. El handler la convierte en 404.
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}
