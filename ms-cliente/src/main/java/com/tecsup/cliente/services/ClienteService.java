package com.tecsup.cliente.services;

import com.tecsup.cliente.dto.ClienteRequest;
import com.tecsup.cliente.dto.ClienteResponse;
import com.tecsup.cliente.exception.BusinessException;
import com.tecsup.cliente.exception.ResourceNotFoundException;
import com.tecsup.cliente.model.Cliente;
import com.tecsup.cliente.model.EstadoCliente;
import com.tecsup.cliente.repository.ClienteRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Reglas de negocio del microservicio de clientes.
 */
@Service
public class ClienteService {

    private final ClienteRepository clienteRepository;

    public ClienteService(ClienteRepository clienteRepository) {
        this.clienteRepository = clienteRepository;
    }

    @Transactional(readOnly = true)
    public List<ClienteResponse> listar() {
        return clienteRepository.findAll(Sort.by(Sort.Direction.ASC, "id"))
                .stream()
                .map(ClienteResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public ClienteResponse obtener(Long id) {
        return ClienteResponse.from(buscar(id));
    }

    @Transactional
    public ClienteResponse crear(ClienteRequest request) {
        // El DNI es único: se valida antes de guardar para devolver un 409 claro.
        if (clienteRepository.existsByDocumento(request.getDocumento())) {
            throw new BusinessException("El documento " + request.getDocumento() + " ya está registrado");
        }

        Cliente cliente = new Cliente();
        aplicarDatos(cliente, request);
        if (cliente.getEstado() == null) {
            cliente.setEstado(EstadoCliente.ACTIVO);
        }
        return ClienteResponse.from(clienteRepository.save(cliente));
    }

    @Transactional
    public ClienteResponse actualizar(Long id, ClienteRequest request) {
        Cliente cliente = buscar(id);

        if (clienteRepository.existsByDocumentoAndIdNot(request.getDocumento(), id)) {
            throw new BusinessException("El documento " + request.getDocumento() + " ya está registrado por otro cliente");
        }

        aplicarDatos(cliente, request);
        if (cliente.getEstado() == null) {
            cliente.setEstado(EstadoCliente.ACTIVO);
        }
        return ClienteResponse.from(clienteRepository.save(cliente));
    }

    @Transactional
    public void eliminar(Long id) {
        clienteRepository.delete(buscar(id));
    }

    private Cliente buscar(Long id) {
        return clienteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Cliente no encontrado con id " + id));
    }

    private void aplicarDatos(Cliente cliente, ClienteRequest request) {
        cliente.setNombres(request.getNombres());
        cliente.setApellidos(request.getApellidos());
        cliente.setDocumento(request.getDocumento());
        cliente.setCorreo(request.getCorreo());
        cliente.setTelefono(request.getTelefono());
        if (request.getEstado() != null) {
            cliente.setEstado(request.getEstado());
        }
    }
}
