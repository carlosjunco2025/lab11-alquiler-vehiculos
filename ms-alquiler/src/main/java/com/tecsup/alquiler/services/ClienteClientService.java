package com.tecsup.alquiler.services;

import com.tecsup.alquiler.dto.ClienteRemotoDTO;
import com.tecsup.alquiler.exception.ExternalServiceException;
import com.tecsup.alquiler.exception.ResourceNotFoundException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

/**
 * Comunicación HTTP con ms-cliente.
 * Una respuesta 404 se traduce a ResourceNotFoundException (404 local)
 * y un fallo de conexión a ExternalServiceException (503).
 */
@Service
public class ClienteClientService {

    private final RestClient restClient;
    private final String baseUrl;

    public ClienteClientService(RestClient.Builder builder,
                                @Value("${clientes.url}") String baseUrl) {
        this.restClient = builder.build();
        this.baseUrl = baseUrl.replaceAll("/+$", "");
    }

    public ClienteRemotoDTO obtener(Long id) {
        try {
            ClienteRemotoDTO cliente = restClient.get()
                    .uri(baseUrl + "/api/clientes/{id}", id)
                    .retrieve()
                    .body(ClienteRemotoDTO.class);
            if (cliente == null) {
                throw new ExternalServiceException("El servicio de clientes devolvió una respuesta vacía");
            }
            return cliente;
        } catch (RestClientResponseException ex) {
            if (ex.getStatusCode().value() == 404) {
                throw new ResourceNotFoundException("Cliente no encontrado");
            }
            throw new ExternalServiceException(
                    "Error al consultar el servicio de clientes (HTTP " + ex.getStatusCode().value() + ")");
        } catch (RestClientException ex) {
            throw new ExternalServiceException("El servicio de clientes no está disponible");
        }
    }
}
