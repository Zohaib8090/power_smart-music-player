from flask import Flask, request, jsonify
from flask_cors import CORS
import yt_dlp
import os
import tempfile

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    try:
        version = yt_dlp.version.__version__
    except:
        version = "unknown"
    return f"Power Smart Python Extractor is Running (yt-dlp: {version})"

def extract_audio_url(video_url, custom_cookies=None, custom_ua=None, custom_po=None):
    # Fallback PO Token
    default_po = 'CgtPRDJlUFVKbmd4TSii79TKBjIKCgJQSxIEGgAgDGLfAgrcAjE0LllUPVFodXdvOFB6OUVkSHphMjI4VXBKbWsxX3lFT2xqN3NkRnBpcVBVZnZIN3hTaGcwZE1JUkgtMzRUY2VYSlFEcXBnV0J0X0haOWhLeVpTc2IzM1JNWU5GX0dEZjZOREpBdzRxQnpjQzNDVkFmTGRHQmJ2WmdTVzdPZl8yaHF1UnROVUNKTjRUYzZxeVVBd1FEOXNSMmMwR3NyTk15Y1F5TDdWdzl0RThCbktrV2J1TDRGdUFOcnRIWFFab0JObUxYQ09qTWY2aC1QTUFQc3haTTQ4WWxBZGFkLUVZSEJNdUJKYzlIamNYY1lCV1ZxTGY3TU5lX0YyN0tGQXBlRVQwaWJYQUhtbjZVVTgtYkJSNmxLUTNKaDViS1ZGakp2Z1RoZGlMNnlfY0xLdkZncmJfTjg5LUFOcHY3Y3J4cEluQlJweEw4QzAzcFpTZDk5eXRJeGpZeUplUQ%3D%3D'
    po_token = custom_po if custom_po else default_po

    ydl_opts = {
        'format': 'bestaudio/best',
        'quiet': True,
        'no_warnings': True,
        'http_headers': {
            'User-Agent': custom_ua if custom_ua else 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://www.youtube.com/',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
            'Accept-Language': 'en-US,en;q=0.9',
            'Sec-Ch-Ua': '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
            'Sec-Ch-Ua-Mobile': '?0',
            'Sec-Ch-Ua-Platform': '"Windows"',
        },
        'extractor_args': {
            'youtube': {
                'player_client': ['ios', 'android', 'web_embedded'],
                'po_token': [f'web.gvs+{po_token}', f'mweb.gvs+{po_token}']
            }
        },
        'remote_components': ['ejs:github'],
        'js_runtimes': {'node': {}},
    }

    # Use the cookies passed from the mobile app
    if custom_cookies:
        # Note: setting 'Cookie' in http_headers is often more reliable than 'headers' for yt-dlp python API
        ydl_opts['http_headers']['Cookie'] = custom_cookies
    else:
        cookie_file = os.path.join(os.path.dirname(__file__), 'cookies.txt')
        if os.path.exists(cookie_file):
            ydl_opts['cookiefile'] = cookie_file

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            return ydl.extract_info(video_url, download=False)
    except Exception as e:
        print(f"yt-dlp error: {e}")
        raise e

@app.route('/extract', methods=['GET'])
def extract_audio():
    video_id = request.args.get('id')
    if not video_id:
        return jsonify({"error": "Missing video ID"}), 400

    video_url = f"https://www.youtube.com/watch?v={video_id}"
    
    # Get cookies from request headers if the app sent them
    custom_cookies = request.headers.get('Cookie')
    custom_ua = request.headers.get('User-Agent')
    custom_po = request.headers.get('X-PO-Token')
    
    try:
        info = extract_audio_url(video_url, custom_cookies=custom_cookies, custom_ua=custom_ua, custom_po=custom_po)
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
