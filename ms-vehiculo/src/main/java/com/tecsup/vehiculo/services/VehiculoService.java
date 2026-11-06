package com.tecsup.vehiculo.services;

import com.tecsup.vehiculo.dto.VehiculoRequest;
import com.tecsup.vehiculo.dto.VehiculoResponse;
import com.tecsup.vehiculo.exception.BusinessException;
import com.tecsup.vehiculo.exception.ResourceNotFoundException;
import com.tecsup.vehiculo.model.EstadoVehiculo;
import com.tecsup.vehiculo.model.Vehiculo;
import com.tecsup.vehiculo.repository.VehiculoRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Reglas de negocio del microservicio de vehículos.
 */
@Service
public class VehiculoService {

    private final VehiculoRepository vehiculoRepository;

    public VehiculoService(VehiculoRepository vehiculoRepository) {
        this.vehiculoRepository = vehiculoRepository;
    }

    @Transactional(readOnly = true)
    public List<VehiculoResponse> listar() {
        return vehiculoRepository.findAll(Sort.by(Sort.Direction.ASC, "id"))
                .stream()
                .map(VehiculoResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public VehiculoResponse obtener(Long id) {
        return VehiculoResponse.from(buscar(id));
    }

    @Transactional
    public VehiculoResponse crear(VehiculoRequest request) {
        if (vehiculoRepository.existsByPlaca(request.getPlaca())) {
            throw new BusinessException("La placa " + request.getPlaca() + " ya está registrada");
        }

        Vehiculo vehiculo = new Vehiculo();
        aplicarDatos(vehiculo, request);
        if (vehiculo.getEstado() == null) {
            vehiculo.setEstado(EstadoVehiculo.DISPONIBLE);
        }
        return VehiculoResponse.from(vehiculoRepository.save(vehiculo));
    }

    @Transactional
    public VehiculoResponse actualizar(Long id, VehiculoRequest request) {
        Vehiculo vehiculo = buscar(id);

        if (vehiculoRepository.existsByPlacaAndIdNot(request.getPlaca(), id)) {
            throw new BusinessException("La placa " + request.getPlaca() + " ya está registrada por otro vehículo");
        }

        aplicarDatos(vehiculo, request);
        if (vehiculo.getEstado() == null) {
            vehiculo.setEstado(EstadoVehiculo.DISPONIBLE);
        }
        return VehiculoResponse.from(vehiculoRepository.save(vehiculo));
    }

    /**
     * Cambia solo el estado. Lo usa ms-alquiler para marcar ALQUILADO
     * al crear un alquiler y DISPONIBLE al finalizarlo o cancelarlo.
     */
    @Transactional
    public VehiculoResponse cambiarEstado(Long id, EstadoVehiculo estado) {
        Vehiculo vehiculo = buscar(id);
        vehiculo.setEstado(estado);
        return VehiculoResponse.from(vehiculoRepository.save(vehiculo));
    }

    @Transactional
    public void eliminar(Long id) {
        vehiculoRepository.delete(buscar(id));
    }

    private Vehiculo buscar(Long id) {
        return vehiculoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Vehículo no encontrado con id " + id));
    }

    private void aplicarDatos(Vehiculo vehiculo, VehiculoRequest request) {
        vehiculo.setPlaca(request.getPlaca());
        vehiculo.setMarca(request.getMarca());
        vehiculo.setModelo(request.getModelo());
        vehiculo.setAnio(request.getAnio());
        vehiculo.setTarifaDiaria(request.getTarifaDiaria());
        if (request.getEstado() != null) {
            vehiculo.setEstado(request.getEstado());
        }
    }
}
