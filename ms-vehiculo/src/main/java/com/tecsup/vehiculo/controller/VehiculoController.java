package com.tecsup.vehiculo.controller;

import com.tecsup.vehiculo.dto.EstadoVehiculoRequest;
import com.tecsup.vehiculo.dto.VehiculoRequest;
import com.tecsup.vehiculo.dto.VehiculoResponse;
import com.tecsup.vehiculo.services.VehiculoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * API REST de vehículos.
 * GET    /api/vehiculos
 * GET    /api/vehiculos/{id}
 * POST   /api/vehiculos                 -> 201
 * PUT    /api/vehiculos/{id}
 * PATCH  /api/vehiculos/{id}/estado
 * DELETE /api/vehiculos/{id}            -> 204
 */
@RestController
@RequestMapping("/api/vehiculos")
public class VehiculoController {

    private final VehiculoService vehiculoService;

    public VehiculoController(VehiculoService vehiculoService) {
        this.vehiculoService = vehiculoService;
    }

    @GetMapping
    public List<VehiculoResponse> listar() {
        return vehiculoService.listar();
    }

    @GetMapping("/{id}")
    public VehiculoResponse obtener(@PathVariable Long id) {
        return vehiculoService.obtener(id);
    }

    @PostMapping
    public ResponseEntity<VehiculoResponse> crear(@Valid @RequestBody VehiculoRequest request) {
        VehiculoResponse creado = vehiculoService.crear(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(creado);
    }

    @PutMapping("/{id}")
    public VehiculoResponse actualizar(@PathVariable Long id, @Valid @RequestBody VehiculoRequest request) {
        return vehiculoService.actualizar(id, request);
    }

    @PatchMapping("/{id}/estado")
    public VehiculoResponse cambiarEstado(@PathVariable Long id,
                                          @Valid @RequestBody EstadoVehiculoRequest request) {
        return vehiculoService.cambiarEstado(id, request.getEstado());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        vehiculoService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
