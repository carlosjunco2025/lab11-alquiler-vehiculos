'use strict';

/* =====================================================================
   Configuración de las APIs.
   El frontend se sirve desde ms-alquiler (8083) y usa el mismo host
   para comunicarse con los otros dos microservicios.
   ===================================================================== */
const HOST = window.location.hostname || 'localhost';
const API = {
  clientes: `http://${HOST}:8081`,
  vehiculos: `http://${HOST}:8082`,
  alquileres: `http://${HOST}:8083`
};

const state = {
  clientes: [],
  vehiculos: [],
  alquileres: [],
  health: { clientes: null, vehiculos: null, alquileres: null }
};

const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

const VIEW_META = {
  dashboard: {
    title: 'Panel general',
    subtitle: 'Resumen de clientes, vehículos y alquileres.'
  },
  clientes: {
    title: 'Clientes',
    subtitle: 'Datos personales y estado de los clientes registrados.'
  },
  vehiculos: {
    title: 'Vehículos',
    subtitle: 'Flota, tarifas diarias y disponibilidad.'
  },
  alquileres: {
    title: 'Alquileres',
    subtitle: 'Contratos, importes calculados y estados.'
  }
};

const STATUS_CLASS = {
  ACTIVO: 'badge-success',
  DISPONIBLE: 'badge-success',
  FINALIZADO: 'badge-info',
  ALQUILADO: 'badge-warning',
  MANTENIMIENTO: 'badge-danger',
  INACTIVO: 'badge-neutral',
  CANCELADO: 'badge-neutral'
};

/* ============================= UTILIDADES ============================= */

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function money(value) {
  const number = Number(value ?? 0);
  return `S/ ${number.toLocaleString('es-PE', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })}`;
}

function formatDate(iso) {
  if (!iso) return '—';
  const [year, month, day] = String(iso).split('-').map(Number);
  if (!year || !month || !day) return iso;
  return new Date(year, month - 1, day).toLocaleDateString('es-PE', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  });
}

function toIsoDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function daysBetween(start, end) {
  if (!start || !end) return null;
  const [y1, m1, d1] = start.split('-').map(Number);
  const [y2, m2, d2] = end.split('-').map(Number);
  const first = Date.UTC(y1, m1 - 1, d1);
  const second = Date.UTC(y2, m2 - 1, d2);
  return Math.round((second - first) / 86400000);
}

function initials(name) {
  return String(name || '?')
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map(part => part[0] || '')
    .join('')
    .toUpperCase();
}

function statusBadge(status) {
  const css = STATUS_CLASS[status] || 'badge-neutral';
  return `<span class="badge ${css}">${escapeHtml(status || '—')}</span>`;
}

function clientName(id) {
  const client = state.clientes.find(item => Number(item.id) === Number(id));
  return client ? `${client.nombres} ${client.apellidos}` : `Cliente #${id}`;
}

function vehicleLabel(id) {
  const vehicle = state.vehiculos.find(item => Number(item.id) === Number(id));
  return vehicle ? `${vehicle.placa} · ${vehicle.marca} ${vehicle.modelo}` : `Vehículo #${id}`;
}

function vehicleById(id) {
  return state.vehiculos.find(item => Number(item.id) === Number(id)) || null;
}

function clientById(id) {
  return state.clientes.find(item => Number(item.id) === Number(id)) || null;
}

/* ============================= API ============================= */

class ApiError extends Error {
  constructor(message, fields = []) {
    super(message);
    this.name = 'ApiError';
    this.fields = fields;
  }
}

async function api(base, path, options = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  const headers = { ...(options.body ? { 'Content-Type': 'application/json' } : {}), ...(options.headers || {}) };

  let response;
  try {
    response = await fetch(base + path, { ...options, headers, signal: controller.signal });
  } catch (error) {
    throw new ApiError(`No se pudo conectar con ${base}. Verifica que el servicio esté encendido.`);
  } finally {
    clearTimeout(timer);
  }

  const text = await response.text();
  let data = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = null;
    }
  }

  if (!response.ok) {
    const message = data?.message || `La operación respondió HTTP ${response.status}`;
    throw new ApiError(message, data?.errors || []);
  }

  return data;
}

