package com.tecsup.alquiler.exception;

/**
 * El microservicio externo no responde o devuelve un error no esperado.
 * El handler la convierte en 503 Service Unavailable.
 */
public class ExternalServiceException extends RuntimeException {

    public ExternalServiceException(String message) {
        super(message);
    }
}
