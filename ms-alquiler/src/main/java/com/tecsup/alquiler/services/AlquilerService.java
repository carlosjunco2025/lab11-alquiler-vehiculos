package com.tecsup.alquiler.services;

import com.tecsup.alquiler.dto.AlquilerRequest;
import com.tecsup.alquiler.dto.AlquilerResponse;
import com.tecsup.alquiler.dto.VehiculoRemotoDTO;
import com.tecsup.alquiler.exception.BadRequestException;
import com.tecsup.alquiler.exception.BusinessException;
import com.tecsup.alquiler.exception.ResourceNotFoundException;
import com.tecsup.alquiler.model.Alquiler;
import com.tecsup.alquiler.model.EstadoAlquiler;
import com.tecsup.alquiler.repository.AlquilerRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Reglas de negocio del alquiler:
 * - Valida fechas y existencia de cliente/vehículo.
 * - Calcula el importe estimado (nunca lo recibe del cliente).
 * - Sincroniza el estado del vehículo llamando a ms-vehiculo.
 */
@Service
public class AlquilerService {

    private static final String DISPONIBLE = "DISPONIBLE";
    private static final String ALQUILADO = "ALQUILADO";

    private final AlquilerRepository alquilerRepository;
    private final ClienteClientService clienteClientService;
    private final VehiculoClientService vehiculoClientService;

    public AlquilerService(AlquilerRepository alquilerRepository,
                           ClienteClientService clienteClientService,
                           VehiculoClientService vehiculoClientService) {
        this.alquilerRepository = alquilerRepository;
        this.clienteClientService = clienteClientService;
        this.vehiculoClientService = vehiculoClientService;
    }

