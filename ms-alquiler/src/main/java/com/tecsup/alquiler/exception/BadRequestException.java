package com.tecsup.alquiler.exception;

/**
 * Datos inválidos, por ejemplo fechas incoherentes. Se traduce a 400.
 */
public class BadRequestException extends RuntimeException {

    public BadRequestException(String message) {
        super(message);
    }
}
