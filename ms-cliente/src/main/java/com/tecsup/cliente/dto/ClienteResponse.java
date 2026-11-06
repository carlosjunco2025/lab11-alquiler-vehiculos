package com.tecsup.cliente.dto;

import com.tecsup.cliente.model.Cliente;
import com.tecsup.cliente.model.EstadoCliente;

/**
 * Representación de un cliente en las respuestas HTTP.
 */
public class ClienteResponse {

    private Long id;
    private String nombres;
    private String apellidos;
    private String documento;
    private String correo;
    private String telefono;
    private EstadoCliente estado;

    public ClienteResponse() {
    }

    public static ClienteResponse from(Cliente cliente) {
        ClienteResponse dto = new ClienteResponse();
        dto.setId(cliente.getId());
        dto.setNombres(cliente.getNombres());
        dto.setApellidos(cliente.getApellidos());
        dto.setDocumento(cliente.getDocumento());
        dto.setCorreo(cliente.getCorreo());
        dto.setTelefono(cliente.getTelefono());
        dto.setEstado(cliente.getEstado());
        return dto;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNombres() {
        return nombres;
    }

    public void setNombres(String nombres) {
        this.nombres = nombres;
    }

    public String getApellidos() {
        return apellidos;
    }

    public void setApellidos(String apellidos) {
        this.apellidos = apellidos;
    }

    public String getDocumento() {
        return documento;
    }

    public void setDocumento(String documento) {
        this.documento = documento;
    }

    public String getCorreo() {
        return correo;
    }

    public void setCorreo(String correo) {
        this.correo = correo;
    }

    public String getTelefono() {
        return telefono;
    }

    public void setTelefono(String telefono) {
        this.telefono = telefono;
    }

    public EstadoCliente getEstado() {
        return estado;
    }

    public void setEstado(EstadoCliente estado) {
        this.estado = estado;
    }
}
