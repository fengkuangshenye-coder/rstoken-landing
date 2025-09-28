/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: { typedRoutes: true },
  webpack: (config) => {
    config.resolve = config.resolve || {};
    config.resolve.alias = {
      ...(config.resolve.alias || {}),
      // 这些仅在原生或 Node CLI 下使用，Web 端屏蔽掉即可
      "@react-native-async-storage/async-storage": false,
      "pino-pretty": false
    };
    return config;
  }
};
export default nextConfig;