async function fetchHealth(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 3500);
  try {
    const response = await fetch(url, { cache: 'no-store', signal: controller.signal });
    return response.ok;
  } catch {
    return false;
  } finally {
    clearTimeout(timer);
  }
}

async function updateHealth() {
  const checks = [
    ['clientes', `${API.clientes}/api/clientes`],
    ['vehiculos', `${API.vehiculos}/api/vehiculos`],
    ['alquileres', `${API.alquileres}/api/alquileres`]
  ];

  const results = await Promise.all(checks.map(async ([key, url]) => [key, await fetchHealth(url)]));
  results.forEach(([key, ok]) => { state.health[key] = ok; });
  renderHealth();
}

async function loadAll({ silent = false } = {}) {
  const requests = [
    api(API.clientes, '/api/clientes'),
    api(API.vehiculos, '/api/vehiculos'),
    api(API.alquileres, '/api/alquileres')
  ];
  const results = await Promise.allSettled(requests);
  const errors = [];

  if (results[0].status === 'fulfilled') state.clientes = results[0].value;
  else errors.push(`Clientes: ${results[0].reason.message}`);

  if (results[1].status === 'fulfilled') state.vehiculos = results[1].value;
  else errors.push(`Vehículos: ${results[1].reason.message}`);

  if (results[2].status === 'fulfilled') state.alquileres = results[2].value;
  else errors.push(`Alquileres: ${results[2].reason.message}`);

  renderAll();

  if (errors.length) {
    setBanner(errors.join(' · '));
    if (!silent) toast(errors[0], 'error');
  } else {
    setBanner('');
  }

  updateHealth();
}

/* ============================= RENDER ============================= */

function setBanner(message, type = 'error') {
  const banner = $('#banner');
  if (!message) {
    banner.classList.add('hidden');
    banner.textContent = '';
    return;
  }
  banner.textContent = message;
  banner.classList.remove('hidden');
  banner.classList.toggle('info', type === 'info');
}

function renderAll() {
  renderStats();
  renderServiceCards();
  renderRecentRentals();
  renderClientes();
  renderVehiculos();
  renderAlquileres();
}

function renderHealth() {
  const info = [
    ['clientes', 'Clientes'],
    ['vehiculos', 'Vehículos'],
    ['alquileres', 'Alquileres']
  ];

  $('#service-pills').innerHTML = info.map(([key, label]) => {
    const online = state.health[key] === true;
    const known = state.health[key] !== null;
    return `<span class="pill ${online ? 'online' : 'offline'}" title="${label}: ${online ? 'en línea' : known ? 'sin conexión' : 'comprobando'}">
      <span class="dot ${online ? 'dot-green' : known ? 'dot-red' : 'dot-amber'}"></span>${label}
    </span>`;
  }).join('');

  renderServiceCards();
}

function renderServiceCards() {
  const services = [
    ['clientes', 'ms-cliente', 'Gestión de clientes', API.clientes, '/api/clientes'],
    ['vehiculos', 'ms-vehiculo', 'Flota y disponibilidad', API.vehiculos, '/api/vehiculos'],
    ['alquileres', 'ms-alquiler', 'Contratos y cálculo de importes', API.alquileres, '/api/alquileres']
  ];

  $('#service-cards').innerHTML = services.map(([key, name, description, base, path]) => {
    const online = state.health[key] === true;
    const known = state.health[key] !== null;
    return `<div class="service-card">
      <span class="dot ${online ? 'dot-green' : known ? 'dot-red' : 'dot-amber'}"></span>
      <div class="service-copy">
        <strong>${name}</strong>
        <small>${description}</small>
        <code>${escapeHtml(base + path)}</code>
      </div>
      <span class="status-badge ${online ? 'status-on' : 'status-off'}">${online ? 'EN LÍNEA' : known ? 'CAÍDO' : '...'}</span>
    </div>`;
  }).join('');
}

