from flask import Flask, request, jsonify
from flask_cors import CORS
import yt_dlp
import os

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return "Power Smart Python Extractor is Running"

def extract_audio_url(video_url):
    cookie_file = os.path.join(os.path.dirname(__file__), 'cookies.txt')
    
    # Using the user's suggested 'ios' client bypass strategy
    ydl_opts = {
        'format': 'bestaudio/best',
        'quiet': True,
        'no_warnings': True,
        # This 'ios' client is the secret—it bypasses the PO_TOKEN requirement
        'extractor_args': {
            'youtube': {
                'player_client': ['ios'],
                'skip': ['webpage', 'configs']
            }
        },
        'remote_components': ['ejs:github'],
        'js_runtimes': {'node': {}},
    }
    
    if os.path.exists(cookie_file):
        ydl_opts['cookiefile'] = cookie_file
        print(f"Logging: Using cookies from {cookie_file}")

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            return ydl.extract_info(video_url, download=False)
    except Exception as e:
        print(f"Extraction failed: {str(e)}")
        raise e

@app.route('/extract', methods=['GET'])
def extract_audio():
    video_id = request.args.get('id')
    if not video_id:
        return jsonify({"error": "Missing video ID"}), 400

    video_url = f"https://www.youtube.com/watch?v={video_id}"
    
    try:
        info = extract_audio_url(video_url)
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
