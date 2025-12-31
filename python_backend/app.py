from flask import Flask, request, jsonify
from flask_cors import CORS
import yt_dlp
import os

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return "Power Smart Python Extractor is Running"

@app.route('/extract', methods=['GET'])
def extract_audio():
    video_id = request.args.get('id')
    if not video_id:
        return jsonify({"error": "Missing video ID"}), 400

    video_url = f"https://www.youtube.com/watch?v={video_id}"
    
    ydl_opts = {
        'format': 'bestaudio/best',
        'quiet': True,
        'noplaylist': True,
        'extract_flat': False,
        # Use iOS/Android clients to bypass PO Token and Signature hurdles
        'extractor_args': {
            'youtube': {
                'player_client': ['ios', 'android', 'web_creator'],
                'skip': ['webpage', 'configs'],
            }
        },
        # Solve Signature challenges (Requires JS runtime)
        'remote_components': ['ejs:github'],
    }

    # Use cookies.txt if it exists (Netscape format)
    cookie_file = os.path.join(os.path.dirname(__file__), 'cookies.txt')
    if os.path.exists(cookie_file):
        ydl_opts['cookiefile'] = cookie_file
        print("Using cookies.txt for authentication")
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(video_url, download=False)
            return jsonify({
                "stream_url": info.get('url'),
                "title": info.get('title'),
                "artist": info.get('uploader'),
                "duration": info.get('duration'),
                "thumbnail": info.get('thumbnail'),
            })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
