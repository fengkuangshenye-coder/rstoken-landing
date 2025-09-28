import { defineConfig } from "vitest/config";
import path from "node:path";

export default defineConfig({
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: "./tests/setup.ts"
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "./") }
  }
});
