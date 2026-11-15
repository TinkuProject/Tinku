const path = require("node:path");

const deployRoot = process.env.TINKU_DEPLOY_ROOT || "/var/www/tinku/monorepo/deploy";

module.exports = {
  apps: [
    {
      name: "tinku-api-monorepo",
      cwd: path.join(deployRoot, "current-api"),
      script: "dist/index.js",
      exec_mode: "fork",
      instances: 1,
      autorestart: true,
      kill_timeout: 12000,
      listen_timeout: 15000,
      node_args: `--env-file=${path.join(deployRoot, "shared/api.env")}`,
      env: { NODE_ENV: "production", PORT: "3300" },
    },
  ],
};
