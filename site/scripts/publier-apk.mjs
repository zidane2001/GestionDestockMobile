// Dépose un APK dans le stockage objet du projet, puis (si une version est
// donnée) relie cette version à l'URL publique du fichier.
//
// Usage :
//   node --env-file=.env scripts/publier-apk.mjs <fichier.apk> [version]
//
// Exemple :
//   node --env-file=.env scripts/publier-apk.mjs \
//     ../ma_boutique/build/app/outputs/flutter-apk/app-release.apk 1.0.0
//
// L'envoi est découpé en tranches de 8 Mo envoyées quatre par quatre : sur un
// lien montant lent, une tranche ratée est reprise seule au lieu de tout
// recommencer, et la progression s'affiche au lieu de laisser croire à un blocage.
//
// Variables attendues dans .env : AWS_ENDPOINT_URL_S3, AWS_ACCESS_KEY_ID,
// AWS_SECRET_ACCESS_KEY, AWS_REGION, S3_BUCKET (défaut « versions »).
import { createHash } from 'node:crypto';
import { open, stat } from 'node:fs/promises';
import path from 'node:path';

const [, , chemin, versionDemandee] = process.argv;

if (!chemin) {
  console.error('Usage: node --env-file=.env scripts/publier-apk.mjs <fichier.apk> [version]');
  process.exit(2);
}

const {
  S3Client,
  PutObjectCommand,
  CopyObjectCommand,
  CreateMultipartUploadCommand,
  UploadPartCommand,
  CompleteMultipartUploadCommand,
  AbortMultipartUploadCommand,
} = await import('@aws-sdk/client-s3');

const bucket = process.env.S3_BUCKET || 'versions';
const endpoint = (process.env.AWS_ENDPOINT_URL_S3 || '').replace(/\/$/, '');
const TYPE_APK = 'application/vnd.android.package-archive';

if (!endpoint) {
  console.error('AWS_ENDPOINT_URL_S3 manquante (.env).');
  process.exit(2);
}

