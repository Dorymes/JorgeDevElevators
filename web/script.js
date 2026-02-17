// =============================================
// JorgeDev - NUI Script (Admin + Player)
// =============================================

// =============================================
// DOM ELEMENTS
// =============================================
// Admin Panel
const adminPanel = document.getElementById('adminPanel');
const adminCloseBtn = document.getElementById('adminCloseBtn');
const btnCreateElevator = document.getElementById('btnCreateElevator');
const elevatorList = document.getElementById('elevatorList');
const emptyState = document.getElementById('emptyState');
const adminContent = document.getElementById('adminContent');
const contentEmpty = document.getElementById('contentEmpty');
const contentDetail = document.getElementById('contentDetail');
const contentForm = document.getElementById('contentForm');
const detailName = document.getElementById('detailName');
const detailId = document.getElementById('detailId');
const btnSaveElevator = document.getElementById('btnSaveElevator');
const btnDeleteElevator = document.getElementById('btnDeleteElevator');
const btnAddFloor = document.getElementById('btnAddFloor');
const floorsList = document.getElementById('floorsList');
const formTitle = document.getElementById('formTitle');
const btnBackFromForm = document.getElementById('btnBackFromForm');
const btnCancelForm = document.getElementById('btnCancelForm');
const btnSubmitForm = document.getElementById('btnSubmitForm');
const btnUsePosition = document.getElementById('btnUsePosition');

// Create Dialog
const createDialog = document.getElementById('createDialog');
const newElevatorName = document.getElementById('newElevatorName');
const btnCancelCreate = document.getElementById('btnCancelCreate');
const btnConfirmCreate = document.getElementById('btnConfirmCreate');

// Confirm Dialog
const confirmDialog = document.getElementById('confirmDialog');
const confirmTitle = document.getElementById('confirmTitle');
const confirmMessage = document.getElementById('confirmMessage');
const btnCancelConfirm = document.getElementById('btnCancelConfirm');
const btnConfirmAction = document.getElementById('btnConfirmAction');

// Interaction Settings
const btnTypeMarker = document.getElementById('btnTypeMarker');
const btnTypeTarget = document.getElementById('btnTypeTarget');
const markerConfigSection = document.getElementById('markerConfigSection');
const markerColorSection = document.getElementById('markerColorSection');
const markerColorInput = document.getElementById('markerColorInput');
const markerColorPicker = document.getElementById('markerColorPicker');
const sliderA = document.getElementById('sliderA');
const valA = document.getElementById('valA');
const markerTypeInput = document.getElementById('markerTypeInput');
const btnSaveInteraction = document.getElementById('btnSaveInteraction');
let currentInteractType = 'marker';
let currentMarkerType = 20;
let currentMarkerColor = '100,100,255,100';

// Elevator Panel (Player)
const elevatorPanel = document.getElementById('elevator-panel');
const doorOverlay = document.getElementById('doorOverlay');
const deniedOverlay = document.getElementById('deniedOverlay');
const floorButtonsContainer = document.getElementById('floorButtons');
const displayFloor = document.getElementById('displayFloor');
const displayName = document.getElementById('displayName');
const arrowUp = document.getElementById('arrowUp');
const arrowDown = document.getElementById('arrowDown');
const statusIndicator = document.getElementById('statusIndicator');
const statusText = statusIndicator?.querySelector('.status-text');
const insideFloor = document.getElementById('insideFloor');
const insideLabel = document.getElementById('insideLabel');
const insideArrow = document.getElementById('insideArrow');

// =============================================
// STATE
// =============================================
let adminElevators = [];
let selectedElevatorId = null;
let editingFloorId = null;
let confirmCallback = null;
let currentFloorId = null;
let floors = [];
let isTraveling = false;
let adminOpen = false;

// =============================================
// SOUND EFFECTS
// =============================================
function playDingSound() {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc1 = audioCtx.createOscillator();
    const gain1 = audioCtx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(1200, audioCtx.currentTime);
    osc1.frequency.exponentialRampToValueAtTime(800, audioCtx.currentTime + 0.3);
    gain1.gain.setValueAtTime(0.3, audioCtx.currentTime);
    gain1.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 1.2);
    osc1.connect(gain1);
    gain1.connect(audioCtx.destination);
    osc1.start(audioCtx.currentTime);
    osc1.stop(audioCtx.currentTime + 1.2);

    const osc2 = audioCtx.createOscillator();
    const gain2 = audioCtx.createGain();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(1600, audioCtx.currentTime + 0.05);
    osc2.frequency.exponentialRampToValueAtTime(1200, audioCtx.currentTime + 0.35);
    gain2.gain.setValueAtTime(0.15, audioCtx.currentTime + 0.05);
    gain2.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 1.0);
    osc2.connect(gain2);
    gain2.connect(audioCtx.destination);
    osc2.start(audioCtx.currentTime + 0.05);
    osc2.stop(audioCtx.currentTime + 1.0);

    setTimeout(() => audioCtx.close(), 2000);
}

