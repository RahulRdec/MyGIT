from bs4 import BeautifulSoup
import requests
#url = input("Enter a website to extract the URL's from: ")
r  = requests.get("http://dpctctst01.uhc.com:2053/prodhealthcheck")
data = r.text
link = BeautifulSoup(data)
print(link)
