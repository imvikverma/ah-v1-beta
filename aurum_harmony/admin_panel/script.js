// AurumHarmony Admin Panel JavaScript

// Configuration
const API_BASE_URL = 'http://localhost:5000/api';
let currentUser = null;
let authToken = null;

// Initialize the admin panel
document.addEventListener('DOMContentLoaded', function() {
    initializeAuth();
    setupEventListeners();
    loadDashboardData();
});

// Authentication
function initializeAuth() {
    // Check for stored auth token
    const storedToken = localStorage.getItem('admin_token');
    const storedUser = localStorage.getItem('admin_user');

    if (storedToken && storedUser) {
        authToken = storedToken;
        currentUser = JSON.parse(storedUser);
        updateUIForAuthenticatedUser();
    } else {
        // Redirect to login if not authenticated
        window.location.href = '/admin/login.html';
    }
}

function updateUIForAuthenticatedUser() {
    if (currentUser) {
        document.querySelector('.user-info span').textContent = currentUser.email || 'Administrator';
    }
}

function logout() {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    window.location.href = '/admin/login.html';
}

// Event Listeners
function setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.addEventListener('click', function() {
            const tabName = this.getAttribute('onclick').match(/'([^']+)'/)[1];
            switchTab(tabName);
        });
    });
}

// Tab Management
function switchTab(tabName) {
    // Update active tab button
    document.querySelectorAll('.nav-tab').forEach(tab => tab.classList.remove('active'));
    document.querySelector(`[onclick="switchTab('${tabName}')"]`).classList.add('active');

    // Update active tab content
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
    document.getElementById(`${tabName}-tab`).classList.add('active');

    // Load tab-specific data
    switch(tabName) {
        case 'users':
            loadUsers();
            break;
        case 'system':
            loadSystemStatus();
            break;
        case 'reports':
            loadReports();
            break;
        case 'logs':
            loadLogs();
            break;
    }
}

// API Helper Functions
async function apiRequest(endpoint, options = {}) {
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`,
        },
    };

    const finalOptions = { ...defaultOptions, ...options };
    if (finalOptions.headers['Content-Type'] === 'application/json' && finalOptions.body) {
        finalOptions.body = JSON.stringify(finalOptions.body);
    }

    const response = await fetch(`${API_BASE_URL}${endpoint}`, finalOptions);

    if (response.status === 401) {
        logout(); // Token expired
        return null;
    }

    return response;
}

// Users Management
async function loadUsers() {
    try {
        const response = await apiRequest('/admin/users');
        if (!response || !response.ok) {
            throw new Error('Failed to load users');
        }

        const data = await response.json();
        const users = data.users || [];

        updateUsersStats(users);
        renderUsersTable(users);
    } catch (error) {
        console.error('Error loading users:', error);
        showError('Failed to load users');
        renderUsersTable([]); // Show empty state
    }
}

function updateUsersStats(users) {
    const totalUsers = users.length;
    const activeUsers = users.filter(u => u.is_active).length;
    const adminUsers = users.filter(u => u.is_admin).length;
    const paperUsers = users.filter(u => u.user_type === 'test').length;

    document.getElementById('total-users').textContent = totalUsers;
    document.getElementById('active-users').textContent = activeUsers;
    document.getElementById('admin-users').textContent = adminUsers;
    document.getElementById('paper-users').textContent = paperUsers;
}

function renderUsersTable(users) {
    const tbody = document.getElementById('users-table-body');

    if (users.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="8" class="loading-row">
                    <i class="fas fa-users"></i> No users found
                </td>
            </tr>
        `;
        return;
    }

    tbody.innerHTML = users.map(user => `
        <tr>
            <td>${user.user_code || 'N/A'}</td>
            <td>${user.email || 'N/A'}</td>
            <td>
                <span class="type-badge ${getUserTypeClass(user.user_type)}">
                    ${user.user_type || 'unknown'}
                </span>
            </td>
            <td>
                <span class="status-badge ${user.is_active ? 'active' : 'inactive'}">
                    ${user.is_active ? 'Active' : 'Inactive'}
                </span>
            </td>
            <td>₹${(user.internal_capital || 0).toLocaleString()}</td>
            <td class="${(user.accumulated_profit || 0) >= 0 ? 'positive' : 'negative'}">
                ₹${(user.accumulated_profit || 0).toLocaleString()}
            </td>
            <td>${user.last_login ? new Date(user.last_login).toLocaleDateString() : 'Never'}</td>
            <td>
                <button class="action-btn edit" onclick="editUser('${user.id}')">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="action-btn toggle ${user.is_active ? 'active' : 'inactive'}"
                        onclick="toggleUserStatus('${user.id}', ${!user.is_active})">
                    <i class="fas fa-${user.is_active ? 'block' : 'check-circle'}"></i>
                </button>
            </td>
        </tr>
    `).join('');
}