function playClickSound() {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(800, audioCtx.currentTime);
    gain.gain.setValueAtTime(0.1, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.1);
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start(audioCtx.currentTime);
    osc.stop(audioCtx.currentTime + 0.1);
    setTimeout(() => audioCtx.close(), 300);
}

function playDoorSound() {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const noise = audioCtx.createOscillator();
    const noiseGain = audioCtx.createGain();
    noise.type = 'sawtooth';
    noise.frequency.setValueAtTime(60, audioCtx.currentTime);
    noise.frequency.linearRampToValueAtTime(40, audioCtx.currentTime + 1.0);
    noiseGain.gain.setValueAtTime(0.05, audioCtx.currentTime);
    noiseGain.gain.linearRampToValueAtTime(0.02, audioCtx.currentTime + 0.5);
    noiseGain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 1.0);
    noise.connect(noiseGain);
    noiseGain.connect(audioCtx.destination);
    noise.start(audioCtx.currentTime);
    noise.stop(audioCtx.currentTime + 1.0);
    setTimeout(() => audioCtx.close(), 1500);
}

// =============================================
// TOAST NOTIFICATIONS
// =============================================
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;

    const icons = { success: 'check_circle', error: 'error', info: 'info' };
    toast.innerHTML = `
        <div class="toast-icon"><span class="material-symbols-rounded">${icons[type] || 'info'}</span></div>
        <span class="toast-text">${message}</span>
    `;

    container.appendChild(toast);

    setTimeout(() => {
        toast.style.animation = 'toastOut 0.3s ease forwards';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// =============================================
// NUI MESSAGE HANDLER
// =============================================
window.addEventListener('message', (event) => {
    const data = event.data;
    switch (data.action) {
        // Admin
        case 'openAdmin':
            openAdminPanel(data);
            break;
        case 'updateElevators':
            updateElevatorData(data.elevators);
            break;
        case 'updateCoords':
            updateCoordsFromGame(data);
            break;
        case 'adminNotify':
            showToast(data.message, data.type || 'info');
            break;
        case 'hideAdmin':
            adminPanel.classList.add('hidden');
            break;
        case 'showAdmin':
            adminPanel.classList.remove('hidden');
            adminPanel.style.animation = 'adminFadeIn 0.3s ease forwards';
            break;
        case 'showPositioning':
            document.getElementById('positioningBar').classList.remove('hidden');
            break;
        case 'hidePositioning':
            document.getElementById('positioningBar').classList.add('hidden');
            break;
        case 'updatePositionCoords':
            document.getElementById('posCoordX').textContent = 'X: ' + parseFloat(data.x).toFixed(1);
            document.getElementById('posCoordY').textContent = 'Y: ' + parseFloat(data.y).toFixed(1);
            document.getElementById('posCoordZ').textContent = 'Z: ' + parseFloat(data.z).toFixed(1);
            break;
        // Player
        case 'openPanel':
            openPanel(data);
            break;
        case 'closeDoors':
            closeDoors();
            break;
        case 'traveling':
            startTraveling(data);
            break;
        case 'openDoors':
            openDoors(data);
            break;
        case 'arrived':
            arrived();
            break;
        case 'accessDenied':
            showAccessDenied(data.message);
            break;
        case 'sameFloor':
            showSameFloor();
            break;
    }
});

// =============================================
// ADMIN PANEL FUNCTIONS
// =============================================

// Normaliza los datos de Lua (puede venir como array o como objeto)
// Siempre devuelve un array plano de elevators
function normalizeElevators(data) {
    if (!data) return [];
    // Si es un array
    if (Array.isArray(data)) {
        return data.filter(e => e != null);
    }
    // Si es un objeto con claves
    return Object.values(data).filter(e => e != null);
}

// Busca un elevator por su ID real de la DB
function findElevatorById(id) {
    return adminElevators.find(e => e.id == id) || null;
}

function openAdminPanel(data) {
    adminElevators = normalizeElevators(data.elevators);
    adminOpen = true;
    adminPanel.classList.remove('hidden');
    selectedElevatorId = null;
    renderElevatorList();
    showContentEmpty();
}

function closeAdminPanel() {
    adminPanel.style.animation = 'adminFadeOut 0.3s ease forwards';
    setTimeout(() => {
        adminPanel.classList.add('hidden');
        adminPanel.style.animation = '';
        adminOpen = false;
        fetch('https://JorgeDevElevators/closeAdmin', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }, 300);
}

function updateElevatorData(elevators) {
    adminElevators = normalizeElevators(elevators);
    renderElevatorList();
    if (selectedElevatorId && findElevatorById(selectedElevatorId)) {
        showElevatorDetail(selectedElevatorId);
    }
}

// Render elevator sidebar list
function renderElevatorList() {
    elevatorList.innerHTML = '';

    if (adminElevators.length === 0) {
        elevatorList.innerHTML = `
            <div class="empty-state">
                <span class="material-symbols-rounded">elevator</span>
                <p>No hay ascensores creados</p>
                <small>Crea uno para empezar</small>
            </div>
        `;
        return;
    }

    adminElevators.forEach((elev, index) => {
        if (!elev) return;
        const realId = elev.id;
        const floorCount = elev.floors ? elev.floors.length : 0;
        const item = document.createElement('div');
        item.className = `elevator-list-item${selectedElevatorId == realId ? ' active' : ''}`;
        item.innerHTML = `
            <div class="elevator-item-icon">
                <span class="material-symbols-rounded">elevator</span>
            </div>
            <div class="elevator-item-info">
                <div class="elevator-item-name">${elev.name}</div>
                <div class="elevator-item-meta">${floorCount} planta${floorCount !== 1 ? 's' : ''} · ID: ${realId}</div>
            </div>
        `;
        item.addEventListener('click', () => {
            selectedElevatorId = realId;
            showElevatorDetail(realId);
            renderElevatorList();
        });

        item.style.opacity = '0';
        item.style.transform = 'translateX(-10px)';
        setTimeout(() => {
            item.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
            item.style.opacity = '1';
            item.style.transform = 'translateX(0)';
        }, index * 50);

        elevatorList.appendChild(item);
    });
}

function showContentEmpty() {
    contentEmpty.classList.remove('hidden');
    contentDetail.classList.add('hidden');
    contentForm.classList.add('hidden');
}

function showElevatorDetail(elevatorId) {
    const elev = findElevatorById(elevatorId);
    if (!elev) return;

    selectedElevatorId = elevatorId;
    contentEmpty.classList.add('hidden');
    contentForm.classList.add('hidden');
    contentDetail.classList.remove('hidden');

    detailName.value = elev.name;
    detailId.textContent = 'ID: ' + elevatorId;

    // Load interaction settings
    currentInteractType = elev.interact_type || 'marker';
    currentMarkerType = parseInt(elev.marker_type) || 20;
    currentMarkerColor = elev.marker_color || '100,100,255,100';
    updateInteractionUI();

    renderFloorCards(elev.floors || []);
}

function renderFloorCards(floors) {
    floorsList.innerHTML = '';

    if (floors.length === 0) {
        floorsList.innerHTML = `
            <div class="empty-state">
                <span class="material-symbols-rounded">layers_clear</span>
                <p>Sin plantas</p>
                <small>Añade plantas para configurar el ascensor</small>
            </div>
        `;
        return;
    }

    const sorted = [...floors].sort((a, b) => (b.floor_index ?? 0) - (a.floor_index ?? 0));

    sorted.forEach((floor, index) => {
        const card = document.createElement('div');
        card.className = 'floor-card';

        const floorIdx = floor.floor_index ?? 0;
        const displayIdx = floorIdx === 0 ? 'PB' : (floorIdx < 0 ? `S${Math.abs(floorIdx)}` : floorIdx);

        let tags = '';
        if (floor.restricted_job && floor.restricted_job !== '') {
            tags += `<span class="floor-card-tag tag-job">👔 ${floor.restricted_job}</span>`;
            if (floor.restricted_grade && floor.restricted_grade > 0) {
                tags += `<span class="floor-card-tag tag-grade">⭐ Grado ${floor.restricted_grade}+</span>`;
            }
        } else {
            tags += `<span class="floor-card-tag tag-free">🔓 Libre</span>`;
        }

        const x = parseFloat(floor.x || 0).toFixed(1);
        const y = parseFloat(floor.y || 0).toFixed(1);
        const z = parseFloat(floor.z || 0).toFixed(1);

        card.innerHTML = `
            <div class="floor-card-index">${displayIdx}</div>
            <div class="floor-card-info">
                <div class="floor-card-name">${floor.label}</div>
                <div class="floor-card-meta">
                    <span class="floor-card-coord">${x}, ${y}, ${z}</span>
                    ${tags}
                </div>
            </div>
            <div class="floor-card-actions">
                <button class="floor-card-btn btn-tp" title="Teleportar" data-action="tp" data-floor-id="${floor.id}">
                    <span class="material-symbols-rounded">my_location</span>
                </button>
                <button class="floor-card-btn btn-edit" title="Editar" data-action="edit" data-floor-id="${floor.id}">
                    <span class="material-symbols-rounded">edit</span>
                </button>
                <button class="floor-card-btn btn-del" title="Eliminar" data-action="delete" data-floor-id="${floor.id}">
                    <span class="material-symbols-rounded">delete</span>
                </button>
            </div>
        `;

        // Action buttons
        card.querySelectorAll('.floor-card-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const action = btn.dataset.action;
                const floorId = parseInt(btn.dataset.floorId);

                if (action === 'tp') {
                    teleportToFloor(floorId, floor);
                } else if (action === 'edit') {
                    openEditFloorForm(floor);
                } else if (action === 'delete') {
                    deleteFloor(floorId, floor.label);
                }
            });
        });

        card.style.opacity = '0';
        card.style.transform = 'translateY(8px)';
        setTimeout(() => {
            card.style.transition = 'opacity 0.25s ease, transform 0.25s ease, background 0.2s ease, border-color 0.2s ease';
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, index * 40);

        floorsList.appendChild(card);
    });
}

// =============================================
// ADMIN ACTIONS
// =============================================

// Create elevator dialog
btnCreateElevator.addEventListener('click', () => {
    newElevatorName.value = '';
    createDialog.classList.remove('hidden');
    setTimeout(() => newElevatorName.focus(), 100);
});

btnCancelCreate.addEventListener('click', () => {
    createDialog.classList.add('hidden');
});

btnConfirmCreate.addEventListener('click', () => {
    const name = newElevatorName.value.trim();
    if (!name) return;
    createDialog.classList.add('hidden');
    fetch('https://JorgeDevElevators/admin:createElevator', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name })
    });
});

