import websocket

def on_message(ws, message):
    print(f"Real-time data: {message}")

ws = websocket.WebSocketApp("wss://nseindia.com/realtime", on_message=on_message)
ws.run_forever()