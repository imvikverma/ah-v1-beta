# APIs_and_Integrations/Realtime_Data_Fetching.py
import websocket
import json
import threading
import time

class RealtimeDataFetcher:
    def __init__(self, hyperledger_client=None):
        self.hyperledger_client = hyperledger_client
        self.ws_urls = {
            "NIFTY50": "wss://www.nseindia.com/api/option-chain-indices?symbol=NIFTY",
            "BANKNIFTY": "wss://www.nseindia.com/api/option-chain-indices?symbol=BANKNIFTY",
            "SENSEX": "wss://pushstream.bseindia.com/"
        }

    def on_message(self, ws, message):
        try:
            data = json.loads(message)
            filtered = {
                "index": data.get("underlying", "UNKNOWN"),
                "price": data.get("lastPrice"),
                "oi": data.get("openInterest"),
                "volume": data.get("totalTradedVolume"),
                "timestamp": int(time.time())
            }
            print(f"Live Data: {filtered['index']} @ ₹{filtered['price']}")
            if self.hyperledger_client:
                self.hyperledger_client.log_market_data(filtered)
        except:
            pass

    def on_error(self, ws, error):
        print(f"Realtime WS Error: {error}")

    def on_open(self, ws):
        print(f"Realtime feed connected: {ws.url}")

    def start_all(self):
        for symbol, url in self.ws_urls.items():
            threading.Thread(
                target=self._connect,
                args=(url, symbol),
                daemon=True
            ).start()

    def _connect(self, url: str, symbol: str):
        ws = websocket.WebSocketApp(
            url,
            on_open=self.on_open,
            on_message=self.on_message,
            on_error=self.on_error
        )
        ws.run_forever()

# Global instance
realtime_fetcher = RealtimeDataFetcher()