newElevatorName.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') btnConfirmCreate.click();
});

// Save elevator name
btnSaveElevator.addEventListener('click', () => {
    const newName = detailName.value.trim();
    if (!newName || !selectedElevatorId) return;
    fetch('https://JorgeDevElevators/admin:renameElevator', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ elevatorId: selectedElevatorId, name: newName })
    });
});

// Delete elevator
btnDeleteElevator.addEventListener('click', () => {
    if (!selectedElevatorId) return;
    const elev = findElevatorById(selectedElevatorId);
    showConfirmDialog(
        'Eliminar Ascensor',
        `¿Seguro que quieres eliminar "${elev?.name}"? Se borrarán todas sus plantas.`,
        () => {
            fetch('https://JorgeDevElevators/admin:deleteElevator', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ elevatorId: selectedElevatorId })
            });
            selectedElevatorId = null;
            showContentEmpty();
        }
    );
});

// Add floor
btnAddFloor.addEventListener('click', () => {
    openAddFloorForm();
});

function openAddFloorForm() {
    editingFloorId = null;
    formTitle.textContent = 'Nueva Planta';
    document.getElementById('floorLabel').value = '';
    const currentElev = findElevatorById(selectedElevatorId);
    document.getElementById('floorIndex').value = currentElev?.floors?.length || 0;
    document.getElementById('floorJob').value = '';
    document.getElementById('floorGrade').value = 0;
    document.getElementById('floorX').value = '0';
    document.getElementById('floorY').value = '0';
    document.getElementById('floorZ').value = '0';
    document.getElementById('floorHeading').value = '0';

    contentDetail.classList.add('hidden');
    contentForm.classList.remove('hidden');

    // Request current coords
    fetch('https://JorgeDevElevators/admin:getCoords', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function openEditFloorForm(floor) {
    editingFloorId = floor.id;
    formTitle.textContent = 'Editar Planta';
    document.getElementById('floorLabel').value = floor.label || '';
    document.getElementById('floorIndex').value = floor.floor_index ?? 0;
    document.getElementById('floorJob').value = floor.restricted_job || '';
    document.getElementById('floorGrade').value = floor.restricted_grade || 0;
    document.getElementById('floorX').value = parseFloat(floor.x || 0).toFixed(2);
    document.getElementById('floorY').value = parseFloat(floor.y || 0).toFixed(2);
    document.getElementById('floorZ').value = parseFloat(floor.z || 0).toFixed(2);
    document.getElementById('floorHeading').value = parseFloat(floor.heading || 0).toFixed(2);

    contentDetail.classList.add('hidden');
    contentForm.classList.remove('hidden');
}

// Back from form
btnBackFromForm.addEventListener('click', goBackToDetail);
btnCancelForm.addEventListener('click', goBackToDetail);

function goBackToDetail() {
    contentForm.classList.add('hidden');
    contentDetail.classList.remove('hidden');
    editingFloorId = null;
}

// Submit form
btnSubmitForm.addEventListener('click', () => {
    const label = document.getElementById('floorLabel').value.trim();
    if (!label) {
        showToast('El nombre de la planta es obligatorio', 'error');
        return;
    }

    const floorData = {
        label,
        floor_index: parseInt(document.getElementById('floorIndex').value) || 0,
        x: parseFloat(document.getElementById('floorX').value) || 0,
        y: parseFloat(document.getElementById('floorY').value) || 0,
        z: parseFloat(document.getElementById('floorZ').value) || 0,
        heading: parseFloat(document.getElementById('floorHeading').value) || 0,
        restricted_job: document.getElementById('floorJob').value.trim(),
        restricted_grade: parseInt(document.getElementById('floorGrade').value) || 0,
    };

    if (editingFloorId) {
        fetch('https://JorgeDevElevators/admin:editFloor', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                elevatorId: selectedElevatorId,
                floorId: editingFloorId,
                floorData
            })
        });
    } else {
        fetch('https://JorgeDevElevators/admin:addFloor', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                elevatorId: selectedElevatorId,
                floorData
            })
        });
    }

    goBackToDetail();
});

