/**
 * Зарежда примерни данни в Cloud Firestore за PA Style Barbershop.
 *
 * Удостоверяване (препоръчително): файл `serviceAccountKey.json` в тази папка
 * (Firebase Console → Project settings → Service accounts → Generate new private key).
 *
 * Project id се взима по ред: FIREBASE_PROJECT_ID → seed.config.json → firebase_options.dart
 */

import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const seedPath = join(__dirname, 'seed-data.json');
const localKeyPath = join(__dirname, 'serviceAccountKey.json');
const dartOptionsPath = join(__dirname, '../../barbershop_app/lib/firebase_options.dart');
const seedConfigPath = join(__dirname, 'seed.config.json');

function resolveProjectId() {
  const fromEnv = process.env.FIREBASE_PROJECT_ID?.trim();
  if (fromEnv) return fromEnv;

  if (existsSync(seedConfigPath)) {
    try {
      const cfg = JSON.parse(readFileSync(seedConfigPath, 'utf8'));
      if (cfg.projectId && String(cfg.projectId).trim()) {
        return String(cfg.projectId).trim();
      }
    } catch {
      /* ignore */
    }
  }

  if (existsSync(dartOptionsPath)) {
    const src = readFileSync(dartOptionsPath, 'utf8');
    const m = src.match(/projectId:\s*'([^']+)'/);
    if (m) return m[1];
  }

  return null;
}

function initFirebase() {
  const projectId = resolveProjectId();
  if (!projectId) {
    console.error(`
Не мога да определя Firebase project id.

Направи едно от следните:
  • Задай променлива:  set FIREBASE_PROJECT_ID=pa-style-barbershop
  • Или създай seed.config.json:  { "projectId": "pa-style-barbershop" }
  • Или провери пътя до firebase_options.dart:  ${dartOptionsPath}
`);
    process.exit(1);
  }

  if (existsSync(localKeyPath)) {
    const sa = JSON.parse(readFileSync(localKeyPath, 'utf8'));
    const pid = sa.project_id || projectId;
    initializeApp({
      credential: cert(sa),
      projectId: pid,
    });
    console.log('Удостоверяване: serviceAccountKey.json | проект:', pid);
    return;
  }

  initializeApp({
    credential: applicationDefault(),
    projectId,
  });
  console.log('Удостоверяване: Application Default Credentials | проект:', projectId);
  console.log(
    'Съвет: за най-малко проблеми сложи serviceAccountKey.json в scripts/firestore-seed/',
  );
}

async function main() {
  const raw = readFileSync(seedPath, 'utf8');
  const data = JSON.parse(raw);

  initFirebase();
  const db = getFirestore();

  const batch = db.batch();

  const salonMainRef = db.collection('salon').doc('main');
  batch.set(
    salonMainRef,
    {
      ...data.salon.main,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  for (const [id, fields] of Object.entries(data.services)) {
    batch.set(db.collection('services').doc(id), fields, { merge: true });
  }

  for (const [id, fields] of Object.entries(data.barberProducts)) {
    batch.set(db.collection('barberProducts').doc(id), fields, { merge: true });
  }

  await batch.commit();
  const nSvc = Object.keys(data.services).length;
  const nBp = Object.keys(data.barberProducts).length;
  console.log(`Готово: salon/main + ${nSvc} услуги + ${nBp} фризьора (barberProducts).`);
}

function explainSeedError(e) {
  const code = e?.code;
  const msg = String(e?.message ?? e ?? '');
  if (code === 5 || msg.includes('NOT_FOUND')) {
    let pid = resolveProjectId() || '(неизвестен)';
    if (existsSync(localKeyPath)) {
      try {
        pid = JSON.parse(readFileSync(localKeyPath, 'utf8')).project_id || pid;
      } catch {
        /* ignore */
      }
    }
    console.error(`
Firestore: NOT_FOUND (код 5)
────────────────────────────
Най-често Firestore още НЕ е създадена за този проект.

1) Firebase Console → проект с id: ${pid}
2) Build → Firestore Database → Create database
3) Избери Native mode, локация (напр. eur3), финализирай
4) Пусни отново: npm run seed

Други причини:
• serviceAccountKey.json е от ДРУГ Google Cloud / Firebase проект
• Проектът е изтрит или project_id в ключа не съвпада с приложението
`);
    return;
  }
  if (code === 7 || msg.toLowerCase().includes('permission')) {
    console.error(`
Няма права за запис в Firestore. Провери в Google Cloud Console → IAM дали
service account има роля „Cloud Datastore User“ или „Firebase Admin“ / Editor.
`);
    return;
  }
  console.error(e);
}

main().catch((e) => {
  explainSeedError(e);
  process.exit(1);
});
