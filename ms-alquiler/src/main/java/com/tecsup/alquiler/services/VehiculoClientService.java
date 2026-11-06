package com.tecsup.alquiler.services;

import com.tecsup.alquiler.dto.VehiculoRemotoDTO;
import com.tecsup.alquiler.exception.ExternalServiceException;
import com.tecsup.alquiler.exception.ResourceNotFoundException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

import java.util.Map;

/**
 * Comunicación HTTP con ms-vehiculo: consulta de datos y cambio de estado.
 */
@Service
public class VehiculoClientService {

    private final RestClient restClient;
    private final String baseUrl;

    public VehiculoClientService(RestClient.Builder builder,
                                 @Value("${vehiculos.url}") String baseUrl) {
        this.restClient = builder.build();
        this.baseUrl = baseUrl.replaceAll("/+$", "");
    }

    public VehiculoRemotoDTO obtener(Long id) {
        try {
            VehiculoRemotoDTO vehiculo = restClient.get()
                    .uri(baseUrl + "/api/vehiculos/{id}", id)
                    .retrieve()
                    .body(VehiculoRemotoDTO.class);
            if (vehiculo == null) {
                throw new ExternalServiceException("El servicio de vehículos devolvió una respuesta vacía");
            }
            return vehiculo;
        } catch (RestClientResponseException ex) {
            if (ex.getStatusCode().value() == 404) {
                throw new ResourceNotFoundException("Vehículo no encontrado");
            }
            throw new ExternalServiceException(
                    "Error al consultar el servicio de vehículos (HTTP " + ex.getStatusCode().value() + ")");
        } catch (RestClientException ex) {
            throw new ExternalServiceException("El servicio de vehículos no está disponible");
        }
    }

    /**
     * Llama a PATCH /api/vehiculos/{id}/estado con el nuevo estado.
     */
    public void cambiarEstado(Long id, String estado) {
        try {
            restClient.patch()
                    .uri(baseUrl + "/api/vehiculos/{id}/estado", id)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("estado", estado))
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientResponseException ex) {
            if (ex.getStatusCode().value() == 404) {
                throw new ResourceNotFoundException("Vehículo no encontrado");
            }
            throw new ExternalServiceException(
                    "Error al actualizar el estado del vehículo (HTTP " + ex.getStatusCode().value() + ")");
        } catch (RestClientException ex) {
            throw new ExternalServiceException("El servicio de vehículos no está disponible");
        }
    }
}