// Use current position
btnUsePosition.addEventListener('click', () => {
    fetch('https://JorgeDevElevators/admin:getCoords', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// Go to position - enters positioning mode
const btnGoPosition = document.getElementById('btnGoPosition');
if (btnGoPosition) {
    btnGoPosition.addEventListener('click', () => {
        fetch('https://JorgeDevElevators/admin:enterPositionMode', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    });
}

function updateCoordsFromGame(data) {
    document.getElementById('floorX').value = parseFloat(data.x).toFixed(2);
    document.getElementById('floorY').value = parseFloat(data.y).toFixed(2);
    document.getElementById('floorZ').value = parseFloat(data.z).toFixed(2);
    document.getElementById('floorHeading').value = parseFloat(data.heading).toFixed(2);
    showToast('Coordenadas actualizadas', 'success');
}

// Teleport
function teleportToFloor(floorId, floor) {
    fetch('https://JorgeDevElevators/admin:teleport', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ x: floor.x, y: floor.y, z: floor.z, heading: floor.heading })
    });
    showToast(`Teleportado a ${floor.label}`, 'info');
}

// Delete floor
function deleteFloor(floorId, floorLabel) {
    showConfirmDialog(
        'Eliminar Planta',
        `¿Seguro que quieres eliminar "${floorLabel}"?`,
        () => {
            fetch('https://JorgeDevElevators/admin:removeFloor', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ elevatorId: selectedElevatorId, floorId })
            });
        }
    );
}

