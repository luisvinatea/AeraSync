// Add a proxy server file: mobile/server.js
const express = require("express");
const { createProxyMiddleware } = require("http-proxy-middleware");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3001;

// Serve static files from 'public' directory
app.use(express.static(path.join(__dirname, "public")));

// Proxy API requests to backend - use environment variable for production
const apiTarget =
  process.env.NODE_ENV === "production"
    ? process.env.API_URL || "https://aerasync-api.vercel.app"
    : "http://localhost:3000";

app.use(
  "/api",
  createProxyMiddleware({
    target: apiTarget,
    pathRewrite: { "^/api": "" },
    changeOrigin: true,
  })
);

// Handle all routes for SPA
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// For local development
if (process.env.NODE_ENV !== "production") {
  app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
  });
}

// Export the Express app for Vercel
module.exports = app;
