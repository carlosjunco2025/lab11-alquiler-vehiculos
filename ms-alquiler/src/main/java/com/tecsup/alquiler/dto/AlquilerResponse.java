package com.tecsup.alquiler.dto;

import com.tecsup.alquiler.model.Alquiler;
import com.tecsup.alquiler.model.EstadoAlquiler;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Representación de un alquiler en las respuestas HTTP.
 */
public class AlquilerResponse {

    private Long id;
    private Long idCliente;
    private Long idVehiculo;
    private LocalDate fechaInicio;
    private LocalDate fechaFin;
    private BigDecimal tarifaDiaria;
    private BigDecimal importeEstimado;
    private EstadoAlquiler estado;

    public AlquilerResponse() {
    }

    public static AlquilerResponse from(Alquiler alquiler) {
        AlquilerResponse dto = new AlquilerResponse();
        dto.setId(alquiler.getId());
        dto.setIdCliente(alquiler.getIdCliente());
        dto.setIdVehiculo(alquiler.getIdVehiculo());
        dto.setFechaInicio(alquiler.getFechaInicio());
        dto.setFechaFin(alquiler.getFechaFin());
        dto.setTarifaDiaria(alquiler.getTarifaDiaria());
        dto.setImporteEstimado(alquiler.getImporteEstimado());
        dto.setEstado(alquiler.getEstado());
        return dto;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

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

    public BigDecimal getImporteEstimado() {
        return importeEstimado;
    }

    public void setImporteEstimado(BigDecimal importeEstimado) {
        this.importeEstimado = importeEstimado;
    }

    public EstadoAlquiler getEstado() {
        return estado;
    }

    public void setEstado(EstadoAlquiler estado) {
        this.estado = estado;
    }
}