// Confirm Dialog
function showConfirmDialog(title, message, callback) {
    confirmTitle.textContent = title;
    confirmMessage.textContent = message;
    confirmCallback = callback;
    confirmDialog.classList.remove('hidden');
}

btnCancelConfirm.addEventListener('click', () => {
    confirmDialog.classList.add('hidden');
    confirmCallback = null;
});

btnConfirmAction.addEventListener('click', () => {
    confirmDialog.classList.add('hidden');
    if (confirmCallback) {
        confirmCallback();
        confirmCallback = null;
    }
});

// Close admin
adminCloseBtn.addEventListener('click', closeAdminPanel);

// =============================================
// INTERACTION SETTINGS
// =============================================
function updateInteractionUI() {
    // Toggle button active state
    if (currentInteractType === 'ox_target') {
        btnTypeMarker.classList.remove('active');
        btnTypeTarget.classList.add('active');
        markerConfigSection.classList.add('hidden-section');
    } else {
        btnTypeMarker.classList.add('active');
        btnTypeTarget.classList.remove('active');
        markerConfigSection.classList.remove('hidden-section');
    }

    // Parse current color
    const parts = currentMarkerColor.split(',').map(s => parseInt(s.trim()));
    const r = parts[0] || 100, g = parts[1] || 100, b = parts[2] || 255, a = parts[3] || 100;

    // Update color picker hex
    const hex = '#' + [r, g, b].map(c => c.toString(16).padStart(2, '0')).join('');
    markerColorPicker.value = hex;

    // Update alpha slider
    sliderA.value = a;
    valA.textContent = a;

    // Update hidden input
    markerColorInput.value = currentMarkerColor;

    // Update marker type
    markerTypeInput.value = currentMarkerType;
}

function hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : { r: 100, g: 100, b: 255 };
}

// Toggle buttons
btnTypeMarker.addEventListener('click', () => {
    currentInteractType = 'marker';
    updateInteractionUI();
});

btnTypeTarget.addEventListener('click', () => {
    currentInteractType = 'ox_target';
    updateInteractionUI();
});

// Color picker change
markerColorPicker.addEventListener('input', (e) => {
    const rgb = hexToRgb(e.target.value);
    const a = parseInt(sliderA.value);
    currentMarkerColor = `${rgb.r},${rgb.g},${rgb.b},${a}`;
    markerColorInput.value = currentMarkerColor;
});

// Alpha slider change
sliderA.addEventListener('input', (e) => {
    const parts = currentMarkerColor.split(',').map(s => parseInt(s.trim()));
    const r = parts[0] || 100, g = parts[1] || 100, b = parts[2] || 255;
    const a = parseInt(e.target.value);
    currentMarkerColor = `${r},${g},${b},${a}`;
    valA.textContent = a;
    markerColorInput.value = currentMarkerColor;
});

// Save interaction button
btnSaveInteraction.addEventListener('click', () => {
    if (!selectedElevatorId) return;
    fetch('https://JorgeDevElevators/admin:updateInteraction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            elevatorId: selectedElevatorId,
            interactType: currentInteractType,
            markerType: currentMarkerType,
            markerColor: currentMarkerColor,
        })
    });
});

// Marker type presets
// Marker type input
markerTypeInput.addEventListener('input', (e) => {
    currentMarkerType = parseInt(e.target.value) || 20;
});


// =============================================
// PLAYER ELEVATOR PANEL
// =============================================
function openPanel(data) {
    floors = data.floors || [];
    currentFloorId = data.currentFloor;
    displayName.textContent = data.elevatorName || 'ASCENSOR';

    const currentFloor = floors.find(f => f.id === currentFloorId);
    displayFloor.textContent = currentFloor ? getFloorDisplayNumber(currentFloor.floorIndex) : '--';

    renderPlayerFloorButtons();
    elevatorPanel.classList.remove('hidden');
    elevatorPanel.style.animation = 'panelSlideIn 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards';
}

function renderPlayerFloorButtons() {
    floorButtonsContainer.innerHTML = '';
    const sortedFloors = [...floors].sort((a, b) => b.floorIndex - a.floorIndex);
    let visibleIndex = 0;

    sortedFloors.forEach((floor) => {
        // Ocultar plantas restringidas
        if (floor.restricted) return;

        const btn = document.createElement('button');
        btn.className = 'floor-btn';
        if (floor.id === currentFloorId) btn.classList.add('current');

        btn.innerHTML = `
            <span class="btn-number">${getFloorDisplayNumber(floor.floorIndex)}</span>
            <span class="btn-label">${floor.label}</span>
        `;

        btn.addEventListener('click', () => {
            if (isTraveling) return;
            playClickSound();
            btn.classList.add('pressed');
            setTimeout(() => btn.classList.remove('pressed'), 600);
            selectFloor(floor.id);
        });

        btn.style.opacity = '0';
        btn.style.transform = 'translateY(10px)';
        setTimeout(() => {
            btn.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
            btn.style.opacity = '1';
            btn.style.transform = 'translateY(0)';
        }, 50 + visibleIndex * 40);

        visibleIndex++;
        floorButtonsContainer.appendChild(btn);
    });
}

