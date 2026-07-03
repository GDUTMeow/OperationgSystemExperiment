import httpx

for i in range(10):
    resp = httpx.get("http://kylinos.internal")
    print(f"[{resp.status_code}] {resp.text.strip()}")