from flask import Flask, request, jsonify
from flask_cors import CORS
import yt_dlp
import os
import time
import random

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return "Power Smart Python Extractor is Running"

def extract_with_strategy(video_url):
    cookie_file = os.path.join(os.path.dirname(__file__), 'cookies.txt')
    has_cookies = os.path.exists(cookie_file)
    
    # The PO Token provided by the user
    # Note: PO Tokens are usually bound to a session/client. 
    # Providing it for multiple clients increases the chance of a match.
    po_token = 'CgtPRDJlUFVKbmd4TSii79TKBjIKCgJQSxIEGgAgDGLfAgrcAjE0LllUPVFodXdvOFB6OUVkSHphMjI4VXBKbWsxX3lFT2xqN3NkRnBpcVBVZnZIN3hTaGcwZE1JUkgtMzRUY2VYSlFEcXBnV0J0X0haOWhLeVpTc2IzM1JNWU5GX0dEZjZOREpBdzRxQnpjQzNDVkFmTGRHQmJ2WmdTVzdPZl8yaHF1UnROVUNKTjRUYzZxeVVBd1FEOXNSMmMwR3NyTk15Y1F5TDdWdzl0RThCbktrV2J1TDRGdUFOcnRIWFFab0JObUxYQ09qTWY2aC1QTUFQc3haTTQ4WWxBZGFkLUVZSEJNdUJKYzlIamNYY1lCV1ZxTGY3TU5lX0YyN0tGQXBlRVQwaWJYQUhtbjZVVTgtYkJSNmxLUTNKaDViS1ZGakp2Z1RoZGlMNnlfY0xLdkZncmJfTjg5LUFOcHY3Y3J4cEluQlJweEw4QzAzcFpTZDk5eXRJeGpZeUplUQ%3D%3D'

    # Common options for all strategies
    base_opts = {
        'format': 'bestaudio/best',
        'quiet': True,
        'noplaylist': True,
        'extract_flat': False,
        'remote_components': ['ejs:github'],
        'js_runtimes': {'node': {}},
        # Randomized user agent for variety
        'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    }

    # Strategy 1: Embedded & Music Clients (Resilient to PO Token)
    s1_opts = {**base_opts, 'extractor_args': {
        'youtube': {
            'player_client': ['web_embedded', 'tv_embedded', 'web_music'],
            'po_token': f'web_music.gvs+{po_token}'
        }
    }}

    # Strategy 2: Mobile/Native clients without cookies
    s2_opts = {**base_opts, 'extractor_args': {
        'youtube': {
            'player_client': ['ios', 'android'],
            'skip': ['configs', 'webpage']
        }
    }}

    # Strategy 3: Web Clients with Cookies AND PO Token (Strongest for logged-in user simulation)
    s3_opts = {**base_opts, 'extractor_args': {
        'youtube': {
            'player_client': ['web', 'mweb', 'web_creator'],
            'po_token': f'mweb.gvs+{po_token},web.gvs+{po_token}'
        }
    }}
    if has_cookies:
        s3_opts['cookiefile'] = cookie_file
        print(f"Logging: Using cookies from {cookie_file}")
    else:
        print("Logging: No cookies.txt found in root directory")

    strategies = [
        ("Embedded/Music", s1_opts),
        ("Native", s2_opts),
        ("Web/Cookies+PO", s3_opts)
    ]

    errors = []
    for name, opts in strategies:
        try:
            # Small random sleep to mimic human timing
            time.sleep(random.uniform(0.5, 1.5))
            with yt_dlp.YoutubeDL(opts) as ydl:
                print(f"Logging: Attempting {name} strategy...")
                return ydl.extract_info(video_url, download=False)
        except Exception as e:
            errors.append(f"{name} failed: {str(e)}")

    raise Exception(" | ".join(errors))

@app.route('/extract', methods=['GET'])
def extract_audio():
    video_id = request.args.get('id')
    if not video_id:
        return jsonify({"error": "Missing video ID"}), 400

    video_url = f"https://www.youtube.com/watch?v={video_id}"
    print(f"Logging: Incoming request for ID {video_id}")
    
    try:
        info = extract_with_strategy(video_url)
        return jsonify({
            "stream_url": info.get('url'),
            "title": info.get('title'),
            "artist": info.get('uploader'),
            "duration": info.get('duration'),
            "thumbnail": info.get('thumbnail'),
        })
    except Exception as e:
        print(f"Extraction Error for {video_id}: {str(e)}")
        # Check if the error is specifically the "bot" error to give the user a hint
        if "confirm you're not a bot" in str(e):
             return jsonify({
                 "error": "YouTube Bot Detection active. Please re-export your cookies.txt and ensure they are fresh.",
                 "details": str(e)
             }), 500
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
