package com.tecsup.alquiler.repository;

import com.tecsup.alquiler.model.Alquiler;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Repositorio JPA para la tabla alquiler.
 */
public interface AlquilerRepository extends JpaRepository<Alquiler, Long> {

    List<Alquiler> findByIdClienteOrderByIdAsc(Long idCliente);
}
