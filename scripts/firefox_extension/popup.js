/**
 * Popup script for AurumHarmony Auto-Refresh Extension
 */

// DOM elements
const statusText = document.getElementById('statusText');
const intervalText = document.getElementById('intervalText');
const tabsText = document.getElementById('tabsText');
const startBtn = document.getElementById('startBtn');
const stopBtn = document.getElementById('stopBtn');
const refreshBtn = document.getElementById('refreshBtn');
const intervalInput = document.getElementById('intervalInput');

// Update status display
async function updateStatus() {
  try {
    const response = await browser.runtime.sendMessage({ action: 'getStatus' });
    
    if (response.enabled) {
      statusText.textContent = 'Running';
      statusText.className = 'status-value enabled';
      startBtn.disabled = true;
      stopBtn.disabled = false;
    } else {
      statusText.textContent = 'Stopped';
      statusText.className = 'status-value disabled';
      startBtn.disabled = false;
      stopBtn.disabled = true;
    }
    
    intervalText.textContent = `${response.interval}s`;
    tabsText.textContent = response.monitoredCount || 0;
  } catch (error) {
    console.error('Failed to get status:', error);
    statusText.textContent = 'Error';
    statusText.className = 'status-value disabled';
  }
}

// Load interval from storage
async function loadInterval() {
  try {
    const result = await browser.storage.local.get(['refresh_interval']);
    if (result.refresh_interval) {
      intervalInput.value = result.refresh_interval;
    }
  } catch (error) {
    console.error('Failed to load interval:', error);
  }
}

// Save interval to storage
async function saveInterval() {
  const interval = parseInt(intervalInput.value) || 30;
  if (interval < 10) {
    intervalInput.value = 10;
    return;
  }
  if (interval > 300) {
    intervalInput.value = 300;
    return;
  }
  
  try {
    await browser.storage.local.set({ refresh_interval: interval });
    await browser.runtime.sendMessage({ action: 'stop' });
    await browser.runtime.sendMessage({ action: 'start' });
    updateStatus();
  } catch (error) {
    console.error('Failed to save interval:', error);
  }
}

// Event listeners
startBtn.addEventListener('click', async () => {
  try {
    await browser.runtime.sendMessage({ action: 'start' });
    updateStatus();
  } catch (error) {
    console.error('Failed to start:', error);
    alert('Failed to start auto-refresh. Check console for details.');
  }
});

stopBtn.addEventListener('click', async () => {
  try {
    await browser.runtime.sendMessage({ action: 'stop' });
    updateStatus();
  } catch (error) {
    console.error('Failed to stop:', error);
  }
});

refreshBtn.addEventListener('click', async () => {
  try {
    await browser.runtime.sendMessage({ action: 'refresh' });
    refreshBtn.textContent = '✓ Refreshed';
    setTimeout(() => {
      refreshBtn.textContent = '🔄 Refresh Now';
    }, 2000);
  } catch (error) {
    console.error('Failed to refresh:', error);
    alert('Failed to refresh tabs. Check console for details.');
  }
});

intervalInput.addEventListener('change', saveInterval);
intervalInput.addEventListener('blur', saveInterval);

// Initialize
loadInterval();
updateStatus();
setInterval(updateStatus, 2000); // Update every 2 seconds

