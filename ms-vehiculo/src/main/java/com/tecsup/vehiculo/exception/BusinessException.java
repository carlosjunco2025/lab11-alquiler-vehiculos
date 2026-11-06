package com.tecsup.vehiculo.exception;

/**
 * Conflicto de negocio, por ejemplo una placa duplicada. Se traduce a 409.
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
