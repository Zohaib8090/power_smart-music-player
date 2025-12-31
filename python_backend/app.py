from flask import Flask, request, jsonify
from flask_cors import CORS
import yt_dlp
import os

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return "Power Smart Python Extractor is Running"

def extract_with_strategy(video_url):
    cookie_file = os.path.join(os.path.dirname(__file__), 'cookies.txt')
    has_cookies = os.path.exists(cookie_file)

    # Strategy 1: Native App Clients (Generally bypasses PO Token and Signature hurdles)
    # Note: These clients do NOT support cookies in yt-dlp, so we run them clean.
    s1_opts = {
        'format': 'bestaudio/best',
        'quiet': True,
        'noplaylist': True,
        'extract_flat': False,
        'extractor_args': {
            'youtube': {
                'player_client': ['ios', 'android'],
                'skip': ['configs', 'webpage']
            }
        },
        'remote_components': ['ejs:github'],
    }

    # Strategy 2: Web Clients with Cookies (Best for age-restricted or private content)
    s2_opts = {
        'format': 'bestaudio/best',
        'quiet': True,
        'noplaylist': True,
        'extract_flat': False,
        'extractor_args': {
            'youtube': {
                'player_client': ['web', 'mweb', 'web_creator'],
            }
        },
        'remote_components': ['ejs:github'],
    }
    if has_cookies:
        s2_opts['cookiefile'] = cookie_file

    errors = []

    # Attempt Strategy 1 (Native App) first - currently the most reliable for general extraction
    try:
        with yt_dlp.YoutubeDL(s1_opts) as ydl:
            return ydl.extract_info(video_url, download=False)
    except Exception as e:
        errors.append(f"Strategy 1 (Native) failed: {str(e)}")

    # Attempt Strategy 2 (Web/Cookies) as fallback
    try:
        with yt_dlp.YoutubeDL(s2_opts) as ydl:
            return ydl.extract_info(video_url, download=False)
    except Exception as e:
        errors.append(f"Strategy 2 (Web) failed: {str(e)}")

    raise Exception(" | ".join(errors))

@app.route('/extract', methods=['GET'])
def extract_audio():
    video_id = request.args.get('id')
    if not video_id:
        return jsonify({"error": "Missing video ID"}), 400

    video_url = f"https://www.youtube.com/watch?v={video_id}"
    
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
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
