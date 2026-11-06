package com.tecsup.alquiler.controller;

import com.tecsup.alquiler.dto.AlquilerRequest;
import com.tecsup.alquiler.dto.AlquilerResponse;
import com.tecsup.alquiler.services.AlquilerService;
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
 * API REST de alquileres.
 * GET    /api/alquileres
 * GET    /api/alquileres/{id}
 * GET    /api/alquileres/cliente/{idCliente}
 * POST   /api/alquileres                 -> 201
 * PUT    /api/alquileres/{id}
 * PATCH  /api/alquileres/{id}/finalizar
 * PATCH  /api/alquileres/{id}/cancelar
 * DELETE /api/alquileres/{id}            -> 204
 */
@RestController
@RequestMapping("/api/alquileres")
public class AlquilerController {

    private final AlquilerService alquilerService;

    public AlquilerController(AlquilerService alquilerService) {
        this.alquilerService = alquilerService;
    }

    @GetMapping
    public List<AlquilerResponse> listar() {
        return alquilerService.listar();
    }

    @GetMapping("/{id}")
    public AlquilerResponse obtener(@PathVariable Long id) {
        return alquilerService.obtener(id);
    }

    @GetMapping("/cliente/{idCliente}")
    public List<AlquilerResponse> listarPorCliente(@PathVariable Long idCliente) {
        return alquilerService.listarPorCliente(idCliente);
    }

    @PostMapping
    public ResponseEntity<AlquilerResponse> crear(@Valid @RequestBody AlquilerRequest request) {
        AlquilerResponse creado = alquilerService.crear(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(creado);
    }

    @PutMapping("/{id}")
    public AlquilerResponse actualizar(@PathVariable Long id, @Valid @RequestBody AlquilerRequest request) {
        return alquilerService.actualizar(id, request);
    }

    @PatchMapping("/{id}/finalizar")
    public AlquilerResponse finalizar(@PathVariable Long id) {
        return alquilerService.finalizar(id);
    }

    @PatchMapping("/{id}/cancelar")
    public AlquilerResponse cancelar(@PathVariable Long id) {
        return alquilerService.cancelar(id);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        alquilerService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
