import os
import requests
from dotenv import load_dotenv

load_dotenv()

def get_access_token(request_token):
    api_key = os.getenv("KOTAK_NEO_API_KEY")
    api_secret = os.getenv("KOTAK_NEO_API_SECRET")
    url = f"https://api.kotakneo.com/v1/access-token?api_key={api_key}&request_token={request_token}"
    data = {"api_secret": api_secret}
    response = requests.post(url, json=data)
    return response
