import fs from "node:fs";
import path from "node:path";

type SharedDomains = { webOrigin?: string; apkLatestPath?: string; apkReleasesPath?: string };

function readSharedDomains(): SharedDomains | undefined {
  const candidates = [
    path.resolve(process.cwd(), "../config/domains.json"),
    path.resolve(process.cwd(), "config/domains.json"),
  ];
  for (const candidate of candidates) {
    try {
      return JSON.parse(fs.readFileSync(candidate, "utf8")) as SharedDomains;
    } catch {
      // The individual API repository can still run before the monorepo config is copied.
    }
  }
  return undefined;
}

export function getCanonicalWebOrigin(): string | undefined {
  const origin = readSharedDomains()?.webOrigin;
  return typeof origin === "string" ? new URL(origin).origin : undefined;
}

export function getApkLatestPath(): string {
  return readSharedDomains()?.apkLatestPath || "/downloads/tinku-latest.apk";
}

export function getApkReleasesPath(): string {
  return readSharedDomains()?.apkReleasesPath || "/downloads/releases";
}

export function getActiveApkDirectory(): string {
  if (process.env.TINKU_APK_RELEASE_ROOT) return process.env.TINKU_APK_RELEASE_ROOT;
  const deployRoot = process.env.TINKU_DEPLOY_ROOT || "/var/www/tinku/monorepo/deploy";
  return path.join(deployRoot, "apks", "current");
}
