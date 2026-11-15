import {
  cert,
  getApps,
  initializeApp,
  ServiceAccount,
} from "firebase-admin/app";
import { Auth, getAuth } from "firebase-admin/auth";
import { getMessaging, Messaging } from "firebase-admin/messaging";
import { getStorage, Storage } from "firebase-admin/storage";

const b64 = process.env.FIREBASE_ADMIN_KEY_B64;
const bucketName = process.env.FIREBASE_STORAGE_BUCKET;

if (!b64) {
  throw new Error("FIREBASE_ADMIN_KEY_B64 está ausente.");
}

if (!bucketName) {
  throw new Error("FIREBASE_STORAGE_BUCKET está ausente.");
}

// Decodificar base64
const jsonString = Buffer.from(b64, "base64").toString("utf8");

let parsed: any;

try {
  parsed = JSON.parse(jsonString);
} catch {
  throw new Error("FIREBASE_ADMIN_KEY_B64 no es un JSON válido");
}

if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
  throw new Error("Invalid Firebase service account structure");
}

const serviceAccount: ServiceAccount = {
  projectId: parsed.project_id,
  clientEmail: parsed.client_email,
  privateKey: parsed.private_key.replace(/\\n/g, "\n"),
};

// Inicializar app (singleton)
if (!getApps().length) {
  initializeApp({
    credential: cert(serviceAccount),
    storageBucket: bucketName,
  });
}

// Instancias
const storage = getStorage();
const auth = getAuth();
const messaging = getMessaging();
const bucket = storage.bucket();
type FirebaseBucket = ReturnType<Storage["bucket"]>;

// Exports tipados
export const firebaseAuth: Auth = auth;
export const firebaseMessaging: Messaging = messaging;
export const firebaseStorage: Storage = storage;
export const firebaseBucket: FirebaseBucket = bucket;
