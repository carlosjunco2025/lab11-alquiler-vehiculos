package com.tecsup.alquiler.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Datos de entrada para crear o actualizar un alquiler.
 * El importeEstimado NO se recibe: lo calcula el servicio.
 */
public class AlquilerRequest {

    @NotNull(message = "El idCliente es obligatorio")
    private Long idCliente;

    @NotNull(message = "El idVehiculo es obligatorio")
    private Long idVehiculo;

    @NotNull(message = "La fecha de inicio es obligatoria")
    private LocalDate fechaInicio;

    @NotNull(message = "La fecha de fin es obligatoria")
    private LocalDate fechaFin;

    // Opcional: si no se envía, el servicio usa la tarifa del vehículo.
    @DecimalMin(value = "0.00", message = "La tarifa diaria no puede ser negativa")
    @Digits(integer = 8, fraction = 2, message = "La tarifa diaria admite como máximo 8 enteros y 2 decimales")
    private BigDecimal tarifaDiaria;

    public Long getIdCliente() {
        return idCliente;
    }

    public void setIdCliente(Long idCliente) {
        this.idCliente = idCliente;
    }

    public Long getIdVehiculo() {
        return idVehiculo;
    }

    public void setIdVehiculo(Long idVehiculo) {
        this.idVehiculo = idVehiculo;
    }

    public LocalDate getFechaInicio() {
        return fechaInicio;
    }

    public void setFechaInicio(LocalDate fechaInicio) {
        this.fechaInicio = fechaInicio;
    }

    public LocalDate getFechaFin() {
        return fechaFin;
    }

    public void setFechaFin(LocalDate fechaFin) {
        this.fechaFin = fechaFin;
    }

    public BigDecimal getTarifaDiaria() {
        return tarifaDiaria;
    }

    public void setTarifaDiaria(BigDecimal tarifaDiaria) {
        this.tarifaDiaria = tarifaDiaria;
    }
}
