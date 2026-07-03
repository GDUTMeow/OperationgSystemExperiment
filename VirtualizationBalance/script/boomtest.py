import httpx
from bs4 import BeautifulSoup

URL = "http://kylinos.internal/index.php"

def find_hostname(html: str) -> str:
    soup = BeautifulSoup(html, "html.parser")
    trs = soup.find_all("table")[1].find_all("tr")
    for tr in trs:
        property = tr.find("td", class_="e")
        value = tr.find("td", class_="v")
        if property and property.text.strip() == "System":
            hostname = value.text.strip().split()[1]
            return hostname
    return "Unknown"

for i in range(10):
    resp = httpx.get(URL)
    hostname = find_hostname(resp.text)
    print(f"[{resp.status_code}] {hostname}")