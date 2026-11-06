package com.tecsup.alquiler.exception;

/**
 * Conflicto de negocio (vehículo no disponible, alquiler ya cerrado...). Se traduce a 409.
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
