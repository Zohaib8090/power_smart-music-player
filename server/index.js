const express = require('express');
const cors = require('cors');
const axios = require('axios');
const YTDlpWrap = require('yt-dlp-wrap').default;

const app = express();
const PORT = process.env.PORT || 3000;
const YOUTUBE_API_KEY = 'AIzaSyAyWLs9wViOYKqNIoE_WumDb4qHjrKl914';
const ytDlp = new YTDlpWrap();

app.use(cors());

// Health Check
app.get('/', (req, res) => {
    res.send('Power Smart Audio Server is Running');
});

// Search Endpoint (using YouTube Data API v3)
app.get('/search', async (req, res) => {
    const query = req.query.q;
    if (!query) return res.status(400).send('Missing query');

    try {
        const response = await axios.get('https://www.googleapis.com/youtube/v3/search', {
            params: {
                part: 'snippet',
                q: query,
                type: 'video',
                maxResults: 10,
                key: YOUTUBE_API_KEY
            }
        });

        const results = response.data.items.map(item => ({
            id: item.id.videoId,
            title: item.snippet.title,
            author: item.snippet.channelTitle,
            channelId: item.snippet.channelId,
            thumbnail: item.snippet.thumbnails.medium.url,
            url: `https://www.youtube.com/watch?v=${item.id.videoId}`
        }));

        res.json(results);
    } catch (error) {
        console.error('Search Error:', error.response?.data || error.message);
        res.status(500).json({ error: 'Failed to search' });
    }
});

// Audio URL Endpoint (using yt-dlp)
app.get('/audio', async (req, res) => {
    const videoId = req.query.id;
    if (!videoId) return res.status(400).send('Missing video ID');

    try {
        const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;

        // Get audio URL using yt-dlp
        const info = await ytDlp.getVideoInfo(videoUrl);

        // Find best audio format
        const audioFormats = info.formats.filter(f => f.acodec !== 'none' && f.vcodec === 'none');
        const bestAudio = audioFormats.sort((a, b) => (b.abr || 0) - (a.abr || 0))[0];

        if (!bestAudio || !bestAudio.url) {
            return res.status(404).send('No audio stream found');
        }

        // Return the direct URL
        res.json({ url: bestAudio.url });

    } catch (error) {
        console.error('Audio Error:', error);
        res.status(500).send('Error getting audio URL');
    }
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
