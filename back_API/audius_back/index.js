import express from "express";
import fetch from "node-fetch";
import cors from "cors";

const app = express();
app.use(cors());

const PORT = process.env.PORT || 3002;

// Hosts Audius (comme Flutter)
const HOSTS = [
  "https://discoveryprovider.audius.co",
  "https://discoveryprovider2.audius.co",
  "https://audius-metadata-1.figment.io",
  "https://audius-metadata-2.figment.io",
  "https://audius-discovery-1.cultur3stake.com",
];

// Route search
app.get("/api/audius/search", async (req, res) => {
  const query = req.query.q;
  if (!query) return res.json([]);

  for (const host of HOSTS) {
    try {
      const url = `${host}/v1/tracks/search?query=${encodeURIComponent(query)}`;

      const response = await fetch(url);
      if (!response.ok) continue;

      const data = await response.json();
      return res.json(data);
    } catch (err) {
      console.log(`Host failed: ${host}`);
      continue;
    }
  }

  res.status(500).json({ error: "All Audius hosts failed" });
});

app.listen(PORT, () =>
  console.log(`Audius proxy running on port ${PORT}`)
);
