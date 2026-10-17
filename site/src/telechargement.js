// Téléchargement direct de l'APK.
//
// Le visiteur ne quitte jamais le site : le serveur sert le fichier avec un
// en-tête `Content-Disposition: attachment`. Trois sources possibles, dans
// cet ordre :
//   1. APK_PATH : fichier local déjà présent (développement, disque Render) ;
//   2. cache local du fichier déjà téléchargé une fois ;
//   3. URL source enregistrée pour la version (ou LIEN_APK) : le serveur la
//      récupère, la met en cache et la renvoie en flux au visiteur.
import crypto from 'node:crypto';
import { createReadStream, createWriteStream } from 'node:fs';
import { mkdir, rename, stat, unlink } from 'node:fs/promises';
import path from 'node:path';
import { PassThrough, Readable, pipeline } from 'node:stream';

import { derniereVersion, listerVersions } from './db.js';

const TYPE_APK = 'application/vnd.android.package-archive';

function dossierCache() {
  return process.env.APK_CACHE_DIR || path.resolve(import.meta.dirname, '..', '.apk');
}

function nomFichier(version) {
  return `ma-boutique${version ? `-${version.replace(/[^0-9A-Za-z._-]/g, '')}` : ''}.apk`;
}

/// Nom de cache dérivé de l'URL source : le pré-téléchargement fait au build
/// et le téléchargement à la demande retrouvent le même fichier.
export function cheminCache(url) {
  const cle = crypto.createHash('sha1').update(url).digest('hex').slice(0, 12);
  return path.join(dossierCache(), `apk-${cle}.apk`);
}

async function existe(chemin) {
  try {
    const infos = await stat(chemin);
    return infos.isFile() ? infos : null;
  } catch {
    return null;
  }
}

async function versionDemandee(demandee) {
  const versions = await listerVersions();
  if (demandee) {
    return versions.find((v) => v.version === demandee) ?? null;
  }
  return versions[0] ?? (await derniereVersion());
}

/** Source distante à utiliser quand aucun fichier local n'existe. */
function sourceDistante(version) {
  return version?.lien_apk || process.env.LIEN_APK || '';
}

async function servirFichier(res, chemin, infos, fichier) {
  res.setHeader('Content-Type', TYPE_APK);
  res.setHeader('Content-Length', infos.size);
  res.setHeader('Content-Disposition', `attachment; filename="${fichier}"`);
  res.setHeader('Cache-Control', 'public, max-age=3600');
  createReadStream(chemin).pipe(res);
}

/** Télécharge la source distante en cache puis la renvoie au visiteur. */
async function servirDepuisSource(res, url, nom) {
  const dossier = dossierCache();
  await mkdir(dossier, { recursive: true });

  const reponse = await fetch(url, { redirect: 'follow' });
  if (!reponse.ok || !reponse.body) {
    throw Object.assign(new Error(`Source APK indisponible (${reponse.status})`), { statut: 502 });
  }

  // Garde-fou : une URL qui renvoie une page web (au lieu d'un binaire) ne doit
  // jamais être présentée au visiteur comme l'application.
  const type = (reponse.headers.get('content-type') || '').toLowerCase();
  const estBinaire = /octet-stream|android|zip/.test(type) || /\.apk(\?|$)/i.test(url);
  if (!estBinaire) {
    throw Object.assign(new Error(`Source non binaire (${type || 'sans type'})`), { statut: 502 });
  }

  const longueur = Number(reponse.headers.get('content-length') || 0);
  const final = cheminCache(url);
  const temporaire = `${final}.part`;

  res.setHeader('Content-Type', TYPE_APK);
  res.setHeader('Content-Disposition', `attachment; filename="${nom}"`);
  res.setHeader('Cache-Control', 'public, max-age=3600');
  if (longueur > 0) res.setHeader('Content-Length', String(longueur));

  // Un seul passage réseau : le flux est dupliqué vers le disque et vers le
  // visiteur. Aucun fichier de 200 Mo n'est gardé en mémoire.
  const tee = new PassThrough();
  const ecriture = pipeline(tee, createWriteStream(temporaire));
  const envoi = pipeline(tee, res);
  Readable.fromWeb(reponse.body).pipe(tee);

  const [resultatEcriture] = await Promise.allSettled([ecriture, envoi]);
  if (resultatEcriture.status === 'fulfilled') {
    await rename(temporaire, final).catch(() => unlink(temporaire).catch(() => {}));
  } else {
    await unlink(temporaire).catch(() => {});
  }
}

export async function servirApk(req, res, versionParametre) {
  const version = await versionDemandee(versionParametre);
  const nom = nomFichier(version?.version);

  const local = process.env.APK_PATH ? await existe(process.env.APK_PATH) : null;
  if (local) {
    await servirFichier(res, process.env.APK_PATH, local, nom);
    return true;
  }

  const url = sourceDistante(version);
  if (url) {
    const cache = await existe(cheminCache(url));
    if (cache) {
      await servirFichier(res, cheminCache(url), cache, nom);
      return true;
    }
  }

  if (!url) {
    res.status(404).type('html').send(
      `<!doctype html><html lang="fr"><meta charset="utf-8">
       <title>APK indisponible</title>
       <p>Aucun fichier APK n'est encore publié. Ajoutez une version avec son lien
       source depuis le back-office.</p>`,
    );
    return false;
  }

  try {
    await servirDepuisSource(res, url, nom);
    return true;
  } catch (erreur) {
    if (res.headersSent) return false;
    res.status(502).type('html').send(
      `<!doctype html><html lang="fr"><meta charset="utf-8">
       <title>Téléchargement momentanément indisponible</title>
       <p>Le fichier source n'a pas pu être récupéré. Réessayez dans quelques minutes.</p>`,
    );
    console.warn(`APK: ${erreur.message}`);
    return false;
  }
}

export function urlTelechargement(version) {
  return version ? `/telechargement/ma-boutique-${version}.apk` : '/telechargement/ma-boutique.apk';
}