function renderStats() {
  $('#stat-clientes').textContent = state.clientes.length;
  $('#stat-vehiculos').textContent = state.vehiculos.length;
  $('#stat-disponibles').textContent = state.vehiculos.filter(vehicle => vehicle.estado === 'DISPONIBLE').length;
  $('#stat-alquileres').textContent = state.alquileres.filter(rental => rental.estado === 'ACTIVO').length;
}

function renderRecentRentals() {
  const recent = [...state.alquileres].sort((a, b) => Number(b.id) - Number(a.id)).slice(0, 5);
  const body = $('#tbody-recientes');

  if (!recent.length) {
    body.innerHTML = '<tr><td colspan="6" class="empty">Todavía no hay alquileres registrados.</td></tr>';
    return;
  }

  body.innerHTML = recent.map(rental => `<tr>
    <td class="mono">#${rental.id}</td>
    <td>${escapeHtml(clientName(rental.idCliente))}</td>
    <td>${escapeHtml(vehicleLabel(rental.idVehiculo))}</td>
    <td class="periodo">${formatDate(rental.fechaInicio)}<br><small>${formatDate(rental.fechaFin)}</small></td>
    <td class="money">${money(rental.importeEstimado)}</td>
    <td>${statusBadge(rental.estado)}</td>
  </tr>`).join('');
}

function renderClientes() {
  const query = ($('#search-clientes').value || '').trim().toLowerCase();
  const filtered = state.clientes
    .filter(client => {
      const searchable = `${client.nombres} ${client.apellidos} ${client.documento} ${client.correo}`.toLowerCase();
      return !query || searchable.includes(query);
    })
    .sort((a, b) => Number(a.id) - Number(b.id));

  $('#count-clientes').textContent = `${filtered.length} cliente${filtered.length === 1 ? '' : 's'}`;
  const body = $('#tbody-clientes');

  if (!filtered.length) {
    body.innerHTML = `<tr><td colspan="5" class="empty">${state.clientes.length ? 'No hay clientes que coincidan con la búsqueda.' : 'Aún no hay clientes. Usa “Nuevo cliente” para registrar el primero.'}</td></tr>`;
    return;
  }

  body.innerHTML = filtered.map(client => `<tr>
    <td>
      <div class="cell-main">
        <span class="avatar">${escapeHtml(initials(`${client.nombres} ${client.apellidos}`))}</span>
        <div>
          <span class="cell-title">${escapeHtml(client.nombres)} ${escapeHtml(client.apellidos)}</span>
          <span class="cell-sub">ID #${client.id}</span>
        </div>
      </div>
    </td>
    <td class="mono">${escapeHtml(client.documento)}</td>
    <td>
      <span class="cell-title">${escapeHtml(client.correo)}</span>
      <span class="cell-sub">${escapeHtml(client.telefono)}</span>
    </td>
    <td>${statusBadge(client.estado)}</td>
    <td class="actions">
      <button class="btn btn-sm btn-outline" data-action="edit-cliente" data-id="${client.id}" type="button">Editar</button>
      <button class="btn btn-sm btn-danger" data-action="delete-cliente" data-id="${client.id}" type="button">Eliminar</button>
    </td>
  </tr>`).join('');
}