    @Transactional(readOnly = true)
    public List<AlquilerResponse> listar() {
        return alquilerRepository.findAll(Sort.by(Sort.Direction.ASC, "id"))
                .stream()
                .map(AlquilerResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AlquilerResponse> listarPorCliente(Long idCliente) {
        return alquilerRepository.findByIdClienteOrderByIdAsc(idCliente)
                .stream()
                .map(AlquilerResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public AlquilerResponse obtener(Long id) {
        return AlquilerResponse.from(buscar(id));
    }

    @Transactional
    public AlquilerResponse crear(AlquilerRequest request) {
        validarFechas(request);

        // 1. El cliente debe existir en ms-cliente.
        clienteClientService.obtener(request.getIdCliente());

        // 2. El vehículo debe existir y estar DISPONIBLE en ms-vehiculo.
        VehiculoRemotoDTO vehiculo = vehiculoClientService.obtener(request.getIdVehiculo());
        validarDisponibilidad(vehiculo);

        // 3. La tarifa puede venir en el DTO; si no, se toma del vehículo.
        BigDecimal tarifa = resolverTarifa(request, vehiculo);

        Alquiler alquiler = new Alquiler();
        alquiler.setIdCliente(request.getIdCliente());
        alquiler.setIdVehiculo(request.getIdVehiculo());
        alquiler.setFechaInicio(request.getFechaInicio());
        alquiler.setFechaFin(request.getFechaFin());
        alquiler.setTarifaDiaria(tarifa);
        alquiler.setImporteEstimado(calcularImporte(request.getFechaInicio(), request.getFechaFin(), tarifa));
        alquiler.setEstado(EstadoAlquiler.ACTIVO);
        alquiler = alquilerRepository.save(alquiler);

        // 4. Se marca el vehículo como ALQUILADO en su propio microservicio.
        vehiculoClientService.cambiarEstado(alquiler.getIdVehiculo(), ALQUILADO);

        return AlquilerResponse.from(alquiler);
    }

    @Transactional
    public AlquilerResponse actualizar(Long id, AlquilerRequest request) {
        Alquiler alquiler = buscar(id);

        if (alquiler.getEstado() != EstadoAlquiler.ACTIVO) {
            throw new BusinessException("Solo se puede actualizar un alquiler en estado ACTIVO");
        }

        validarFechas(request);
        clienteClientService.obtener(request.getIdCliente());

        VehiculoRemotoDTO vehiculo = vehiculoClientService.obtener(request.getIdVehiculo());
        boolean cambiaVehiculo = !alquiler.getIdVehiculo().equals(request.getIdVehiculo());
        if (cambiaVehiculo) {
            validarDisponibilidad(vehiculo);
        }

        BigDecimal tarifa = resolverTarifa(request, vehiculo);
        Long idVehiculoAnterior = alquiler.getIdVehiculo();

        alquiler.setIdCliente(request.getIdCliente());
        alquiler.setIdVehiculo(request.getIdVehiculo());
        alquiler.setFechaInicio(request.getFechaInicio());
        alquiler.setFechaFin(request.getFechaFin());
        alquiler.setTarifaDiaria(tarifa);
        alquiler.setImporteEstimado(calcularImporte(request.getFechaInicio(), request.getFechaFin(), tarifa));
        alquiler = alquilerRepository.save(alquiler);

        if (cambiaVehiculo) {
            vehiculoClientService.cambiarEstado(idVehiculoAnterior, DISPONIBLE);
            vehiculoClientService.cambiarEstado(alquiler.getIdVehiculo(), ALQUILADO);
        }

        return AlquilerResponse.from(alquiler);
    }

    @Transactional
    public AlquilerResponse finalizar(Long id) {
        Alquiler alquiler = buscar(id);
        if (alquiler.getEstado() != EstadoAlquiler.ACTIVO) {
            throw new BusinessException("Solo se puede finalizar un alquiler en estado ACTIVO");
        }

        vehiculoClientService.cambiarEstado(alquiler.getIdVehiculo(), DISPONIBLE);
        alquiler.setEstado(EstadoAlquiler.FINALIZADO);
        return AlquilerResponse.from(alquilerRepository.save(alquiler));
    }

    @Transactional
    public AlquilerResponse cancelar(Long id) {
        Alquiler alquiler = buscar(id);
        if (alquiler.getEstado() != EstadoAlquiler.ACTIVO) {
            throw new BusinessException("Solo se puede cancelar un alquiler en estado ACTIVO");
        }

        vehiculoClientService.cambiarEstado(alquiler.getIdVehiculo(), DISPONIBLE);
        alquiler.setEstado(EstadoAlquiler.CANCELADO);
        return AlquilerResponse.from(alquilerRepository.save(alquiler));
    }

    @Transactional
    public void eliminar(Long id) {
        Alquiler alquiler = buscar(id);
        // Si seguía activo, se libera el vehículo antes de borrar el alquiler.
        if (alquiler.getEstado() == EstadoAlquiler.ACTIVO) {
            vehiculoClientService.cambiarEstado(alquiler.getIdVehiculo(), DISPONIBLE);
        }
        alquilerRepository.delete(alquiler);
    }

    private Alquiler buscar(Long id) {
        return alquilerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Alquiler no encontrado con id " + id));
    }

    private void validarFechas(AlquilerRequest request) {
        if (request.getFechaInicio().isBefore(LocalDate.now())) {
            throw new BadRequestException("La fecha de inicio no puede estar en el pasado");
        }
        if (!request.getFechaFin().isAfter(request.getFechaInicio())) {
            throw new BadRequestException("La fecha de fin debe ser posterior a la fecha de inicio");
        }
    }

    private void validarDisponibilidad(VehiculoRemotoDTO vehiculo) {
        if (!DISPONIBLE.equals(vehiculo.getEstado())) {
            throw new BusinessException("El vehículo no está disponible para alquiler (estado: "
                    + vehiculo.getEstado() + ")");
        }
    }

    private BigDecimal resolverTarifa(AlquilerRequest request, VehiculoRemotoDTO vehiculo) {
        if (request.getTarifaDiaria() != null) {
            return request.getTarifaDiaria();
        }
        if (vehiculo.getTarifaDiaria() == null) {
            throw new BadRequestException("No se pudo determinar la tarifa diaria del vehículo");
        }
        return vehiculo.getTarifaDiaria();
    }

    /**
     * Días calendario entre las fechas (mínimo 1) por la tarifa diaria.
     */
    private BigDecimal calcularImporte(LocalDate inicio, LocalDate fin, BigDecimal tarifa) {
        long dias = ChronoUnit.DAYS.between(inicio, fin);
        if (dias < 1) {
            dias = 1;
        }
        return tarifa.multiply(BigDecimal.valueOf(dias)).setScale(2, RoundingMode.HALF_UP);
    }
}
