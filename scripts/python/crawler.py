import os
import sqlite3
import time
import subprocess
from urllib.parse import urlparse
from bs4 import BeautifulSoup
from ebooklib import epub
from playwright.sync_api import sync_playwright

# Persistence configuration
BASE_DIR = os.path.expanduser("~/github/knowledge")
os.makedirs(BASE_DIR, exist_ok=True)
DB_PATH = os.path.join(BASE_DIR, "novels_digest.db")

def init_db():
    """Initializes the database for multi-chapter books."""
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS books (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT UNIQUE,
                start_url TEXT,
                selector TEXT,
                next_selector TEXT,
                added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        # Schema migration: Add next_selector if it doesn't exist
        try:
            conn.execute("ALTER TABLE books ADD COLUMN next_selector TEXT")
        except sqlite3.OperationalError:
            pass # Column already exists
        conn.execute("""
            CREATE TABLE IF NOT EXISTS chapters (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                book_id INTEGER,
                url TEXT UNIQUE,
                title TEXT,
                html_content TEXT,
                chapter_order INTEGER,
                added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(book_id) REFERENCES books(id)
            )
        """)

def clean_html_content(raw_html):
    """Strips out structural navigation nodes, ads, and code scripts."""
    soup = BeautifulSoup(raw_html, "html.parser")
    garbage_selectors = [
        "script", "style", "iframe", "ins", "button", 
        ".chapter-nav", ".ads", ".sharedaddy", ".wpcnt",
        "nav", "header", "footer"
    ]
    for selector in garbage_selectors:
        for tag in soup.select(selector):
            tag.decompose()
    return str(soup)

def sync_with_calibre(book_title, epub_path):
    """Forces Calibre catalog engine to pick up binary file layout shifts."""
    print(f"Syncing '{book_title}' with Calibre library...")
    try:
        # Don't use check=True here because exit code 1 means "no results"
        search_cmd = ["calibredb", "search", f"title:\"{book_title}\""]
        result = subprocess.run(search_cmd, capture_output=True, text=True)
        book_ids = result.stdout.strip()

        if book_ids and result.returncode == 0:
            book_id = book_ids.split(',')[0]
            print(f"Updating existing Calibre Book Entry ID: {book_id}")
            add_cmd = ["calibredb", "add_format", book_id, epub_path]
            subprocess.run(add_cmd, check=True)
        else:
            print(f"Adding '{book_title}' to Calibre as a brand new catalog item...")
            add_cmd = ["calibredb", "add", epub_path]
            subprocess.run(add_cmd, check=True)
            
        print("Calibre database successfully refreshed.")
    except FileNotFoundError:
        print("\n[Warning]: 'calibredb' command utility was not found in system PATH.")
    except subprocess.CalledProcessError as e:
        stderr_msg = e.stderr if e.stderr else str(e)
        if "Another calibre program" in stderr_msg:
            print("\n[Error]: Calibre database is locked because the Calibre desktop app is open.")
            print("Please close Calibre and run the script again to sync.")
        else:
            print(f"Failed Calibre sync (Command failed): {stderr_msg}")
    except Exception as e:
        print(f"Failed Calibre sync: {e}")

def get_next_url(page, current_url, next_selector=None):
    """Extracts the 'Next' link using common selectors, avoiding 'Previous' links."""
    candidates = []
    if next_selector:
        candidates.append(page.locator(next_selector))
    else:
        # Ordered list of heuristics
        candidates = [
            page.locator("a[rel='next']"),
            page.locator("[title*='ext chapter']"), 
            page.locator("[title*='ext Chapter']"),
            page.locator("a.next_page"),
            page.locator("a.next-page"),
            page.locator("a:has-text('Next')"),
            page.locator("button:has-text('Next')"), # Added button support
            page.locator("a:has-text('下一章')"),
            page.locator("a:has-text('Next Chapter')"),
            page.locator("button:has-text('Next Chapter')")
        ]
    
    for candidate_locator in candidates:
        try:
            count = candidate_locator.count()
            for i in range(count):
                el = candidate_locator.nth(i)
                # Be more patient for SPA buttons
                if el.is_visible(timeout=10000):
                    text = el.inner_text().lower()
                    href = el.get_attribute("href")
                    
                    # Hard-exclude common 'Previous' patterns in text or href
                    if any(x in text for x in ["prev", "back", "上一章"]):
                        continue
                    if href and any(x in href.lower() for x in ["prev", "back"]):
                        continue
                        
                    if href:
                        parsed_url = urlparse(current_url)
                        base_domain = f"{parsed_url.scheme}://{parsed_url.netloc}"
                        new_url = base_domain + href if href.startswith("/") else href
                        
                        # Smart AO3 handling: Append view_adult=true to ensure content is visible
                        if "archiveofourown.org" in new_url and "view_adult=true" not in new_url:
                            base_part, *fragment = new_url.split("#")
                            sep = "&" if "?" in base_part else "?"
                            new_url = f"{base_part}{sep}view_adult=true"
                            if fragment:
                                new_url += f"#{fragment[0]}"

                        # Strip fragments for comparison
                        clean_new = new_url.split("#")[0].split("?")[0]
                        clean_current = current_url.split("#")[0].split("?")[0]
                        
                        if clean_new != clean_current:
                            print(f"  [Debug] Found Next Link: {new_url}")
                            return new_url
                    else:
                        # Handle SPA click
                        print(f"  [Debug] Found Next Button (SPA Click)")
                        old_url = page.url
                        el.click()
                        # Wait for URL to change OR some time to pass
                        try:
                            page.wait_for_url(lambda url: url != old_url, timeout=10000)
                            return page.url
                        except Exception:
                            # If URL didn't change, return anyway as it might have loaded content
                            return page.url
        except Exception:
            continue
            
    return None

def scrape_incremental(book_id, start_url, selector, next_selector=None, max_new=500):
    """Scrapes new chapters starting from the provided URL."""
    new_chapters_count = 0
    current_url = start_url
    visited_this_session = set()
    
    # Find current max order
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.execute("SELECT MAX(chapter_order) FROM chapters WHERE book_id = ?", (book_id,))
        max_order = cursor.fetchone()[0] or 0

    with sync_playwright() as p:
        browser = p.firefox.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
        )
        page = context.new_page()

        def handle_ao3_gate(page):
            """Checks for and bypasses AO3 age/tos gate in a loop to handle sequential gates."""
            for _ in range(3):  # Try up to 3 times to handle multiple sequential gates
                gate_found = False
                try:
                    # 1. Handle TOS/Consent Gate
                    # Wait briefly to see if the gate appears
                    try:
                        page.wait_for_selector("#tos_agree", timeout=3000, state="visible")
                    except Exception:
                        pass # Might not be on this page

                    tos_check = page.locator("#tos_agree")
                    data_check = page.locator("#data_processing_agree")
                    
                    if tos_check.count() > 0 and tos_check.is_visible():
                        print("  [Debug] AO3 TOS Gate detected. Accepting...")
                        tos_check.check(force=True)
                        if data_check.count() > 0:
                            data_check.check(force=True)
                        
                        accept_btn = page.locator("#accept_tos")
                        if accept_btn.count() > 0:
                            accept_btn.click(timeout=5000, force=True)
                            page.wait_for_load_state("domcontentloaded")
                            gate_found = True
                    
                    # 2. Handle Adult Content / Age Gate
                    try:
                        page.wait_for_selector("input[value='Proceed']", timeout=2000, state="visible")
                    except Exception:
                        pass

                    proceed_btn = page.locator("input[name='commit'][value='Proceed']")
                    if proceed_btn.count() > 0 and proceed_btn.is_visible():
                        print("  [Debug] AO3 Age Gate detected. Proceeding...")
                        proceed_btn.click(timeout=5000, force=True)
                        page.wait_for_load_state("domcontentloaded")
                        gate_found = True
                    
                    if not gate_found:
                        break # No gates visible, proceed to content
                    
                    print("  [Debug] Gate bypassed, waiting for content to settle...")
                    time.sleep(2) # Give the page 2 seconds to settle after a click
                except Exception as e:
                    print(f"  [Debug] AO3 Gate loop error: {e}")
                    break
        
        while current_url and new_chapters_count < max_new:
            # Smart AO3 handling: Force append view_adult=true to every URL before processing
            # Ensure it's placed before fragments (#)
            if "archiveofourown.org" in current_url and "view_adult=true" not in current_url:
                base_part, *fragment = current_url.split("#")
                sep = "&" if "?" in base_part else "?"
                current_url = f"{base_part}{sep}view_adult=true"
                if fragment:
                    current_url += f"#{fragment[0]}"

            # Infinite loop protection
            if current_url in visited_this_session:
                print(f"Loop detected at {current_url}. Stopping.")
                break
            visited_this_session.add(current_url)

            # Check if URL already exists in database
            with sqlite3.connect(DB_PATH) as conn:
                if conn.execute("SELECT 1 FROM chapters WHERE url = ?", (current_url,)).fetchone():
                    print(f"Chapter already in DB: {current_url}. Advancing to find next chapter...")
                    try:
                        # Retry logic for advancement navigation
                        max_retries = 3
                        for attempt in range(max_retries):
                            try:
                                page.goto(current_url, wait_until="domcontentloaded", timeout=60000)
                                break
                            except Exception as e:
                                if attempt < max_retries - 1:
                                    print(f"  [Warning] Timeout advancing from {current_url}, retrying ({attempt + 1}/{max_retries})...")
                                    time.sleep(5)
                                else:
                                    raise e

                        handle_ao3_gate(page)
                        
                        # Give the page more time if it's dynamic/heavy
                        try:
                            page.wait_for_load_state("networkidle", timeout=15000) 
                        except Exception:
                            print("  [Debug] Networkidle timeout (continuing anyway...)")
                        
                        next_url = get_next_url(page, current_url, next_selector)
                        
                        if not next_url:
                            # Diagnostic screenshot
                            diag_path = os.path.expanduser("~/github/knowledge/debug/ao3_debug.png")
                            os.makedirs(os.path.dirname(diag_path), exist_ok=True)
                            page.screenshot(path=diag_path)
                            print(f"  [Debug] Saved diagnostic screenshot to {diag_path}")
                            print(f"[Error]: Could not extract 'Next' URL from existing chapter: {current_url}")
                            print(f"Check if your Next selector '{next_selector if next_selector else '[Auto-Detect]'}' is still valid on this page.")
                            break
                            
                        current_url = next_url
                        continue
                    except Exception as e:
                        print(f"Could not advance from existing chapter: {e}")
                        break

            print(f"Fetching: {current_url}")
            try:
                # Retry logic for page navigation
                max_retries = 3
                for attempt in range(max_retries):
                    try:
                        page.goto(current_url, wait_until="domcontentloaded", timeout=60000)
                        break
                    except Exception as e:
                        if attempt < max_retries - 1:
                            print(f"  [Warning] Timeout fetching {current_url}, retrying ({attempt + 1}/{max_retries})...")
                            time.sleep(5)
                        else:
                            raise e

                handle_ao3_gate(page)
                page.wait_for_selector(selector, timeout=15000)
                
                page_title = page.title()
                raw_content = page.locator(selector).first.inner_html()
                pristine_html = clean_html_content(raw_content)
                
                # Preview for the first TWO new chapters of the session
                if new_chapters_count < 2:
                    text_preview = BeautifulSoup(pristine_html, "html.parser").get_text().strip()
                    print("\n" + "="*50)
                    print(f"PREVIEW (Chapter {new_chapters_count + 1}): {page_title}")
                    print("-" * 50)
                    print(text_preview[:400] + "...")
                    print("="*50)
                    confirm = input(f"\nDoes preview {new_chapters_count + 1} look correct? (y/n): ").strip().lower()
                    if confirm != 'y':
                        print("Aborting.")
                        break

                max_order += 1
                with sqlite3.connect(DB_PATH) as conn:
                    conn.execute(
                        "INSERT INTO chapters (book_id, url, title, html_content, chapter_order) VALUES (?, ?, ?, ?, ?)",
                        (book_id, current_url, page_title, pristine_html, max_order)
                    )
                
                new_chapters_count += 1
                current_url = get_next_url(page, current_url, next_selector)
                time.sleep(1.5) # Modest pacing
                
            except Exception as e:
                print(f"Error parsing {current_url}: {e}")
                break
        
        browser.close()
    return new_chapters_count

