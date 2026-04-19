import requests
from bs4 import BeautifulSoup
import time



def scrape_pages():

    # Base URL without the page number
    base_url = ""
    start_page = 0
    end_page = 0

    for i in range(start_page, end_page + 1):
        url = f"{base_url}{i}/"
        print(f"Scraping: {url}")

        try:
            # 1. Fetch the page
            response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"})
            if response.status_code != 200:
                print(f"Skipping {i}: Status code {response.status_code}")
                continue

            # 2. Parse the HTML
            soup = BeautifulSoup(response.text, "html.parser")

            # 3. Target the content (Update 'div.content-class' to the actual CSS selector)
            content = soup.select_one("div.prose")

            if content:
                # Save to a file (appending)
                text_data = content.get_text(separator="\n", strip=True)
                with open("scraped_content.txt", "a", encoding="utf-8") as f:
                    f.write(text_data)

            # 4. Respectful delay (prevents getting blocked)
            time.sleep(1)

        except Exception as e:
            print(f"Error on page {i}: {e}")


def scrape_from_toc():
    toc_url = ""
    link_selector = ""
    paginate_selector = ""
    base_url = ""

    if not toc_url:
        print("Error: Please set 'toc_url'")
        return

    all_links = []

    def fetch_page(url):
        print(f"Fetching TOC: {url}")
        response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"})
        if response.status_code != 200:
            print(f"Failed to fetch TOC: {response.status_code}")
            return None
        return BeautifulSoup(response.text, "html.parser")

    soup = fetch_page(toc_url)

    while soup is not None:
        links = soup.select(link_selector)
        all_links.extend(links)
        print(f"Page: found {len(links)} links (total: {len(all_links)})")

        next_btn = soup.select_one(paginate_selector)
        if not next_btn:
            break

        next_href = next_btn.get("href")
        if not next_href or next_href == "javascript:void(0)":
            break

        next_url = base_url + next_href if next_href.startswith("/") else next_href
        soup = fetch_page(next_url)
        time.sleep(1)

    print(f"Total links collected: {len(all_links)}")

    for link in all_links:
        href = link.get("href")
        if not href:
            continue

        full_href = base_url.rstrip("/") + href if href.startswith("/") else href
        print(f"Scraping: {full_href}")
        try:
            page_response = requests.get(full_href, headers={"User-Agent": "Mozilla/5.0"})
            if page_response.status_code != 200:
                print(f"Skipped {full_href}: Status {page_response.status_code}")
                continue

            page_soup = BeautifulSoup(page_response.text, "html.parser")
            content = page_soup.select_one("div.chapter-content")

            if content:
                text_data = content.get_text(separator="\n", strip=True)
                with open("scraped_content.txt", "a", encoding="utf-8") as f:
                    f.write(text_data)
                print(f"  -> Saved ({len(text_data)} chars)")
            else:
                print(f"  -> No content found")

            time.sleep(1)

        except Exception as e:
            print(f"Error on {full_href}: {e}")


if __name__ == "__main__":
    # scrape_pages()
    scrape_from_toc()
