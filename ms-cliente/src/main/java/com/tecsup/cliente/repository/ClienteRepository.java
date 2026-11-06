package com.tecsup.cliente.repository;

import com.tecsup.cliente.model.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repositorio JPA: Spring genera la implementación de los métodos CRUD.
 * Los métodos existsBy... se usan para validar el DNI único antes de guardar.
 */
public interface ClienteRepository extends JpaRepository<Cliente, Long> {

    boolean existsByDocumento(String documento);

    boolean existsByDocumentoAndIdNot(String documento, Long id);
}
