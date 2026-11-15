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
  const promoteAliasesUrl = new URL(
    `https://api.vercel.com/v1/projects/${encodeURIComponent(projectId)}/promote/aliases`,
  );
  promoteAliasesUrl.searchParams.set("teamId", teamId);

  const deadline = Date.now() + 180_000;
  let latestAliasStatus = "todavía no disponible";
  while (Date.now() < deadline) {
    const promotionStatus = await requestJson(
      promoteAliasesUrl,
      { headers },
      "no pudo consultar el estado de los alias promovidos",
    );
    const productionAlias = (Array.isArray(promotionStatus.aliases) ? promotionStatus.aliases : [])
      .find((alias) => alias.alias === productionHost);

    // Vercel's promote-aliases endpoint has returned `completed` for a
    // successfully mapped production alias in current deployments. Older
    // responses used `mapped`, so accept both successful terminal states.
    if (productionAlias?.status === "mapped" || productionAlias?.status === "completed") {
      process.stdout.write(
        `Deployment ${deployment.id} promovido y asignado a ${productionHost} (estado: ${productionAlias.status}).\n`,
      );
      return;
    }
    if (productionAlias?.status === "failed") {
      throw new Error(
        `Vercel aceptó la promoción, pero falló la asignación de ${productionHost}` +
        (productionAlias.error ? `: ${productionAlias.error}` : "."),
      );
    }
    latestAliasStatus = productionAlias?.status || "alias aún no reportado";
    await wait(5_000);
  }

  throw new Error(
    `Vercel aceptó la promoción, pero no confirmó ${productionHost} como asignado dentro de 3 minutos (último estado: ${latestAliasStatus}).`,
  );
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