const client = new S3Client({
  region: process.env.AWS_REGION || 'us-east-2',
  endpoint,
  forcePathStyle: true,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

const TAILLE_TRANCHE = 8 * 1024 * 1024;
const PARALLELES = 4;
const TENTATIVES = 3;

const infos = await stat(chemin);
const total = infos.size;
const nom = path.basename(chemin);

if (total < 1024) {
  console.error(`${nom} est vide ou tronqué (${total} octets).`);
  process.exit(1);
}

// Une archive APK commence par « PK ». Envoyer autre chose (une page HTML
// téléchargée par erreur) casserait tous les téléchargements sans rien dire.
const poignee = Buffer.alloc(2);
const verif = await open(chemin, 'r');
await verif.read(poignee, 0, 2, 0);
await verif.close();
if (poignee.toString('latin1') !== 'PK') {
  console.error(`${nom} n'est pas une archive APK (en-tête inattendu).`);
  process.exit(1);
}

console.log(`Fichier : ${nom} (${(total / 1024 / 1024).toFixed(1)} Mo)`);
console.log(`Destination : ${endpoint}/${bucket}/${cleFichier()}`);

const empreinte = await sha256(chemin);
console.log(`SHA-256 : ${empreinte}`);

const cle = cleFichier();
const debut = Date.now();
const debutEnvoi = Date.now();
let derniereAffichage = 0;
await televerser(chemin, cle, total);
const secondes = (Date.now() - debut) / 1000;
console.log(`Envoyé en ${secondes.toFixed(0)} s (${(total / 1024 / 1024 / secondes).toFixed(2)} Mo/s).`);

// Alias stable : le bouton d'accueil pointe toujours vers la dernière version.
await client.send(
  new CopyObjectCommand({
    Bucket: bucket,
    CopySource: `${bucket}/${encodeURIComponent(cle)}`,
    Key: 'ma-boutique.apk',
    ContentType: TYPE_APK,
    MetadataDirective: 'REPLACE',
  }),
);
console.log(`Alias : ${endpoint}/${bucket}/ma-boutique.apk`);

const url = `${endpoint}/${bucket}/ma-boutique.apk`;
const urlVersion = `${endpoint}/${bucket}/${cle}`;

const publiq = await verifierLecturePublique(url);
if (!publiq) {
  console.warn(
    'Lecture anonyme refusée : le site devra signer ses requêtes (variables AWS_* côté Render).',
  );
}

if (versionDemandee) {
  await relierVersion(versionDemandee, urlVersion);
}

console.log(`\nURL version : ${urlVersion}`);
console.log(`URL stable  : ${url}`);
console.log(`Taille      : ${total} octets`);
console.log(`SHA-256     : ${empreinte}`);

// ---------- outils ----------

function cleFichier() {
  if (!versionDemandee) return 'ma-boutique.apk';
  const propre = versionDemandee.replace(/[^0-9A-Za-z._-]/g, '');
  return `ma-boutique-${propre}.apk`;
}

async function sha256(fichier) {
  const hash = createHash('sha256');
  const fd = await open(fichier, 'r');
  const tampon = Buffer.alloc(1024 * 1024);
  let position = 0;
  try {
    for (;;) {
      const { bytesRead } = await fd.read(tampon, 0, tampon.length, position);
      if (!bytesRead) break;
      position += bytesRead;
      hash.update(tampon.subarray(0, bytesRead));
    }
  } finally {
    await fd.close();
  }
  return hash.digest('hex');
}

async function televerser(fichier, cleObjet, taille) {
  const fd = await open(fichier, 'r');

  try {
    // Petit fichier : un seul envoi, sans la mécanique multipart.
    if (taille <= TAILLE_TRANCHE) {
      const contenu = Buffer.alloc(taille);
      await fd.read(contenu, 0, taille, 0);
      await avecReprise(() =>
        client.send(
          new PutObjectCommand({
            Bucket: bucket,
            Key: cleObjet,
            Body: contenu,
            ContentLength: taille,
            ContentType: TYPE_APK,
          }),
        ),
      );
      afficherProgression(taille, taille);
      return;
    }

    const { UploadId } = await client.send(
      new CreateMultipartUploadCommand({ Bucket: bucket, Key: cleObjet, ContentType: TYPE_APK }),
    );

    const nombres = [];
    for (let numero = 1, offset = 0; offset < taille; numero += 1, offset += TAILLE_TRANCHE) {
      nombres.push({ numero, offset, longueur: Math.min(TAILLE_TRANCHE, taille - offset) });
    }

    let envoyees = 0;
    const terminees = [];

    try {
      await parallele(nombres, PARALLELES, async (tranche) => {
        const tampon = Buffer.alloc(tranche.longueur);
        await fd.read(tampon, 0, tranche.longueur, tranche.offset);

        const { ETag } = await avecReprise(() =>
          client.send(
            new UploadPartCommand({
              Bucket: bucket,
              Key: cleObjet,
              UploadId,
              PartNumber: tranche.numero,
              Body: tampon,
              ContentLength: tranche.longueur,
            }),
          ),
        );

        terminees.push({ ETag, PartNumber: tranche.numero });
        envoyees += tranche.longueur;
        afficherProgression(envoyees, taille);
      });

      terminees.sort((a, b) => a.PartNumber - b.PartNumber);
      await client.send(
        new CompleteMultipartUploadCommand({
          Bucket: bucket,
          Key: cleObjet,
          UploadId,
          MultipartUpload: { Parts: terminees },
        }),
      );
    } catch (erreur) {
      await client
        .send(new AbortMultipartUploadCommand({ Bucket: bucket, Key: cleObjet, UploadId }))
        .catch(() => {});
      throw erreur;
    }
  } finally {
    await fd.close();
  }
}

function afficherProgression(faits, taille) {
  const maintenant = Date.now();
  if (maintenant - derniereAffichage < 2000 && faits < taille) return;
  derniereAffichage = maintenant;

  const pourcent = ((faits / taille) * 100).toFixed(1);
  const ecoule = Math.max((maintenant - debutEnvoi) / 1000, 0.5);
  const debit = faits / 1024 / 1024 / ecoule;
  const reste = debit > 0 ? (taille - faits) / 1024 / 1024 / debit : 0;
  const temps = reste > 60 ? `${Math.round(reste / 60)} min` : `${Math.round(reste)} s`;

  console.log(
    `  ${pourcent}% · ${(faits / 1024 / 1024).toFixed(1)}/${(taille / 1024 / 1024).toFixed(1)} Mo · ` +
      `${debit.toFixed(2)} Mo/s · reste ${faits >= taille ? '0 s' : temps}`,
  );
}

async function avecReprise(action) {
  let derniere;
  for (let essai = 1; essai <= TENTATIVES; essai += 1) {
    try {
      return await action();
    } catch (erreur) {
      derniere = erreur;
      if (essai === TENTATIVES) break;
      const attente = 1000 * essai;
      console.warn(`  tentative ${essai} échouée (${erreur.name}) : nouvel essai dans ${attente / 1000} s`);
      await new Promise((suite) => setTimeout(suite, attente));
    }
  }
  throw derniere;
}

async function parallele(elements, largeur, tache) {
  let index = 0;
  const ouvriers = Array.from({ length: Math.min(largeur, elements.length) }, async () => {
    while (index < elements.length) {
      const courant = elements[index];
      index += 1;
      await tache(courant);
    }
  });
  await Promise.all(ouvriers);
}

async function verifierLecturePublique(url) {
  try {
    const reponse = await fetch(url, { headers: { Range: 'bytes=0-1' } });
    const type = reponse.headers.get('content-type') || 'sans type';
    const debut = Buffer.from(await reponse.arrayBuffer()).subarray(0, 2).toString('latin1');
    const ok = (reponse.status === 200 || reponse.status === 206) && debut === 'PK';
    console.log(
      `Contrôle anonyme : ${reponse.status} (${type})${ok ? ' · en-tête APK confirmé' : ''}`,
    );
    return ok;
  } catch (erreur) {
    console.warn(`Contrôle anonyme impossible : ${erreur.message}`);
    return false;
  }
}

async function relierVersion(version, url) {
  try {
    const { creerLienVersion, fermerBase, initialiserBase, listerVersions } = await import(
      '../src/db.js'
    );
    await initialiserBase();
    const connue = (await listerVersions()).some((v) => v.version === version);
    if (!connue) {
      console.warn(`Version ${version} absente de la base : lien non enregistré.`);
      await fermerBase();
      return;
    }
    await creerLienVersion(version, url);
    console.log(`Base : v${version} pointe désormais vers ${url}`);
    await fermerBase();
  } catch (erreur) {
    console.warn(`Lien en base non enregistré (${erreur.message}).`);
  }
}
