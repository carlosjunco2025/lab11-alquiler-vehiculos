package com.tecsup.vehiculo.dto;

import com.tecsup.vehiculo.model.EstadoVehiculo;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

/**
 * Datos de entrada para crear o actualizar un vehículo.
 */
public class VehiculoRequest {

    @NotBlank(message = "La placa es obligatoria")
    @Size(max = 10, message = "La placa no puede superar los 10 caracteres")
    private String placa;

    @NotBlank(message = "La marca es obligatoria")
    @Size(max = 50, message = "La marca no puede superar los 50 caracteres")
    private String marca;

    @NotBlank(message = "El modelo es obligatorio")
    @Size(max = 50, message = "El modelo no puede superar los 50 caracteres")
    private String modelo;

    @NotNull(message = "El año es obligatorio")
    @Min(value = 1900, message = "El año debe ser mayor o igual a 1900")
    @Max(value = 2100, message = "El año debe ser menor o igual a 2100")
    private Integer anio;

    @NotNull(message = "La tarifa diaria es obligatoria")
    @DecimalMin(value = "0.00", message = "La tarifa diaria no puede ser negativa")
    @Digits(integer = 8, fraction = 2, message = "La tarifa diaria admite como máximo 8 enteros y 2 decimales")
    private BigDecimal tarifaDiaria;

    // Opcional: al crear, si no se envía, el servicio asigna DISPONIBLE.
    private EstadoVehiculo estado;

    public String getPlaca() {
        return placa;
    }

    public void setPlaca(String placa) {
        this.placa = placa;
    }

    public String getMarca() {
        return marca;
    }

    public void setMarca(String marca) {
        this.marca = marca;
    }

    public String getModelo() {
        return modelo;
    }

    public void setModelo(String modelo) {
        this.modelo = modelo;
    }

    public Integer getAnio() {
        return anio;
    }

    public void setAnio(Integer anio) {
        this.anio = anio;
    }

    public BigDecimal getTarifaDiaria() {
        return tarifaDiaria;
    }

    public void setTarifaDiaria(BigDecimal tarifaDiaria) {
        this.tarifaDiaria = tarifaDiaria;
    }

    public EstadoVehiculo getEstado() {
        return estado;
    }

    public void setEstado(EstadoVehiculo estado) {
        this.estado = estado;
    }
}
