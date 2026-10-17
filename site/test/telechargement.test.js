// Tests du téléchargement direct de l'APK : le fichier part du site, avec un
// en-tête `attachment`, sans redirection vers un hébergeur externe.
import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

process.env.NODE_ENV = 'test';
process.env.ADMIN_PASSWORD = 'motdepasse-de-test';
process.env.SESSION_SECRET = 'secret-de-signature-de-test-32-caracteres';

const dossier = await mkdtemp(path.join(os.tmpdir(), 'mb-apk-test-'));
process.env.PGLITE_DIR = await mkdtemp(path.join(os.tmpdir(), 'mb-base-test-'));
process.env.APK_CACHE_DIR = path.join(dossier, 'cache');

const { initialiserBase, fermerBase, creerVersion } = await import('../src/db.js');
const { creerApplication } = await import('../src/app.js');

let serveur;
let base;

before(async () => {
  await initialiserBase();
  serveur = creerApplication().listen(0, '127.0.0.1');
  await new Promise((resoudre) => serveur.once('listening', resoudre));
  base = `http://127.0.0.1:${serveur.address().port}`;
});

after(async () => {
  await new Promise((resoudre) => serveur.close(resoudre));
  await fermerBase();
});

test('sans fichier ni source, le téléchargement explique la situation', async () => {
  const reponse = await fetch(base + '/telechargement/ma-boutique.apk', { redirect: 'manual' });
  assert.equal(reponse.status, 404);
  assert.match(await reponse.text(), /Aucun fichier APK/);
});

test('un APK local est servi directement en pièce jointe', async () => {
  const chemin = path.join(dossier, 'ma-boutique.apk');
  const contenu = 'PK\u0003\u0004 faux apk pour le test';
  await writeFile(chemin, contenu);
  process.env.APK_PATH = chemin;

  const reponse = await fetch(base + '/telechargement/ma-boutique.apk', { redirect: 'manual' });
  assert.equal(reponse.status, 200);
  assert.match(reponse.headers.get('content-type'), /android\.package-archive/);
  assert.match(reponse.headers.get('content-disposition'), /attachment; filename="ma-boutique/);
  assert.equal(await reponse.text(), contenu);
});

test('la version demandée est servie par la même route', async () => {
  await creerVersion({
    version: '2.0.0',
    titre: 'Version test',
    notes: '—',
    lienApk: '',
    publieeLe: null,
  });

  const reponse = await fetch(base + '/telechargement/ma-boutique-2.0.0.apk', {
    redirect: 'manual',
  });
  assert.equal(reponse.status, 200);
  assert.match(reponse.headers.get('content-disposition'), /ma-boutique-2\.0\.0\.apk/);
  assert.doesNotMatch(reponse.headers.get('location') ?? '', /github\.com/);
});

test('une source distante injoignable renvoie une erreur claire', async () => {
  delete process.env.APK_PATH;
  await creerVersion({
    version: '3.0.0',
    titre: 'Source cassée',
    notes: '',
    lienApk: 'http://127.0.0.1:9/inexistant.apk',
    publieeLe: null,
  });

  const reponse = await fetch(base + '/telechargement/ma-boutique-3.0.0.apk', {
    redirect: 'manual',
  });
  assert.equal(reponse.status, 502);
  assert.match(await reponse.text(), /momentanément indisponible/);
});
