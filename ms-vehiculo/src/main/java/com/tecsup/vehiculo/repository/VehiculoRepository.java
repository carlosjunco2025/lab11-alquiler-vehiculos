package com.tecsup.vehiculo.repository;

import com.tecsup.vehiculo.model.Vehiculo;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repositorio JPA para la tabla vehiculo.
 */
public interface VehiculoRepository extends JpaRepository<Vehiculo, Long> {

    boolean existsByPlaca(String placa);

    boolean existsByPlacaAndIdNot(String placa, Long id);
}