function renderVehiculos() {
  const query = ($('#search-vehiculos').value || '').trim().toLowerCase();
  const status = $('#filter-vehiculos').value;
  const filtered = state.vehiculos
    .filter(vehicle => {
      const searchable = `${vehicle.placa} ${vehicle.marca} ${vehicle.modelo}`.toLowerCase();
      return (!query || searchable.includes(query)) && (!status || vehicle.estado === status);
    })
    .sort((a, b) => Number(a.id) - Number(b.id));

  $('#count-vehiculos').textContent = `${filtered.length} vehículo${filtered.length === 1 ? '' : 's'}`;
  const body = $('#tbody-vehiculos');

  if (!filtered.length) {
    body.innerHTML = `<tr><td colspan="6" class="empty">${state.vehiculos.length ? 'No hay vehículos que coincidan con el filtro.' : 'Aún no hay vehículos registrados.'}</td></tr>`;
    return;
  }

  body.innerHTML = filtered.map(vehicle => `<tr>
    <td>
      <div class="cell-main">
        <span class="avatar violet">${escapeHtml(initials(`${vehicle.marca} ${vehicle.modelo}`))}</span>
        <div>
          <span class="cell-title">${escapeHtml(vehicle.marca)} ${escapeHtml(vehicle.modelo)}</span>
          <span class="cell-sub">ID #${vehicle.id}</span>
        </div>
      </div>
    </td>
    <td class="mono">${escapeHtml(vehicle.placa)}</td>
    <td>${vehicle.anio}</td>
    <td class="tarifa">${money(vehicle.tarifaDiaria)}</td>
    <td>${statusBadge(vehicle.estado)}</td>
    <td class="actions">
      <button class="btn btn-sm btn-outline" data-action="edit-vehiculo" data-id="${vehicle.id}" type="button">Editar</button>
      <button class="btn btn-sm btn-danger" data-action="delete-vehiculo" data-id="${vehicle.id}" type="button">Eliminar</button>
    </td>
  </tr>`).join('');
}

function renderAlquileres() {
  const status = $('#filter-alquileres').value;
  const filtered = state.alquileres
    .filter(rental => !status || rental.estado === status)
    .sort((a, b) => Number(b.id) - Number(a.id));

  $('#count-alquileres').textContent = `${filtered.length} alquiler${filtered.length === 1 ? '' : 'es'}`;
  const body = $('#tbody-alquileres');

  if (!filtered.length) {
    body.innerHTML = `<tr><td colspan="8" class="empty">${state.alquileres.length ? 'No hay alquileres con ese estado.' : 'Aún no hay alquileres. Usa “Nuevo alquiler” para registrar uno.'}</td></tr>`;
    return;
  }

  body.innerHTML = filtered.map(rental => {
    const days = daysBetween(rental.fechaInicio, rental.fechaFin);
    const actions = rental.estado === 'ACTIVO'
      ? `<button class="btn btn-sm btn-ok" data-action="finalize-alquiler" data-id="${rental.id}" type="button">Finalizar</button>
         <button class="btn btn-sm btn-outline" data-action="cancel-alquiler" data-id="${rental.id}" type="button">Cancelar</button>`
      : '';
    return `<tr>
      <td class="mono">#${rental.id}</td>
      <td>${escapeHtml(clientName(rental.idCliente))}</td>
      <td>${escapeHtml(vehicleLabel(rental.idVehiculo))}</td>
      <td class="periodo">${formatDate(rental.fechaInicio)} → ${formatDate(rental.fechaFin)}</td>
      <td>${days ?? '—'}</td>
      <td class="money">${money(rental.importeEstimado)}</td>
      <td>${statusBadge(rental.estado)}</td>
      <td class="actions">
        ${actions}
        <button class="btn btn-sm btn-danger" data-action="delete-alquiler" data-id="${rental.id}" type="button">Eliminar</button>
      </td>
    </tr>`;
  }).join('');
}

/* ============================= NAVEGACIÓN ============================= */

