import os
import re
import sys
import time
from urllib.parse import urlparse
from bs4 import BeautifulSoup
from ebooklib import epub
from playwright.sync_api import sync_playwright

def clean_html_content(raw_html):
    """Strips out structural navigation nodes, ads, and code scripts."""
    soup = BeautifulSoup(raw_html, "html.parser")
    garbage_selectors = [
        "script", "style", "iframe", "ins", "button", 
        ".chapter-nav", ".ads", ".sharedaddy", ".wpcnt"
    ]
    for selector in garbage_selectors:
        for tag in soup.select(selector):
            tag.decompose()
    return str(soup)

def interactive_scraper():
    print("=== Dynamic Multi-Chapter Web Novel Downloader ===")
    start_url = input("Enter the starting chapter URL: ").strip()
    content_selector = input("Enter the CSS selector for the text block: ").strip()
    output_filename = input("Enter desired output filename (e.g., novel.epub): ").strip()
    
    if not output_filename.endswith(".epub"):
        output_filename += ".epub"

    book = epub.EpubBook()
    book.set_language("en")
    chapters = []
    
    current_url = start_url
    chapter_count = 0
    
    with sync_playwright() as p:
        browser = p.firefox.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0"
        )
        page = context.new_page()
        
        # --- PHASE 1: TWO-CHAPTER PREVIEW VALIDATION RUN ---
        for preview_idx in range(1, 3):
            chapter_count += 1
            print(f"\n[Preview Run] Fetching Chapter {preview_idx}: {current_url}")
            
            try:
                page.goto(current_url, wait_until="domcontentloaded")
                page.wait_for_selector(content_selector, timeout=15000)
                
                page_title = page.title()
                raw_content = page.locator(content_selector).first.inner_html()
                pristine_html = clean_html_content(raw_content)
                
                preview_text = BeautifulSoup(pristine_html, "html.parser").get_text().strip()
                
                print("\n" + "="*50)
                print(f"DEBUG PREVIEW FOR CHAPTER {preview_idx}: '{page_title}'")
                print("="*50)
                print(preview_text[:350] + "\n...")
                print("="*50)
                
                # Setup basic book structure metadata on first pass
                if preview_idx == 1:
                    book.set_title(page_title.split("Chapter")[0].strip(" -"))
                
                # Append chapter to memory data structure array lists
                filename = f"chapter_{chapter_count}.xhtml"
                epub_chapter = epub.EpubHtml(title=page_title, file_name=filename, lang="en")
                epub_chapter.content = f"<h1>{page_title}</h1>\n{pristine_html}"
                book.add_item(epub_chapter)
                chapters.append(epub_chapter)
                
                # Handle SPA pagination transitions securely
                if preview_idx == 1:
                    # Look for links or the custom interactive title element
                    next_element = page.locator("a:has-text('Next'), a[rel='next'], [title*='ext chapter']").first
                    
                    if next_element.is_visible():
                        href = next_element.get_attribute("href")
                        if href:
                            parsed_url = urlparse(current_url)
                            base_domain = f"{parsed_url.scheme}://{parsed_url.netloc}"
                            current_url = base_domain + href if href.startswith("/") else href
                        else:
                            print("SPA Navigation element triggered. Awaiting dynamic routing address swap...")
                            old_url = page.url
                            next_element.click()
                            
                            # CRITICAL SAFETY: Wait for the address state text string to change values completely
                            page.wait_for_url(lambda url: url != old_url, timeout=10000)
                            current_url = page.url
                    else:
                        print("Could not locate a second preview chapter link node.")
                        current_url = None
                        break
                        
            except Exception as e:
                print(f"Error during preview parsing pipeline: {e}")
                browser.close()
                return
        
        # Verify the two-chapter batch run with the user before committing the whole loop
        confirm = input("\nDo BOTH chapter previews look structured correctly? (y/n): ").strip().lower()
        if confirm != 'y':
            print("Aborting download.")
            browser.close()
            return
            
        max_input = input("How many total chapters do you want to download? (Default 500): ").strip()
        max_chapters = int(max_input) if max_input.isdigit() else 500

        # --- PHASE 2: AUTOMATED BATCH PROCESSING LOOP ---
        # Get the next target link from Chapter 2 to continue the loop
        try:
            next_element = page.locator("a:has-text('Next'), a[rel='next'], [title*='ext chapter']").first
            if next_element.is_visible():
                href = next_element.get_attribute("href")
                if href:
                    parsed_url = urlparse(current_url)
                    base_domain = f"{parsed_url.scheme}://{parsed_url.netloc}"
                    current_url = base_domain + href if href.startswith("/") else href
                else:
                    old_url = page.url
                    next_element.click()
                    page.wait_for_url(lambda url: url != old_url, timeout=10000)
                    current_url = page.url
            else:
                current_url = None
        except Exception:
            current_url = None

        while current_url and chapter_count < max_chapters:
            chapter_count += 1
            print(f"[{chapter_count}/{max_chapters}] Fetching: {current_url}")
            
            try:
                page.goto(current_url, wait_until="domcontentloaded")
                page.wait_for_selector(content_selector, timeout=15000)
                
                page_title = page.title()
                raw_content = page.locator(content_selector).first.inner_html()
                pristine_html = clean_html_content(raw_content)
                
                filename = f"chapter_{chapter_count}.xhtml"
                epub_chapter = epub.EpubHtml(title=page_title, file_name=filename, lang="en")
                epub_chapter.content = f"<h1>{page_title}</h1>\n{pristine_html}"
                book.add_item(epub_chapter)
                chapters.append(epub_chapter)
                
                # Advance layout pagination step
                next_element = page.locator("a:has-text('Next'), a[rel='next'], [title*='ext chapter']").first
                if next_element.is_visible():
                    href = next_element.get_attribute("href")
                    if href:
                        parsed_url = urlparse(current_url)
                        base_domain = f"{parsed_url.scheme}://{parsed_url.netloc}"
                        current_url = base_domain + href if href.startswith("/") else href
                    else:
                        old_url = page.url
                        next_element.click()
                        page.wait_for_url(lambda url: url != old_url, timeout=10000)
                        current_url = page.url
                else:
                    print("No explicit 'Next' element found. Compilation ending.")
                    current_url = None
                    
            except Exception as e:
                print(f"Error parsing chapter {chapter_count}: {e}")
                break
                
            time.sleep(1.5) # Anti-throttle pacing step
            
        browser.close()

    # --- PHASE 3: FILE GENERATION ---
    if not chapters:
        print("No content compiled.")
        return

    book.toc = tuple(chapters)
    book.spine = ["nav"] + chapters
    book.add_item(epub.EpubNcx())
    book.add_item(epub.EpubNav())
    
    epub.write_epub(output_filename, book)
    print(f"\n🎉 Done! Pure EPUB compiled successfully: '{output_filename}'")

if __name__ == "__main__":
    interactive_scraper()