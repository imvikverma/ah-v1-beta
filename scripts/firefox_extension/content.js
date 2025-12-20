/**
 * Content script for AurumHarmony Auto-Refresh Extension
 * Injected into all pages to enable hard refresh functionality
 */

// Listen for refresh commands from background script
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'hardRefresh') {
    // Perform hard refresh (bypass cache)
    window.location.reload(true);
    sendResponse({ success: true });
  }
  return false;
});

// Expose refresh function to page context if needed
if (typeof window !== 'undefined') {
  window.aurumHarmonyRefresh = function() {
    window.location.reload(true);
  };
}

