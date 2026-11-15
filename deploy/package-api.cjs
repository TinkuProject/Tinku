const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { createHash } = require("node:crypto");

const root = path.resolve(__dirname, "..");
const releaseId = process.env.RELEASE_ID;
if (!/^[0-9a-f]{40}-\d+$/.test(releaseId || "")) throw new Error("RELEASE_ID invalido.");
const sourceApi = path.join(root, "Api");
const destination = fs.mkdtempSync(path.join(os.tmpdir(), "tinku-api-package-"));
const api = path.join(destination, "Api");
fs.mkdirSync(api);

function copyTree(source, target) {
  const stat = fs.lstatSync(source);
  if (stat.isSymbolicLink() || (!stat.isDirectory() && !stat.isFile())) throw new Error("El paquete API contiene un archivo especial.");
  if (stat.isDirectory()) {
    fs.mkdirSync(target, { recursive: true });
    for (const entry of fs.readdirSync(source)) copyTree(path.join(source, entry), path.join(target, entry));
  } else {
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.copyFileSync(source, target, fs.constants.COPYFILE_EXCL);
  }
}

for (const name of ["dist", "database/migrations"]) copyTree(path.join(sourceApi, name), path.join(api, name));
for (const name of ["package.json", "package-lock.json"]) copyTree(path.join(sourceApi, name), path.join(api, name));
copyTree(path.join(__dirname, "run-migrations.cjs"), path.join(api, "deploy-migrations.cjs"));
copyTree(path.join(__dirname, "ecosystem.config.cjs"), path.join(api, "ecosystem.config.cjs"));
copyTree(path.join(root, "config/domains.json"), path.join(api, "config/domains.json"));
if (!fs.existsSync(path.join(api, "dist/index.js")) || !fs.readdirSync(path.join(api, "database/migrations")).some((name) => /^\d{4}_[a-z0-9_]+\.sql$/i.test(name))) {
  throw new Error("El release API no contiene build o migraciones.");
}
fs.writeFileSync(path.join(api, "deployment.json"), `${JSON.stringify({ releaseId, commit: releaseId.slice(0, 40), builtAt: new Date().toISOString() }, null, 2)}\n`, { flag: "wx" });

const releaseDir = path.join(root, "release");
fs.mkdirSync(releaseDir, { recursive: true });
const archive = path.join(releaseDir, `tinku-api-${releaseId}.tar.gz`);
const result = spawnSync("tar", ["-czf", archive, "-C", destination, "Api"], { encoding: "utf8" });
if (result.error) throw result.error;
if (result.status !== 0) throw new Error(`No se pudo empaquetar API: ${result.stderr}`);
const sha = createHash("sha256").update(fs.readFileSync(archive)).digest("hex");
fs.writeFileSync(`${archive}.sha256`, `${sha}  ${path.basename(archive)}\n`, { flag: "wx" });
const output = process.env.GITHUB_OUTPUT;
if (output) fs.appendFileSync(output, `archive=${archive}\nrelease_id=${releaseId}\n`);
console.log(`Paquete API ${releaseId}: ${fs.statSync(archive).size} bytes, SHA-256 ${sha}.`);