function showView(name, updateHash = true) {
  const meta = VIEW_META[name] || VIEW_META.dashboard;
  $$('.nav-item').forEach(item => item.classList.toggle('active', item.dataset.view === name));
  $$('.view').forEach(view => view.classList.add('hidden'));
  $(`#view-${name}`).classList.remove('hidden');
  $('#page-title').textContent = meta.title;
  $('#page-subtitle').textContent = meta.subtitle;
  $('.main').scrollTop = 0;
  if (updateHash && window.location.hash !== `#${name}`) {
    window.history.replaceState(null, '', `#${name}`);
  }
}

/* ============================= MODALES ============================= */

function openModal(id) {
  const modal = $(`#${id}`);
  modal.classList.remove('hidden');
  document.body.style.overflow = 'hidden';
  setTimeout(() => {
    const focusable = modal.querySelector('input:not([type="hidden"]), select, button');
    focusable?.focus();
  }, 60);
}

function closeModal(modal) {
  if (!modal) return;
  modal.classList.add('hidden');
  if (!$$('.modal:not(.hidden)').length) document.body.style.overflow = '';
}

function closeAllModals() {
  $$('.modal').forEach(modal => modal.classList.add('hidden'));
  document.body.style.overflow = '';
}

function openClienteModal(cliente = null) {
  const form = $('#form-cliente');
  form.reset();
  $('#cliente-id').value = cliente?.id ?? '';
  $('#cliente-nombres').value = cliente?.nombres ?? '';
  $('#cliente-apellidos').value = cliente?.apellidos ?? '';
  $('#cliente-documento').value = cliente?.documento ?? '';
  $('#cliente-telefono').value = cliente?.telefono ?? '';
  $('#cliente-correo').value = cliente?.correo ?? '';
  $('#cliente-estado').value = cliente?.estado ?? 'ACTIVO';
  $('#modal-cliente-title').textContent = cliente ? 'Editar cliente' : 'Nuevo cliente';
  $('#btn-guardar-cliente').textContent = cliente ? 'Guardar cambios' : 'Guardar cliente';
  openModal('modal-cliente');
}

function openVehiculoModal(vehicle = null) {
  const form = $('#form-vehiculo');
  form.reset();
  $('#vehiculo-id').value = vehicle?.id ?? '';
  $('#vehiculo-placa').value = vehicle?.placa ?? '';
  $('#vehiculo-marca').value = vehicle?.marca ?? '';
  $('#vehiculo-modelo').value = vehicle?.modelo ?? '';
  $('#vehiculo-anio').value = vehicle?.anio ?? new Date().getFullYear();
  $('#vehiculo-tarifa').value = vehicle?.tarifaDiaria ?? '';
  $('#vehiculo-estado').value = vehicle?.estado ?? 'DISPONIBLE';
  $('#modal-vehiculo-title').textContent = vehicle ? 'Editar vehículo' : 'Nuevo vehículo';
  $('#btn-guardar-vehiculo').textContent = vehicle ? 'Guardar cambios' : 'Guardar vehículo';
  openModal('modal-vehiculo');
}

function fillAlquilerSelects() {
  const clientSelect = $('#alquiler-cliente');
  const vehicleSelect = $('#alquiler-vehiculo');
  const clients = [...state.clientes].sort((a, b) => Number(a.id) - Number(b.id));
  const vehicles = state.vehiculos
    .filter(vehicle => vehicle.estado === 'DISPONIBLE')
    .sort((a, b) => Number(a.id) - Number(b.id));

  clientSelect.innerHTML = clients.length
    ? clients.map(client => `<option value="${client.id}">${escapeHtml(client.nombres)} ${escapeHtml(client.apellidos)} · DNI ${escapeHtml(client.documento)}</option>`).join('')
    : '<option value="">No hay clientes registrados</option>';

  vehicleSelect.innerHTML = vehicles.length
    ? vehicles.map(vehicle => `<option value="${vehicle.id}">${escapeHtml(vehicle.placa)} · ${escapeHtml(vehicle.marca)} ${escapeHtml(vehicle.modelo)} · ${money(vehicle.tarifaDiaria)}</option>`).join('')
    : '<option value="">No hay vehículos disponibles</option>';

  return { clients, vehicles };
}

