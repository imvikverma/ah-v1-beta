// Firefox Auto-Refresh Bookmarklet for AurumHarmony
// 
// INSTRUCTIONS:
// 1. Copy the entire code below (the javascript: line)
// 2. In Firefox, right-click your bookmarks toolbar → New Bookmark
// 3. Name it "AH Auto-Refresh"
// 4. Paste the code below into the "Location" field
// 5. Save
// 
// USAGE:
// Navigate to your target URL (Cloudflare Pages or GitHub)
// Click the bookmarklet to start auto-refreshing every 30 seconds
// Click again to stop

javascript:(function(){
    if(window.ahAutoRefresh){
        clearInterval(window.ahAutoRefresh);
        window.ahAutoRefresh = null;
        alert('Auto-refresh stopped');
        return;
    }
    var interval = 30; // seconds
    var count = 0;
    var startTime = Date.now();
    window.ahAutoRefresh = setInterval(function(){
        count++;
        var elapsed = Math.floor((Date.now() - startTime) / 1000);
        console.log('Auto-refresh #' + count + ' (elapsed: ' + elapsed + 's)');
        location.reload(true); // true = hard refresh (bypass cache)
    }, interval * 1000);
    alert('Auto-refresh started! Refreshing every ' + interval + ' seconds.\n\nClick bookmarklet again to stop.');
})();

