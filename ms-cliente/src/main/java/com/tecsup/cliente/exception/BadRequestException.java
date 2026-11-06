package com.tecsup.cliente.exception;

/**
 * Datos inválidos que no dependen solo de las anotaciones de validación. Se traduce a 400.
 */
public class BadRequestException extends RuntimeException {

    public BadRequestException(String message) {
        super(message);
    }
}