def compile_epub(book_id, book_title):
    """Generates an EPUB from stored chapters."""
    print(f"Compiling EPUB for '{book_title}'...")
    epub_filename = os.path.join(BASE_DIR, f"{book_title.replace(' ', '_')}.epub")
    
    book = epub.EpubBook()
    book.set_title(book_title)
    book.set_language("en")
    book.add_author("Crawler Pipeline")

    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.execute(
            "SELECT title, html_content, chapter_order FROM chapters WHERE book_id = ? ORDER BY chapter_order ASC",
            (book_id,)
        )
        rows = cursor.fetchall()

    if not rows:
        print("No chapters found to compile.")
        return None

    chapters = []
    for title, html_content, order in rows:
        filename = f"chap_{order}.xhtml"
        chapter = epub.EpubHtml(title=title, file_name=filename, lang="en")
        chapter.content = f"<h1>{title}</h1>{html_content}"
        book.add_item(chapter)
        chapters.append(chapter)

    book.toc = tuple(chapters)
    book.spine = ["nav"] + chapters
    book.add_item(epub.EpubNcx())
    book.add_item(epub.EpubNav())
    
    if os.path.exists(epub_filename):
        os.remove(epub_filename)
    
    epub.write_epub(epub_filename, book)
    print(f"EPUB created: {epub_filename}")
    return epub_filename