function openAlquilerModal() {
  const { clients, vehicles } = fillAlquilerSelects();
  if (!clients.length) {
    toast('Primero registra al menos un cliente.', 'error');
    showView('clientes');
    return;
  }
  if (!vehicles.length) {
    toast('No hay vehículos disponibles para alquilar.', 'error');
    return;
  }

  $('#form-alquiler').reset();
  const start = new Date();
  start.setDate(start.getDate() + 1);
  const end = new Date(start);
  end.setDate(start.getDate() + 3);
  $('#alquiler-inicio').value = toIsoDate(start);
  $('#alquiler-fin').value = toIsoDate(end);
  $('#alquiler-inicio').min = toIsoDate(new Date());
  $('#alquiler-tarifa').value = '';
  updateEstimate();
  openModal('modal-alquiler');
}

function updateEstimate() {
  const vehicleId = Number($('#alquiler-vehiculo').value);
  const vehicle = vehicleById(vehicleId);
  const start = $('#alquiler-inicio').value;
  const end = $('#alquiler-fin').value;
  const rawTariff = $('#alquiler-tarifa').value;
  const tariff = rawTariff !== '' ? Number(rawTariff) : Number(vehicle?.tarifaDiaria ?? 0);
  const days = daysBetween(start, end);
  const value = $('#estimate-value');
  const detail = $('#estimate-detail');

  if (!vehicle || !start || !end || days === null || days < 1) {
    value.textContent = 'S/ 0.00';
    detail.textContent = 'Selecciona vehículo y fechas válidas';
    return;
  }

  value.textContent = money(Math.max(1, days) * tariff);
  detail.textContent = `${Math.max(1, days)} día${days === 1 ? '' : 's'} × ${money(tariff)}`;
}

/* ============================= MENSAJES ============================= */

function toast(message, type = 'info') {
  const container = $('#toasts');
  const element = document.createElement('div');
  element.className = `toast ${type}`;
  element.textContent = message;
  container.appendChild(element);
  setTimeout(() => {
    element.style.opacity = '0';
    element.style.transform = 'translateY(6px)';
    element.style.transition = 'opacity .2s, transform .2s';
    setTimeout(() => element.remove(), 220);
  }, 4600);
}

function apiErrorMessage(error) {
  if (error instanceof ApiError && error.fields?.length) {
    const details = error.fields.map(item => `${item.field}: ${item.message}`).join(' · ');
    return `${error.message} — ${details}`;
  }
  return error?.message || 'Ocurrió un error inesperado.';
}

function setBusy(button, busy, busyText = 'Guardando...') {
  if (!button) return;
  if (busy) {
    button.dataset.originalText = button.textContent;
    button.textContent = busyText;
    button.disabled = true;
  } else {
    button.textContent = button.dataset.originalText || button.textContent;
    button.disabled = false;
  }
}

/* ============================= FORMULARIOS ============================= */

async function submitCliente(event) {
  event.preventDefault();
  const form = event.currentTarget;
  if (!form.reportValidity()) return;

  const id = $('#cliente-id').value;
  const payload = {
    nombres: $('#cliente-nombres').value.trim(),
    apellidos: $('#cliente-apellidos').value.trim(),
    documento: $('#cliente-documento').value.trim(),
    correo: $('#cliente-correo').value.trim(),
    telefono: $('#cliente-telefono').value.trim(),
    estado: $('#cliente-estado').value
  };
  const button = $('#btn-guardar-cliente');

  try {
    setBusy(button, true);
    if (id) {
      await api(API.clientes, `/api/clientes/${id}`, { method: 'PUT', body: JSON.stringify(payload) });
      toast('Cliente actualizado correctamente.', 'success');
    } else {
      await api(API.clientes, '/api/clientes', { method: 'POST', body: JSON.stringify(payload) });
      toast('Cliente registrado correctamente.', 'success');
    }
    closeAllModals();
    await loadAll({ silent: true });
  } catch (error) {
    toast(apiErrorMessage(error), 'error');
  } finally {
    setBusy(button, false);
  }
}

