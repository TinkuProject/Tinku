const fs = require("node:fs");
const path = require("node:path");

const deploymentUrl = process.env.DEPLOYMENT_URL;
const teamId = process.env.VERCEL_ORG_ID;
const projectId = process.env.VERCEL_PROJECT_ID;
const token = process.env.VERCEL_TOKEN;

for (const [name, value] of Object.entries({ deploymentUrl, teamId, projectId, token })) {
  if (!value) throw new Error(`Falta la variable requerida ${name}.`);
}

const parsedDeploymentUrl = new URL(deploymentUrl);
if (parsedDeploymentUrl.protocol !== "https:" || !parsedDeploymentUrl.hostname.endsWith(".vercel.app")) {
  throw new Error("DEPLOYMENT_URL no es un deployment HTTPS de Vercel.");
}

const headers = {
  Authorization: `Bearer ${token}`,
  "Content-Type": "application/json",
};

async function requestJson(url, options, action) {
  const response = await fetch(url, options);
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const detail = body.error?.message || body.message || `HTTP ${response.status}`;
    throw new Error(`Vercel ${action} falló: ${detail}`);
  }
  return body;
}

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function main() {
  const deploymentLookup = new URL(
    `https://api.vercel.com/v13/deployments/${encodeURIComponent(parsedDeploymentUrl.hostname)}`,
  );
  deploymentLookup.searchParams.set("teamId", teamId);

  const deployment = await requestJson(
    deploymentLookup,
    { headers },
    "no pudo localizar el deployment",
  );

  if (deployment.readyState !== "READY" || !/^dpl_[A-Za-z0-9]+$/.test(deployment.id || "")) {
    throw new Error("El deployment de Vercel no está READY o no devolvió un ID válido.");
  }

  const promotionUrl = new URL(
    `https://api.vercel.com/v10/projects/${encodeURIComponent(projectId)}/promote/${encodeURIComponent(deployment.id)}`,
  );
  promotionUrl.searchParams.set("teamId", teamId);

  const result = await requestJson(
    promotionUrl,
    { method: "POST", headers },
    "no pudo promover el deployment",
  );

  if (result.error) {
    throw new Error(`Vercel rechazó la promoción: ${result.error.message || result.error.code || "error desconocido"}`);
  }

  const { webOrigin } = JSON.parse(
    fs.readFileSync(path.join(__dirname, "../config/domains.json"), "utf8"),
  );
  const productionHost = new URL(webOrigin).hostname;
  const deploymentStatusUrl = new URL(
    `https://api.vercel.com/v13/deployments/${encodeURIComponent(deployment.id)}`,
  );
  deploymentStatusUrl.searchParams.set("teamId", teamId);

  const deadline = Date.now() + 180_000;
  while (Date.now() < deadline) {
    const promotedDeployment = await requestJson(
      deploymentStatusUrl,
      { headers },
      "no pudo verificar el deployment promovido",
    );
    const aliases = Array.isArray(promotedDeployment.alias) ? promotedDeployment.alias : [];
    const aliasAssigned = promotedDeployment.aliasAssigned === true || promotedDeployment.aliasAssigned === "true";
    if (aliasAssigned && aliases.includes(productionHost)) {
      process.stdout.write(`Deployment ${deployment.id} promovido y asignado a ${productionHost}.\n`);
      return;
    }
    await wait(5_000);
  }

  throw new Error(`Vercel aceptó la promoción, pero ${productionHost} no quedó asignado dentro de 3 minutos.`);
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
