const fs = require("node:fs");
const path = require("node:path");
const { loadPublicConfig, writeDartDefines } = require("./public-config.cjs");

function required(name) {
  const value = process.env[name];
  if (!value || /[\r\n\0]/.test(value)) throw new Error(`Falta ${name}.`);
  return value;
}

const encoded = required("TINKU_ANDROID_KEYSTORE_BASE64").replace(/\s/g, "");
if (!/^[A-Za-z0-9+/]+={0,2}$/.test(encoded)) throw new Error("Keystore Base64 invalido.");
const keystore = Buffer.from(encoded, "base64");
if (keystore.length < 1024) throw new Error("El keystore recibido es demasiado pequeno.");

const runnerTemp = required("RUNNER_TEMP");
const keystorePath = path.join(runnerTemp, "tinku-release.jks");
fs.writeFileSync(keystorePath, keystore, { mode: 0o600, flag: "wx" });

const propertiesPath = path.join(__dirname, "../App/android/key.properties");
const properties = [
  `storeFile=${keystorePath}`,
  `storePassword=${required("TINKU_ANDROID_KEYSTORE_PASSWORD")}`,
  `keyAlias=${required("TINKU_ANDROID_KEY_ALIAS")}`,
  `keyPassword=${required("TINKU_ANDROID_KEY_PASSWORD")}`,
].join("\n");
fs.writeFileSync(propertiesPath, `${properties}\n`, { mode: 0o600 });

const base = JSON.parse(fs.readFileSync(path.join(__dirname, "../config/android-version.json"), "utf8"));
const runNumber = Number(required("GITHUB_RUN_NUMBER"));
if (!Number.isSafeInteger(base.versionCodeBase) || base.versionCodeBase < 1 || !Number.isSafeInteger(runNumber) || runNumber < 1) {
  throw new Error("Version code o numero de ejecucion invalido.");
}
const buildNumber = base.versionCodeBase + runNumber;
if (buildNumber > 2_100_000_000) throw new Error("Se alcanzo el limite de versionCode Android.");

const pubspec = fs.readFileSync(path.join(__dirname, "../App/pubspec.yaml"), "utf8");
const version = /^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+[0-9]+)?\s*$/m.exec(pubspec)?.[1];
if (!version) throw new Error("No se pudo leer version en App/pubspec.yaml.");
loadPublicConfig();
const dartDefines = path.join(runnerTemp, "tinku-production-dart-defines.json");
writeDartDefines(dartDefines, {
  googleClientId: process.env.TINKU_GOOGLE_WEB_CLIENT_ID,
  stripePublishableKey: process.env.TINKU_STRIPE_PUBLISHABLE_KEY,
});

const output = process.env.GITHUB_OUTPUT;
if (!output) throw new Error("GITHUB_OUTPUT no esta definido.");
fs.appendFileSync(output, `keystore_path=${keystorePath}\nbuild_number=${buildNumber}\nversion_name=${version}\ndart_defines=${dartDefines}\n`);
console.log(`Firma Android preparada. Build ${version}+${buildNumber}.`);
