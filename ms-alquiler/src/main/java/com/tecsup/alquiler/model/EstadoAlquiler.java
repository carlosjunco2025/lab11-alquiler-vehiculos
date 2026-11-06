package com.tecsup.alquiler.model;

/**
 * Estados posibles de un alquiler. Se persiste como texto (VARCHAR).
 */
public enum EstadoAlquiler {
    ACTIVO,
    FINALIZADO,
    CANCELADO
}
