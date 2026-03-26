import express from "express";
import fetch from "node-fetch";

const app = express();
const PORT = process.env.PORT || 3000;

// Utilise la variable d'environnement JAMENDO_CLIENT_ID,
// ou la valeur par défaut si elle n'est pas définie
const JAMENDO_CLIENT_ID = process.env.JAMENDO_CLIENT_ID || "e1ce7712";


app.get("/api/search", async (req, res) => {
  const query = req.query.q;
  if (!query) return res.json([]);

  const url =
    `https://api.jamendo.com/v3.0/tracks/` +
    `?client_id=${JAMENDO_CLIENT_ID}` +
    `&search=${encodeURIComponent(query)}` +
    `&format=json&limit=10&audioformat=mp31&include=musicinfo`;

  try {
    const response = await fetch(url);
    const data = await response.json();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: "Jamendo error" });
  }
});

app.listen(PORT, () =>
  console.log(`Jamendo proxy running on port ${PORT}`)
);
