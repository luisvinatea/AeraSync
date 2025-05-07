// Add a proxy server file: mobile/server.js
const express = require("express");
const { createProxyMiddleware } = require("http-proxy-middleware");
const path = require("path");

const app = express();
const PORT = 3001;

// Serve static files from 'public' directory
app.use(express.static(path.join(__dirname, "public")));

// Proxy API requests to backend
app.use(
  "/api",
  createProxyMiddleware({
    target: "http://localhost:3000",
    pathRewrite: { "^/api": "" },
    changeOrigin: true,
  })
);

// Handle all routes for SPA
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
