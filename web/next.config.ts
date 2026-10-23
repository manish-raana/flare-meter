import path from "node:path";
import type { NextConfig } from "next";

// A static site (out/) for Cloudflare Pages: no server, so no image optimizer either.
const nextConfig: NextConfig = {
  output: "export",
  images: { unoptimized: true },
  turbopack: {
    // The limits table is ../Shared/Limits.json, shared with the app.
    root: path.join(__dirname, ".."),
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
