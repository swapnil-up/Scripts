import requests
from bs4 import BeautifulSoup
import time

# Base URL without the page number
base_url = ""
start_page = 0
end_page = 0

def scrape_pages():
    for i in range(start_page, end_page + 1):
        url = f"{base_url}{i}/"
        print(f"Scraping: {url}")
        
        try:
            # 1. Fetch the page
            response = requests.get(url, headers={'User-Agent': 'Mozilla/5.0'})
            if response.status_code != 200:
                print(f"Skipping {i}: Status code {response.status_code}")
                continue
            
            # 2. Parse the HTML
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # 3. Target the content (Update 'div.content-class' to the actual CSS selector)
            content = soup.select_one('div.prose') 
            
            if content:
                # Save to a file (appending)
                text_data = content.get_text(separator='\n', strip=True)
                with open("scraped_content.txt", "a", encoding="utf-8") as f:
                    f.write(text_data)
            
            # 4. Respectful delay (prevents getting blocked)
            time.sleep(1) 
            
        except Exception as e:
            print(f"Error on page {i}: {e}")

if __name__ == "__main__":
    scrape_pages()