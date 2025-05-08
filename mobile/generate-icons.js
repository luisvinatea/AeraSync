const sharp = require("sharp");
const fs = require("fs");
const path = require("path");

const INPUT_SVG = path.join(__dirname, "public/icons/aerasync_icon.svg");
const OUTPUT_DIR = path.join(__dirname, "public/icons/ios");

// Make sure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// iOS icon sizes
const sizes = [
  { size: 180, name: "apple-touch-icon-180.png" },
  { size: 152, name: "apple-touch-icon-152.png" },
  { size: 144, name: "apple-touch-icon-144.png" },
  { size: 120, name: "apple-touch-icon-120.png" },
  { size: 114, name: "apple-touch-icon-114.png" },
  { size: 76, name: "apple-touch-icon-76.png" },
  { size: 72, name: "apple-touch-icon-72.png" },
  { size: 60, name: "apple-touch-icon-60.png" },
  { size: 57, name: "apple-touch-icon-57.png" },
  { size: 512, name: "app-icon-512.png" },
  { size: 192, name: "app-icon-192.png" },
];

async function generateIcons() {
  console.log("Generating icons from SVG...");

  for (const { size, name } of sizes) {
    console.log(`Creating ${name} (${size}x${size}px)`);

    const outputPath = path.join(OUTPUT_DIR, name);

    await sharp(INPUT_SVG).resize(size, size).png().toFile(outputPath);
  }

  console.log("All icons generated successfully!");
}

generateIcons().catch((err) => {
  console.error("Error generating icons:", err);
  process.exit(1);
});
