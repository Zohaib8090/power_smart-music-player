const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
const YOUTUBE_API_KEY = 'AIzaSyAyWLs9wViOYKqNIoE_WumDb4qHjrKl914';

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

// Audio URL Endpoint - Simplified for Web (returns error message)
app.get('/audio', async (req, res) => {
    const videoId = req.query.id;
    if (!videoId) return res.status(400).send('Missing video ID');

    // For Web, audio extraction is complex due to YouTube restrictions
    // Return a message suggesting to use Android/Windows app
    res.status(501).json({
        error: 'Audio playback on Web is not supported. Please use the Android or Windows app for full functionality.',
        videoUrl: `https://www.youtube.com/watch?v=${videoId}`
    });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
