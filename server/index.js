const express = require('express');
const cors = require('cors');
const ytdl = require('ytdl-core');
const YouTube = require("youtube-sr").default;

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());

// Health Check
app.get('/', (req, res) => {
    res.send('Power Smart Audio Server is Running');
});

// Search Endpoint (proxies YouTube search)
app.get('/search', async (req, res) => {
    const query = req.query.q;
    if (!query) return res.status(400).send('Missing query');

    try {
        const videos = await YouTube.search(query, { limit: 10, type: 'video' });
        const results = videos.map(v => ({
            id: v.id,
            title: v.title,
            author: v.channel.name,
            channelId: v.channel.id,
            duration: v.durationFormatted,
            thumbnail: v.thumbnail.url,
            url: v.url
        }));
        res.json(results);
    } catch (error) {
        console.error('Search Error:', error);
        res.status(500).json({ error: 'Failed to search' });
    }
});

// Audio Stream Endpoint (Pipes audio directly to response)
app.get('/audio', async (req, res) => {
    const videoId = req.query.id;
    if (!videoId) return res.status(400).send('Missing video ID');

    try {
        const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;

        // Get info first to find correct format
        const info = await ytdl.getInfo(videoUrl);
        const format = ytdl.chooseFormat(info.formats, { quality: 'highestaudio' });

        // Pipe the stream
        res.header('Content-Type', 'audio/mpeg');
        ytdl(videoUrl, { format: format })
            .pipe(res);

    } catch (error) {
        console.error('Stream Error:', error);
        res.status(500).send('Error streaming audio');
    }
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