function getFloorDisplayNumber(floorIndex) {
    if (floorIndex === 0) return 'PB';
    if (floorIndex < 0) return 'S' + Math.abs(floorIndex);
    return floorIndex.toString();
}

function selectFloor(floorId) {
    fetch('https://JorgeDevElevators/selectFloor', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ floorId })
    });
}

// =============================================
// DOOR ANIMATIONS
// =============================================
function closeDoors() {
    isTraveling = true;
    statusIndicator.classList.add('traveling');
    if (statusText) statusText.textContent = 'EN MOVIMIENTO';
    playDoorSound();

    // Reset states
    doorOverlay.classList.remove('hidden', 'doors-open', 'traveling');
    if (insideFloor) insideFloor.textContent = '--';
    if (insideArrow) {
        insideArrow.style.display = '';
        insideArrow.textContent = '▲';
    }

    // Close doors
    setTimeout(() => doorOverlay.classList.add('doors-closed'), 50);

    // Hide elevator panel
    setTimeout(() => {
        elevatorPanel.style.animation = 'panelSlideOut 0.4s ease forwards';
        setTimeout(() => elevatorPanel.classList.add('hidden'), 400);
    }, 800);
}

function startTraveling(data) {
    doorOverlay.classList.add('traveling');

    // Set destination label
    if (insideLabel) insideLabel.textContent = data.floorLabel || 'VIAJANDO';

    // Set arrow direction (up or down based on destination)
    if (insideArrow) {
        insideArrow.textContent = '▲'; // default up
    }

    // Animate the floor counter
    animateFloorCounter(data.travelTime || 3000);
}

function animateFloorCounter(travelTime) {
    const symbols = ['--', '··', '—', '··'];
    let i = 0;
    const interval = setInterval(() => {
        if (insideFloor) insideFloor.textContent = symbols[i % symbols.length];
        i++;
    }, 350);
    setTimeout(() => clearInterval(interval), travelTime);
}

function openDoors(data) {
    doorOverlay.classList.remove('traveling');

    // Show arrived floor
    if (insideFloor) insideFloor.textContent = '✓';
    if (insideLabel) insideLabel.textContent = data.floorLabel || '';
    if (insideArrow) insideArrow.style.display = 'none';

    playDingSound();

    // Open doors after a brief pause
    setTimeout(() => {
        playDoorSound();
        doorOverlay.classList.remove('doors-closed');
        doorOverlay.classList.add('doors-open');
    }, 500);
}

function arrived() {
    statusIndicator.classList.remove('traveling');
    if (statusText) statusText.textContent = 'EN SERVICIO';
    setTimeout(() => {
        doorOverlay.classList.add('hidden');
        doorOverlay.classList.remove('doors-open', 'doors-closed', 'traveling');
        if (insideArrow) insideArrow.style.display = '';
    }, 800);
    isTraveling = false;
}

function showAccessDenied(message) {
    const deniedMsg = document.getElementById('deniedMessage');
    if (deniedMsg) deniedMsg.textContent = message || 'No tienes acceso a esta planta';
    deniedOverlay.classList.remove('hidden');
    setTimeout(() => deniedOverlay.classList.add('hidden'), 2500);
}

function showSameFloor() {
    displayFloor.style.color = '#4ade80';
    displayFloor.style.textShadow = '0 0 15px rgba(74, 222, 128, 0.5)';
    setTimeout(() => {
        displayFloor.style.color = '';
        displayFloor.style.textShadow = '';
    }, 1000);
}

// Close player panel
document.getElementById('btnEmergency')?.addEventListener('click', () => {
    playClickSound();
    closePlayerPanel();
});

function closePlayerPanel() {
    elevatorPanel.style.animation = 'panelSlideOut 0.4s ease forwards';
    setTimeout(() => {
        elevatorPanel.classList.add('hidden');
        fetch('https://JorgeDevElevators/closePanel', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }, 400);
}

// ESC key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (confirmDialog && !confirmDialog.classList.contains('hidden')) {
            confirmDialog.classList.add('hidden');
            return;
        }
        if (createDialog && !createDialog.classList.contains('hidden')) {
            createDialog.classList.add('hidden');
            return;
        }
        if (adminOpen) {
            closeAdminPanel();
            return;
        }
        if (!isTraveling) {
            closePlayerPanel();
        }
    }
});
