package com.tecsup.vehiculo.dto;

import jakarta.validation.constraints.NotNull;

import com.tecsup.vehiculo.model.EstadoVehiculo;

/**
 * Cuerpo del endpoint PATCH /api/vehiculos/{id}/estado.
 */
public class EstadoVehiculoRequest {

    @NotNull(message = "El estado es obligatorio")
    private EstadoVehiculo estado;

    public EstadoVehiculo getEstado() {
        return estado;
    }

    public void setEstado(EstadoVehiculo estado) {
        this.estado = estado;
    }
}
