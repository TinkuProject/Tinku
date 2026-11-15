const fs = require("node:fs");
const path = require("node:path");

const configFile = path.join(
  __dirname,
  "../config/environments/production.env",
);
const domainsFile = path.join(__dirname, "../config/domains.json");

function loadDomains(file = domainsFile) {
  const domains = JSON.parse(fs.readFileSync(file, "utf8"));
  for (const key of ["apiOrigin", "webOrigin"]) {
    const url = new URL(domains[key]);
    if (url.protocol !== "https:" || url.username || url.password || url.pathname !== "/" || url.search || url.hash) {
      throw new Error(`${key} debe ser un origen HTTPS sin credenciales ni ruta.`);
    }
    domains[key] = url.origin;
  }
  for (const key of ["apkLatestPath", "apkReleasesPath"]) {
    if (typeof domains[key] !== "string" || !/^\/(?:[a-z0-9.-]+\/?)+$/.test(domains[key])) {
      throw new Error(`${key} debe ser una ruta publica absoluta valida.`);
    }
  }
  return Object.freeze(domains);
}

function loadPublicConfig(file = configFile) {
  const values = Object.create(null);
  for (const [index, rawLine] of fs.readFileSync(file, "utf8").split(/\r?\n/).entries()) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    const match = /^([A-Z][A-Z0-9_]*)=(.*)$/.exec(line);
    if (!match || Object.hasOwn(values, match[1])) {
      throw new Error(`Configuracion publica invalida en linea ${index + 1}.`);
    }
    const value = match[2].trim();
    if (/[\r\n\0]/.test(value) || /(?:SECRET|PASSWORD|PRIVATE|TOKEN|KEY_B64|DATABASE_URL)/i.test(match[1])) {
      throw new Error(`La variable ${match[1]} no puede estar en configuracion publica.`);
    }
    values[match[1]] = value;
  }
  for (const key of ["ANDROID_APK_NAME"]) {
    if (!values[key]) throw new Error(`Falta la variable publica ${key}.`);
  }
  const domains = loadDomains();
  values.PUBLIC_API_URL = domains.apiOrigin;
  values.PUBLIC_WEB_URL = domains.webOrigin;
  values.APK_LATEST_URL = new URL(domains.apkLatestPath, domains.webOrigin).toString();
  values.APK_RELEASES_URL = new URL(domains.apkReleasesPath, domains.apiOrigin).toString();
  values.APK_REDIRECT_URL = new URL(domains.apkLatestPath, domains.apiOrigin).toString();
  if (!/^[A-Za-z0-9._-]+\.apk$/i.test(values.ANDROID_APK_NAME)) {
    throw new Error("ANDROID_APK_NAME no es valido.");
  }
  if (!/^\d+$/.test(values.ANDROID_APK_MAX_BYTES || "")) throw new Error("ANDROID_APK_MAX_BYTES no es valido.");
  return Object.freeze(values);
}

function writeDartDefines(destination, extra = {}) {
  const config = loadPublicConfig();
  const values = {
    API_BASE_URL: config.PUBLIC_API_URL,
    SERVER_GOOGLE_CLIENT_ID: extra.googleClientId || "",
    STRIPE_PUBLISHABLE_KEY: extra.stripePublishableKey || "",
  };
  for (const [key, value] of Object.entries(values)) {
    if (typeof value !== "string" || /[\r\n\0]/.test(value)) {
      throw new Error(`Valor publico invalido para ${key}.`);
    }
  }
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, `${JSON.stringify(values, null, 2)}\n`, { mode: 0o600 });
}

if (require.main === module) {
  const command = process.argv[2];
  if (command === "web-env") {
    const config = loadPublicConfig();
    process.stdout.write(`NEXT_PUBLIC_API_URL=${config.PUBLIC_API_URL}\nTINKU_APK_REDIRECT_URL=${config.APK_REDIRECT_URL}\n`);
  } else if (command === "dart-defines") {
    const destination = process.argv[3];
    if (!destination) throw new Error("Indique la ruta de salida de dart-defines.");
    writeDartDefines(destination, {
      googleClientId: process.env.TINKU_GOOGLE_WEB_CLIENT_ID,
      stripePublishableKey: process.env.TINKU_STRIPE_PUBLISHABLE_KEY,
    });
  } else {
    throw new Error("Comando esperado: web-env o dart-defines.");
  }
}

module.exports = { loadDomains, loadPublicConfig, writeDartDefines };
