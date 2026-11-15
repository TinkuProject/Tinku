const fs = require("node:fs");
const path = require("node:path");
const { createHash } = require("node:crypto");
const { loadPublicConfig } = require("./public-config.cjs");

function sha256(file) {
  return createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

const source = path.join(__dirname, "../App/build/app/outputs/flutter-apk/app-release.apk");
if (!fs.existsSync(source)) throw new Error("Falta app-release.apk.");
const stat = fs.statSync(source);
const maximumSize = Number(loadPublicConfig().ANDROID_APK_MAX_BYTES);
if (stat.size < 1024 * 1024 || stat.size > maximumSize) {
  throw new Error(`APK de ${stat.size} bytes: debe medir entre 1 MB y ${maximumSize} bytes.`);
}
const buildNumber = Number(process.env.ANDROID_BUILD_NUMBER);
const versionName = process.env.ANDROID_VERSION_NAME;
const fingerprint = process.env.TINKU_ANDROID_CERT_SHA256?.replaceAll(":", "").toUpperCase();
const releaseId = process.env.RELEASE_ID;
if (!Number.isSafeInteger(buildNumber) || buildNumber < 1 || !/^\d+\.\d+\.\d+$/.test(versionName || "") || !/^[0-9A-F]{64}$/.test(fingerprint || "") || !/^[0-9a-f]{40}-\d+$/.test(releaseId || "")) {
  throw new Error("Faltan datos validos de version, release o huella de firma esperada.");
}
const certOutput = fs.readFileSync(process.env.APK_SIGNATURE_REPORT, "utf8");
const actual = /certificate SHA-256 digest:\s*([0-9a-f:]+)/i.exec(certOutput)?.[1]?.replaceAll(":", "").toUpperCase();
if (!actual || actual !== fingerprint) throw new Error("El APK no esta firmado con el certificado Android existente.");
const badging = fs.readFileSync(process.env.APK_BADGING_REPORT, "utf8");
if (!badging.includes("package: name='com.tinku.tinkuapp'") || !badging.includes(`versionCode='${buildNumber}'`) || !badging.includes(`versionName='${versionName}'`)) {
  throw new Error("El ID de paquete o la version declarada por el APK no coincide con el release.");
}

const destination = path.join(process.env.RUNNER_TEMP, "tinku-android-release");
fs.mkdirSync(destination, { recursive: false, mode: 0o700 });
const apk = path.join(destination, "Tinku.apk");
fs.copyFileSync(source, apk, fs.constants.COPYFILE_EXCL);
const checksum = sha256(apk);
const metadata = {
  app: "Tinku",
  applicationId: "com.tinku.tinkuapp",
  versionName,
  versionCode: buildNumber,
  releaseId,
  signingCertificateSha256: actual,
  sha256: checksum,
  sizeBytes: fs.statSync(apk).size,
};
fs.writeFileSync(path.join(destination, "release.json"), `${JSON.stringify(metadata, null, 2)}\n`, { mode: 0o644, flag: "wx" });
fs.writeFileSync(path.join(destination, "Tinku.apk.sha256"), `${checksum}  Tinku.apk\n`, { mode: 0o644, flag: "wx" });
console.log(`APK verificado: Tinku ${versionName}+${buildNumber}, ${metadata.sizeBytes} bytes, SHA-256 ${checksum}.`);
