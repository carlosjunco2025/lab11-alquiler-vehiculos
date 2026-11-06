package com.tecsup.alquiler;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestClient;

/**
 * Punto de entrada del microservicio de alquileres.
 * Expone el CRUD en http://localhost:8083/api/alquileres
 */
@SpringBootApplication
public class MsAlquilerApplication {

    public static void main(String[] args) {
        SpringApplication.run(MsAlquilerApplication.class, args);
    }

    /**
     * Cliente HTTP moderno de Spring para comunicarse con ms-cliente y ms-vehiculo.
     * Cada servicio de cliente remoto construye su propio RestClient con este builder.
     */
    @Bean
    public RestClient.Builder restClientBuilder() {
        return RestClient.builder();
    }
}