async function submitVehiculo(event) {
  event.preventDefault();
  const form = event.currentTarget;
  if (!form.reportValidity()) return;

  const id = $('#vehiculo-id').value;
  const payload = {
    placa: $('#vehiculo-placa').value.trim().toUpperCase(),
    marca: $('#vehiculo-marca').value.trim(),
    modelo: $('#vehiculo-modelo').value.trim(),
    anio: Number($('#vehiculo-anio').value),
    tarifaDiaria: Number($('#vehiculo-tarifa').value),
    estado: $('#vehiculo-estado').value
  };
  const button = $('#btn-guardar-vehiculo');

  try {
    setBusy(button, true);
    if (id) {
      await api(API.vehiculos, `/api/vehiculos/${id}`, { method: 'PUT', body: JSON.stringify(payload) });
      toast('Vehículo actualizado correctamente.', 'success');
    } else {
      await api(API.vehiculos, '/api/vehiculos', { method: 'POST', body: JSON.stringify(payload) });
      toast('Vehículo registrado correctamente.', 'success');
    }
    closeAllModals();
    await loadAll({ silent: true });
  } catch (error) {
    toast(apiErrorMessage(error), 'error');
  } finally {
    setBusy(button, false);
  }
}

async function submitAlquiler(event) {
  event.preventDefault();
  const form = event.currentTarget;
  if (!form.reportValidity()) return;

  const start = $('#alquiler-inicio').value;
  const end = $('#alquiler-fin').value;
  const today = toIsoDate(new Date());
  if (start < today) {
    toast('La fecha de inicio no puede estar en el pasado.', 'error');
    return;
  }
  if (!end || end <= start) {
    toast('La fecha de fin debe ser posterior a la fecha de inicio.', 'error');
    return;
  }
  if (!$('#alquiler-cliente').value || !$('#alquiler-vehiculo').value) {
    toast('Selecciona un cliente y un vehículo disponible.', 'error');
    return;
  }

  const payload = {
    idCliente: Number($('#alquiler-cliente').value),
    idVehiculo: Number($('#alquiler-vehiculo').value),
    fechaInicio: start,
    fechaFin: end
  };
  const tariff = $('#alquiler-tarifa').value;
  if (tariff !== '') payload.tarifaDiaria = Number(tariff);

  const button = $('#btn-guardar-alquiler');
  try {
    setBusy(button, true, 'Registrando...');
    const created = await api(API.alquileres, '/api/alquileres', { method: 'POST', body: JSON.stringify(payload) });
    closeAllModals();
    toast(`Alquiler #${created.id} registrado por ${money(created.importeEstimado)}.`, 'success');
    await loadAll({ silent: true });
  } catch (error) {
    toast(apiErrorMessage(error), 'error');
  } finally {
    setBusy(button, false);
  }
}

/* ============================= ACCIONES DE TABLA ============================= */

