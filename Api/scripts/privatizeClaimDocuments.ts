import dotenv from "dotenv";
import { query, dbPool } from "../src/config/database.config";
import { firebaseBucket } from "../src/config/firebase-client.config";
import { StorageService } from "../src/services/storage.service";

dotenv.config();

async function run() {
  const apply = process.argv.includes("--apply");
  const rows = await query<{ user_id: string; documents: string[] }>(
    "SELECT user_id, documents FROM business_claim_requests"
  );
  const paths = new Set<string>();
  const [files] = await firebaseBucket.getFiles({ prefix: "business_claim_requests/" });
  for (const file of files) paths.add(file.name);
  for (const row of rows.rows) {
    for (const url of row.documents ?? []) {
      paths.add(StorageService.assertEntityFile(url, "business_claim_requests", row.user_id));
    }
  }
  console.log(`${paths.size} claim documents. Mode: ${apply ? "apply" : "dry run"}.`);
  for (const path of paths) {
    if (apply) await firebaseBucket.file(path).makePrivate();
  }
}

run().catch(error => { console.error(error); process.exitCode = 1; })
  .finally(() => dbPool.end());
