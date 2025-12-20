import requests

api_key = "d7bcfc9e4a374ade8450802069a36dfd"
request_token = "d1e01b98ecc249e8b889e27e682a49dd1530186681"
api_secret = "92249d8032a74a60b37705a3345286b1"

url = f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}&request_token={request_token}"
data = {"api_secret": api_secret}
response = requests.post(url, json=data)

if response.status_code == 200:
    print("Access Token:", response.json().get("access_token"))
else:
    print("Error:", response.status_code, response.text)