async function handleAction(action, id) {
  try {
    if (action === 'edit-cliente') {
      openClienteModal(clientById(id));
      return;
    }
    if (action === 'edit-vehiculo') {
      openVehiculoModal(vehicleById(id));
      return;
    }
    if (action === 'delete-cliente') {
      if (!confirm(`¿Eliminar al cliente "${clientName(id)}"? Esta acción no se puede deshacer.`)) return;
      await api(API.clientes, `/api/clientes/${id}`, { method: 'DELETE' });
      toast('Cliente eliminado.', 'success');
    }
    if (action === 'delete-vehiculo') {
      if (!confirm(`¿Eliminar el vehículo "${vehicleLabel(id)}"?`)) return;
      await api(API.vehiculos, `/api/vehiculos/${id}`, { method: 'DELETE' });
      toast('Vehículo eliminado.', 'success');
    }
    if (action === 'finalize-alquiler') {
      if (!confirm(`¿Finalizar el alquiler #${id}? El vehículo volverá a estar DISPONIBLE.`)) return;
      await api(API.alquileres, `/api/alquileres/${id}/finalizar`, { method: 'PATCH' });
      toast('Alquiler finalizado. Vehículo liberado.', 'success');
    }
    if (action === 'cancel-alquiler') {
      if (!confirm(`¿Cancelar el alquiler #${id}? El vehículo volverá a estar DISPONIBLE.`)) return;
      await api(API.alquileres, `/api/alquileres/${id}/cancelar`, { method: 'PATCH' });
      toast('Alquiler cancelado. Vehículo liberado.', 'success');
    }
    if (action === 'delete-alquiler') {
      if (!confirm(`¿Eliminar el alquiler #${id}?`)) return;
      await api(API.alquileres, `/api/alquileres/${id}`, { method: 'DELETE' });
      toast('Alquiler eliminado.', 'success');
    }
    await loadAll({ silent: true });
  } catch (error) {
    toast(apiErrorMessage(error), 'error');
  }
}

/* ============================= EVENTOS ============================= */

function bindEvents() {
  $$('.nav-item').forEach(item => {
    item.addEventListener('click', () => showView(item.dataset.view));
  });

  $$('[data-go]').forEach(button => {
    button.addEventListener('click', () => showView(button.dataset.go));
  });

  $('#refresh-btn').addEventListener('click', async () => {
    const button = $('#refresh-btn');
    button.disabled = true;
    await loadAll();
    button.disabled = false;
    toast('Datos actualizados.', 'info');
  });

  $('#btn-nuevo-cliente').addEventListener('click', () => openClienteModal());
  $('#btn-nuevo-vehiculo').addEventListener('click', () => openVehiculoModal());
  $('#btn-nuevo-alquiler').addEventListener('click', openAlquilerModal);

  $('#search-clientes').addEventListener('input', renderClientes);
  $('#search-vehiculos').addEventListener('input', renderVehiculos);
  $('#filter-vehiculos').addEventListener('change', renderVehiculos);
  $('#filter-alquileres').addEventListener('change', renderAlquileres);

  $('#form-cliente').addEventListener('submit', submitCliente);
  $('#form-vehiculo').addEventListener('submit', submitVehiculo);
  $('#form-alquiler').addEventListener('submit', submitAlquiler);

  ['#alquiler-vehiculo', '#alquiler-inicio', '#alquiler-fin', '#alquiler-tarifa'].forEach(selector => {
    $(selector).addEventListener('input', updateEstimate);
    $(selector).addEventListener('change', updateEstimate);
  });

  document.addEventListener('click', async event => {
    const actionButton = event.target.closest('[data-action]');
    if (actionButton) {
      await handleAction(actionButton.dataset.action, Number(actionButton.dataset.id));
      return;
    }

    const closeButton = event.target.closest('[data-close]');
    if (closeButton) {
      closeModal(closeButton.closest('.modal'));
      return;
    }

    if (event.target.classList.contains('modal')) {
      closeModal(event.target);
    }
  });

  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') closeAllModals();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  bindEvents();

  const initialView = window.location.hash.replace('#', '');
  if (VIEW_META[initialView]) showView(initialView, false);

  window.addEventListener('hashchange', () => {
    const view = window.location.hash.replace('#', '');
    if (VIEW_META[view]) showView(view, false);
  });

  loadAll().then(() => {
    const modal = new URLSearchParams(window.location.search).get('modal');
    if (modal === 'cliente') openClienteModal();
    if (modal === 'vehiculo') openVehiculoModal();
    if (modal === 'alquiler') openAlquilerModal();
  });

  setInterval(updateHealth, 30000);
});
