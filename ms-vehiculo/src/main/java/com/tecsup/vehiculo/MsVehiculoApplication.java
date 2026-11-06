package com.tecsup.vehiculo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Punto de entrada del microservicio de vehículos.
 * Expone el CRUD en http://localhost:8082/api/vehiculos
 */
@SpringBootApplication
public class MsVehiculoApplication {

    public static void main(String[] args) {
        SpringApplication.run(MsVehiculoApplication.class, args);
    }
}
