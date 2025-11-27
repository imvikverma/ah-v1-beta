# APIs_and_Integrations/Regulatory_Update_Workflow.py
import websocket
import json
import threading
import time

class RegulatoryUpdateWorkflow:
    def __init__(self, hyperledger_client=None):
        self.hyperledger_client = hyperledger_client
        self.nse_ws_url = "wss://www.nseindia.com/api/real-time-data"
        self.bse_ws_url = "wss://www.bseindia.com/api/real-time-data"

    def on_message(self, ws, message):
        data = json.loads(message)
        # Filter only regulatory updates (lot size, margin, expiry changes)
        if any(k in data for k in ["lot_size", "margin", "expiry"]):
            update = {
                "source": "NSE" if "nse" in ws.url else "BSE",
                "data": data,
                "timestamp": int(time.time())
            }
            print(f"Regulatory Update: {update}")
            if self.hyperledger_client:
                self.hyperledger_client.log_regulatory_update(update)

    def on_error(self, ws, error):
        print(f"WebSocket Error: {error}")

    def on_open(self, ws):
        print(f"Connected to {ws.url}")

    def start(self):
        threading.Thread(target=self._connect_nse, daemon=True).start()
        threading.Thread(target=self._connect_bse, daemon=True).start()

    def _connect_nse(self):
        ws = websocket.WebSocketApp(
            self.nse_ws_url,
            on_open=self.on_open,
            on_message=self.on_message,
            on_error=self.on_error
        )
        ws.run_forever()

    def _connect_bse(self):
        time.sleep(2)  # stagger connections
        ws = websocket.WebSocketApp(
            self.bse_ws_url,
            on_open=self.on_open,
            on_message=self.on_message,
            on_error=self.on_error
        )
        ws.run_forever()

# Global instance
regulatory_workflow = RegulatoryUpdateWorkflow()