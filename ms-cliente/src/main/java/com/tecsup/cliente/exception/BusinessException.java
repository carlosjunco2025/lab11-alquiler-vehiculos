package com.tecsup.cliente.exception;

/**
 * Conflicto de negocio, por ejemplo un DNI duplicado. Se traduce a 409.
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
