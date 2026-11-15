import path from "node:path";
import { fileURLToPath } from "node:url";
import publicConfig from "../deploy/public-config.cjs";

const projectRoot = path.dirname(fileURLToPath(import.meta.url));
const domains = publicConfig.loadDomains();

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  turbopack: {
    root: projectRoot,
  },
  async redirects() {
    return [
      {
        source: domains.apkLatestPath,
        destination: `${domains.apiOrigin}${domains.apkLatestPath}`,
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
