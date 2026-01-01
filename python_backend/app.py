from flask import Flask, request, jsonify
from flask_cors import CORS
import yt_dlp
import os
import tempfile

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return "Power Smart Python Extractor is Running"

def extract_audio_url(video_url, custom_cookies=None):
    # Use user provided PO Token
    po_token = 'CgtPRDJlUFVKbmd4TSii79TKBjIKCgJQSxIEGgAgDGLfAgrcAjE0LllUPVFodXdvOFB6OUVkSHphMjI4VXBKbWsxX3lFT2xqN3NkRnBpcVBVZnZIN3hTaGcwZE1JUkgtMzRUY2VYSlFEcXBnV0J0X0haOWhLeVpTc2IzM1JNWU5GX0dEZjZOREpBdzRxQnpjQzNDVkFmTGRHQmJ2WmdTVzdPZl8yaHF1UnROVUNKTjRUYzZxeVVBd1FEOXNSMmMwR3NyTk15Y1F5TDdWdzl0RThCbktrV2J1TDRGdUFOcnRIWFFab0JObUxYQ09qTWY2aC1QTUFQc3haTTQ4WWxBZGFkLUVZSEJNdUJKYzlIamNYY1lCV1ZxTGY3TU5lX0YyN0tGQXBlRVQwaWJYQUhtbjZVVTgtYkJSNmxLUTNKaDViS1ZGakp2Z1RoZGlMNnlfY0xLdkZncmJfTjg5LUFOcHY3Y3J4cEluQlJweEw4QzAzcFpTZDk5eXRJeGpZeUplUQ%3D%3D'

    ydl_opts = {
        'format': 'bestaudio/best',
        'quiet': True,
        'no_warnings': True,
        'extractor_args': {
            'youtube': {
                'player_client': ['ios', 'android', 'web_embedded'],
                'po_token': [f'web.gvs+{po_token}', f'mweb.gvs+{po_token}']
            }
        },
        'remote_components': ['ejs:github'],
        'js_runtimes': {'node': {}},
    }

    # Handle cookies
    temp_cookie_file = None
    try:
        if custom_cookies:
            # Create a temporary cookie file for yt-dlp to use
            # Note: yt-dlp works best with Netscape format, but simplified headers can work via --add-header
            # However, for the python API, setting 'cookiefile' to a File path is most reliable.
            fd, temp_cookie_file = tempfile.mkstemp(suffix='.txt')
            with os.fdopen(fd, 'w') as tmp:
                # If it's a flat cookie string from document.cookie, we can't easily convert to Netscape
                # but we can pass it as a header.
                pass
            ydl_opts['headers'] = {'Cookie': custom_cookies}
        else:
            cookie_file = os.path.join(os.path.dirname(__file__), 'cookies.txt')
            if os.path.exists(cookie_file):
                ydl_opts['cookiefile'] = cookie_file

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            return ydl.extract_info(video_url, download=False)
    finally:
        if temp_cookie_file and os.path.exists(temp_cookie_file):
            os.remove(temp_cookie_file)

@app.route('/extract', methods=['GET'])
def extract_audio():
    video_id = request.args.get('id')
    if not video_id:
        return jsonify({"error": "Missing video ID"}), 400

    video_url = f"https://www.youtube.com/watch?v={video_id}"
    
    # Get cookies from request headers if the app sent them
    custom_cookies = request.headers.get('Cookie')
    
    try:
        info = extract_audio_url(video_url, custom_cookies=custom_cookies)
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
