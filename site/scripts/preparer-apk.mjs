// Pré-télécharge l'APK publié (LIEN_APK) dans le cache du serveur.
//
// Appelé au build Render : le premier visiteur reçoit alors le fichier
// immédiatement, au lieu d'attendre le rapatriement depuis la source.
// Sans LIEN_APK, le script ne fait rien et ne fait pas échouer le build.
import { mkdir, rename, stat, unlink } from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import path from 'node:path';
import { Readable, pipeline } from 'node:stream';
import { cheminCache } from '../src/telechargement.js';

const url = process.env.LIEN_APK;

if (!url) {
  console.log('LIEN_APK absent : aucun pré-téléchargement (le site le fera à la demande).');
  process.exit(0);
}

const cible = cheminCache(url);
await mkdir(path.dirname(cible), { recursive: true });

try {
  const infos = await stat(cible);
  console.log(`APK déjà en cache (${(infos.size / 1024 / 1024).toFixed(1)} Mo).`);
  process.exit(0);
} catch {
  // Pas encore de cache : on continue.
}

console.log(`Récupération de l'APK depuis ${url}`);
const reponse = await fetch(url, { redirect: 'follow' });

if (!reponse.ok || !reponse.body) {
  console.warn(`Pré-téléchargement ignoré (${reponse.status}) : le site servira à la demande.`);
  process.exit(0);
}

const temporaire = `${cible}.part`;
await pipeline(Readable.fromWeb(reponse.body), createWriteStream(temporaire));

const { size } = await stat(temporaire);
if (size < 1024 * 1024) {
  await unlink(temporaire).catch(() => {});
  console.warn(`Fichier suspect (${size} octets) : pré-téléchargement annulé.`);
  process.exit(0);
}

await rename(temporaire, cible);
console.log(`APK prêt en cache : ${(size / 1024 / 1024).toFixed(1)} Mo.`);