def main():
    init_db()
    print("=== Multi-Chapter Novel Scraper & Digest ===")
    
    # List existing books
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.execute("SELECT id, title FROM books")
        existing_books = cursor.fetchall()

    book_id = None
    if existing_books:
        print("\nExisting Books:")
        for idx, (bid, title) in enumerate(existing_books, 1):
            print(f"{idx}. {title}")
        print(f"{len(existing_books) + 1}. [Add New Book]")
        
        choice = input("\nSelect a book or add new (number): ").strip()
        if choice.isdigit():
            choice_idx = int(choice)
            if 1 <= choice_idx <= len(existing_books):
                book_id, book_title = existing_books[choice_idx - 1]
            elif choice_idx == len(existing_books) + 1:
                book_id = None
    
    if not book_id:
        book_title = input("Enter new Book Title: ").strip()
        start_url = input("Enter the STARTING chapter URL: ").strip()
        selector = input("Enter the CSS selector for the content block: ").strip()
        next_selector = input("Enter CSS selector for 'Next' link (optional, press Enter for auto): ").strip()
        
        with sqlite3.connect(DB_PATH) as conn:
            cursor = conn.execute(
                "INSERT INTO books (title, start_url, selector, next_selector) VALUES (?, ?, ?, ?)",
                (book_title, start_url, selector, next_selector)
            )
            book_id = cursor.lastrowid
    else:
        # For existing books, find the last URL to resume
        with sqlite3.connect(DB_PATH) as conn:
            res = conn.execute(
                "SELECT chapters.url, books.selector, books.next_selector, books.title "
                "FROM chapters JOIN books ON chapters.book_id = books.id "
                "WHERE book_id = ? ORDER BY chapter_order DESC LIMIT 1", 
                (book_id,)
            ).fetchone()
            if res:
                last_url, selector, next_selector, book_title = res
                start_url = last_url
            else:
                # Book exists but no chapters yet
                res = conn.execute("SELECT start_url, selector, next_selector, title FROM books WHERE id = ?", (book_id,)).fetchone()
                start_url, selector, next_selector, book_title = res
        
        print(f"\nCurrent Selectors for '{book_title}':")
        print(f"  Content: {selector}")
        print(f"  Next:    {next_selector if next_selector else '[Auto-Detect]'}")
        
        change = input("\nUpdate selectors? (y/n): ").strip().lower()
        if change == 'y':
            new_selector = input(f"Enter new content selector (Enter to keep '{selector}'): ").strip()
            if new_selector: selector = new_selector
            
            new_next = input(f"Enter new Next selector (Enter to keep '{next_selector}'): ").strip()
            if new_next: next_selector = new_next
            
            with sqlite3.connect(DB_PATH) as conn:
                conn.execute("UPDATE books SET selector = ?, next_selector = ? WHERE id = ?", (selector, next_selector, book_id))
                print("Selectors updated.")

    max_new = input("How many NEW chapters to fetch? (Default 10): ").strip()
    max_new = int(max_new) if max_new.isdigit() else 10
    
    new_count = scrape_incremental(book_id, start_url, selector, next_selector, max_new)
    
    if new_count > 0:
        epub_path = compile_epub(book_id, book_title)
        if epub_path:
            sync_with_calibre(book_title, epub_path)
    else:
        print("No new chapters fetched. EPUB remains unchanged.")

if __name__ == "__main__":
    main()
