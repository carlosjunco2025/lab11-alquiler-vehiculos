package com.tecsup.vehiculo.dto;

import com.tecsup.vehiculo.model.EstadoVehiculo;
import com.tecsup.vehiculo.model.Vehiculo;

import java.math.BigDecimal;

/**
 * Representación de un vehículo en las respuestas HTTP.
 */
public class VehiculoResponse {

    private Long id;
    private String placa;
    private String marca;
    private String modelo;
    private Integer anio;
    private BigDecimal tarifaDiaria;
    private EstadoVehiculo estado;

    public VehiculoResponse() {
    }

    public static VehiculoResponse from(Vehiculo vehiculo) {
        VehiculoResponse dto = new VehiculoResponse();
        dto.setId(vehiculo.getId());
        dto.setPlaca(vehiculo.getPlaca());
        dto.setMarca(vehiculo.getMarca());
        dto.setModelo(vehiculo.getModelo());
        dto.setAnio(vehiculo.getAnio());
        dto.setTarifaDiaria(vehiculo.getTarifaDiaria());
        dto.setEstado(vehiculo.getEstado());
        return dto;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

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
