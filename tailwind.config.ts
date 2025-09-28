import type { Config } from "tailwindcss"

export default {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
    "./features/**/*.{js,ts,jsx,tsx}"
  ],
  theme: { container: { center: true, padding: "1rem" }, extend: {} },
  plugins: []
} satisfies Config
