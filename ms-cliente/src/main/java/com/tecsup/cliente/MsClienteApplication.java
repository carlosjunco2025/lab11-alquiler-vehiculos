package com.tecsup.cliente;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Punto de entrada del microservicio de clientes.
 * Expone el CRUD en http://localhost:8081/api/clientes
 */
@SpringBootApplication
public class MsClienteApplication {

    public static void main(String[] args) {
        SpringApplication.run(MsClienteApplication.class, args);
    }
}
