/**
 * Background script for AurumHarmony Auto-Refresh Extension
 * Handles tab refresh commands and cross-origin tab management
 */

// Default monitored URLs
const DEFAULT_TABS = [
  {
    id: 'cloudflare-pages',
    label: 'Cloudflare Pages',
    url: 'https://ah.saffronbolt.in'
  },
  {
    id: 'cloudflare-dashboard',
    label: 'Cloudflare Dashboard',
    url: 'https://dash.cloudflare.com/e75d70dfd45bd465d93950e54cd264bd/pages/view/ah-v1-beta'
  },
  {
    id: 'github',
    label: 'GitHub Repository',
    url: 'https://github.com/imvikverma/ah-v1-beta'
  }
];

// Storage keys
const STORAGE_KEYS = {
  TABS: 'monitored_tabs',
  INTERVAL: 'refresh_interval',
  ENABLED: 'auto_refresh_enabled'
};

// Default refresh interval (30 seconds)
const DEFAULT_INTERVAL = 30;

// State
let refreshInterval = null;
let monitoredTabs = new Map(); // tabId -> { url, label, lastRefresh }

/**
 * Initialize extension
 */
async function init() {
  // Load saved settings
  const result = await browser.storage.local.get([
    STORAGE_KEYS.TABS,
    STORAGE_KEYS.INTERVAL,
    STORAGE_KEYS.ENABLED
  ]);
  
  // Set defaults if not present
  if (!result[STORAGE_KEYS.TABS]) {
    await browser.storage.local.set({ [STORAGE_KEYS.TABS]: DEFAULT_TABS });
  }
  
  if (!result[STORAGE_KEYS.INTERVAL]) {
    await browser.storage.local.set({ [STORAGE_KEYS.INTERVAL]: DEFAULT_INTERVAL });
  }
  
  // Start auto-refresh if enabled
  if (result[STORAGE_KEYS.ENABLED]) {
    startAutoRefresh();
  }
}

/**
 * Start auto-refresh
 */
async function startAutoRefresh() {
  if (refreshInterval) {
    return; // Already running
  }
  
  const result = await browser.storage.local.get([STORAGE_KEYS.INTERVAL, STORAGE_KEYS.TABS]);
  const interval = result[STORAGE_KEYS.INTERVAL] || DEFAULT_INTERVAL;
  const tabs = result[STORAGE_KEYS.TABS] || DEFAULT_TABS;
  
  // Open all monitored tabs if not already open
  await openMonitoredTabs(tabs);
  
  // Start refresh interval
  refreshInterval = setInterval(() => {
    refreshAllTabs(tabs);
  }, interval * 1000);
  
  // Save enabled state
  await browser.storage.local.set({ [STORAGE_KEYS.ENABLED]: true });
  
  console.log(`[AurumHarmony] Auto-refresh started (interval: ${interval}s)`);
}

/**
 * Stop auto-refresh
 */
async function stopAutoRefresh() {
  if (refreshInterval) {
    clearInterval(refreshInterval);
    refreshInterval = null;
  }
  
  await browser.storage.local.set({ [STORAGE_KEYS.ENABLED]: false });
  console.log('[AurumHarmony] Auto-refresh stopped');
}

/**
 * Open all monitored tabs
 */
async function openMonitoredTabs(tabs) {
  const existingTabs = await browser.tabs.query({});
  const existingUrls = new Set(existingTabs.map(t => t.url));
  
  for (const tabConfig of tabs) {
    // Check if tab is already open
    const existingTab = existingTabs.find(t => t.url === tabConfig.url);
    
    if (!existingTab) {
      // Open new tab
      try {
        const tab = await browser.tabs.create({
          url: tabConfig.url,
          active: false
        });
        monitoredTabs.set(tab.id, {
          url: tabConfig.url,
          label: tabConfig.label,
          lastRefresh: Date.now()
        });
      } catch (error) {
        console.error(`[AurumHarmony] Failed to open tab ${tabConfig.url}:`, error);
      }
    } else {
      // Track existing tab
      monitoredTabs.set(existingTab.id, {
        url: tabConfig.url,
        label: tabConfig.label,
        lastRefresh: Date.now()
      });
    }
  }
}

/**
 * Refresh all monitored tabs
 */
async function refreshAllTabs(tabs) {
  const tabIds = Array.from(monitoredTabs.keys());
  
  for (const tabId of tabIds) {
    try {
      // Check if tab still exists
      const tab = await browser.tabs.get(tabId);
      
      if (tab && !tab.discarded) {
        // Reload the tab (hard refresh)
        await browser.tabs.reload(tabId, { bypassCache: true });
        
        // Update last refresh time
        const tabInfo = monitoredTabs.get(tabId);
        if (tabInfo) {
          tabInfo.lastRefresh = Date.now();
        }
        
        console.log(`[AurumHarmony] Refreshed tab: ${tabInfo?.label || tab.url}`);
      }
    } catch (error) {
      // Tab might have been closed, remove from monitoring
      monitoredTabs.delete(tabId);
      console.log(`[AurumHarmony] Tab ${tabId} no longer exists, removed from monitoring`);
    }
  }
}

/**
 * Hard refresh a specific tab
 */
async function hardRefreshTab(tabId) {
  try {
    await browser.tabs.reload(tabId, { bypassCache: true });
    console.log(`[AurumHarmony] Hard refreshed tab ${tabId}`);
  } catch (error) {
    console.error(`[AurumHarmony] Failed to refresh tab ${tabId}:`, error);
  }
}

/**
 * Handle messages from popup/content scripts
 */
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message.action) {
    case 'start':
      startAutoRefresh().then(() => sendResponse({ success: true }));
      return true; // Async response
      
    case 'stop':
      stopAutoRefresh().then(() => sendResponse({ success: true }));
      return true;
      
    case 'refresh':
      refreshAllTabs().then(() => sendResponse({ success: true }));
      return true;
      
    case 'refreshTab':
      hardRefreshTab(message.tabId).then(() => sendResponse({ success: true }));
      return true;
      
    case 'getStatus':
      browser.storage.local.get([STORAGE_KEYS.INTERVAL]).then(result => {
        sendResponse({
          enabled: refreshInterval !== null,
          interval: result[STORAGE_KEYS.INTERVAL] || DEFAULT_INTERVAL,
          monitoredCount: monitoredTabs.size
        });
      });
      return true; // Async response
      
    case 'getTabs':
      sendResponse({ tabs: Array.from(monitoredTabs.entries()) });
      return false;
      
    default:
      sendResponse({ error: 'Unknown action' });
      return false;
  }
});

/**
 * Handle tab removal
 */
browser.tabs.onRemoved.addListener((tabId) => {
  if (monitoredTabs.has(tabId)) {
    monitoredTabs.delete(tabId);
    console.log(`[AurumHarmony] Tab ${tabId} closed, removed from monitoring`);
  }
});

/**
 * Handle tab updates (URL changes)
 */
browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && monitoredTabs.has(tabId)) {
    const tabInfo = monitoredTabs.get(tabId);
    tabInfo.lastRefresh = Date.now();
  }
});

// Initialize on startup
init();