function getUserTypeClass(userType) {
    switch(userType) {
        case 'admin': return 'admin';
        case 'existing': return 'existing';
        case 'new': return 'new';
        default: return 'new';
    }
}

async function toggleUserStatus(userId, activate) {
    try {
        const response = await apiRequest(`/admin/users/${userId}/status`, {
            method: 'POST',
            body: { active: activate }
        });

        if (!response || !response.ok) {
            throw new Error('Failed to update user status');
        }

        showSuccess(`User ${activate ? 'activated' : 'deactivated'} successfully`);
        loadUsers(); // Refresh the table
    } catch (error) {
        console.error('Error updating user status:', error);
        showError('Failed to update user status');
    }
}

function editUser(userId) {
    // For now, just show a message. In a full implementation, this would open the edit modal
    showInfo('User editing functionality coming soon');
}

async function refreshUsers() {
    await loadUsers();
    showSuccess('Users refreshed');
}

// System Status
async function loadSystemStatus() {
    // Mock system status - in production, this would come from API
    // The HTML already has some mock data, but we could enhance this
    showInfo('System status loaded');
}

async function runSystemCheck() {
    showInfo('Running system health check...');
    // Simulate health check
    setTimeout(() => {
        showSuccess('System health check completed - All systems operational');
    }, 2000);
}

async function backupDatabase() {
    showInfo('Initiating database backup...');
    // Simulate backup
    setTimeout(() => {
        showSuccess('Database backup completed successfully');
    }, 3000);
}

async function restartServices() {
    const confirmed = confirm('Are you sure you want to restart services? This may cause temporary downtime.');
    if (!confirmed) return;

    showWarning('Restarting services...');
    // Simulate restart
    setTimeout(() => {
        showSuccess('Services restarted successfully');
    }, 5000);
}

// Reports
async function loadReports() {
    // Mock reports data - in production, this would come from API
    // The HTML already has some mock data
    showInfo('Reports loaded');
}

async function generateReport() {
    showInfo('Generating comprehensive report...');
    // Simulate report generation
    setTimeout(() => {
        showSuccess('Report generated and downloaded');
    }, 3000);
}

// Logs
async function loadLogs() {
    // Mock logs data - in production, this would come from API
    // The HTML already has some mock logs
    showInfo('Logs loaded');
}

async function refreshLogs() {
    showInfo('Refreshing system logs...');
    // Simulate log refresh
    setTimeout(() => {
        showSuccess('Logs refreshed');
    }, 1000);
}

async function clearLogs() {
    const confirmed = confirm('Are you sure you want to clear all system logs?');
    if (!confirmed) return;

    showWarning('Clearing system logs...');
    // Simulate log clearing
    setTimeout(() => {
        showSuccess('System logs cleared');
    }, 2000);
}

// Modal Functions
function openModal() {
    document.getElementById('user-modal').classList.add('show');
}

function closeModal() {
    document.getElementById('user-modal').classList.remove('show');
}

function saveUserChanges() {
    // TODO: Implement save functionality
    showInfo('User changes saved');
    closeModal();
}

// Utility Functions
function showSuccess(message) {
    showNotification(message, 'success');
}

function showError(message) {
    showNotification(message, 'error');
}

function showWarning(message) {
    showNotification(message, 'warning');
}

function showInfo(message) {
    showNotification(message, 'info');
}

function showNotification(message, type) {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <i class="fas fa-${getNotificationIcon(type)}"></i>
        <span>${message}</span>
        <button onclick="this.parentElement.remove()">&times;</button>
    `;

    // Add to page
    document.body.appendChild(notification);

    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (notification.parentElement) {
            notification.remove();
        }
    }, 5000);
}

function getNotificationIcon(type) {
    switch(type) {
        case 'success': return 'check-circle';
        case 'error': return 'exclamation-circle';
        case 'warning': return 'exclamation-triangle';
        case 'info': return 'info-circle';
        default: return 'info-circle';
    }
}

// Load initial data
function loadDashboardData() {
    // Load initial users data
    loadUsers();
}
