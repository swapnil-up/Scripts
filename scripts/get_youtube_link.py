from youtubesearchpython import VideosSearch

def get_youtube_link(song_name, artist_name):
    # Combine song name and artist for search query
    query = f"{song_name} {artist_name}"
    search = VideosSearch(query, limit=1)  # Fetch the top result
    results = search.result()

    if results["result"]:
        # Extract video URL from the top search result
        video_url = results["result"][0]["link"]
        return video_url
    else:
        return None

if __name__ == "__main__":
    # Example input
    song_name = "kiss me more"
    artist_name = "SZA"

    # Fetch YouTube link
    url = get_youtube_link(song_name, artist_name)
    if url:
        print(f"Video URL: {url}")
    else:
        print("No results found!")

