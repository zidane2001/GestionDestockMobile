// Tests de bout en bout du site : pages, souscription, back-office, export CSV.
// Exécutés contre une base PGlite temporaire (aucun serveur Postgres requis).
import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

process.env.NODE_ENV = 'test';
process.env.ADMIN_PASSWORD = 'motdepasse-de-test';
process.env.SESSION_SECRET = 'secret-de-signature-de-test-32-caracteres';
process.env.PGLITE_DIR = await mkdtemp(path.join(os.tmpdir(), 'mb-site-test-'));

const { initialiserBase, fermerBase } = await import('../src/db.js');
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

function poster(chemin, corps, cookie) {
  const entetes = { 'Content-Type': 'application/x-www-form-urlencoded' };
  if (cookie) entetes.Cookie = cookie;
  return fetch(base + chemin, {
    method: 'POST',
    headers: entetes,
    body: new URLSearchParams(corps),
    redirect: 'manual',
  });
}

function cookieDe(reponse) {
  const brut = reponse.headers.getSetCookie?.() ?? [];
  const valeur = brut.find((c) => c.startsWith('mb_admin='));
  return valeur ? valeur.split(';')[0] : '';
}

test('la page d’accueil présente la marque et les appels à l’action', async () => {
  const reponse = await fetch(base + '/');
  const html = await reponse.text();
  assert.equal(reponse.status, 200);
  assert.match(reponse.headers.get('content-type'), /text\/html/);
  assert.match(html, /Ma&nbsp;Boutique/);
  assert.match(html, /Souscrire à l'application/);
  assert.match(html, /Télécharger l'APK/);
  assert.match(html, /id="formulaire-abonnement"/);
  assert.match(reponse.headers.get('content-security-policy'), /default-src 'self'/);
});

test('les pages du site répondent et restent accessibles', async () => {
  for (const [chemin, attendu] of [
    ['/fonctionnalites', /Ce que fait Ma Boutique/],
    ['/mises-a-jour', /Journal des versions/],
    ['/installer', /Installer Ma Boutique/],
  ]) {
    const reponse = await fetch(base + chemin);
    assert.equal(reponse.status, 200, chemin);
    assert.match(await reponse.text(), attendu, chemin);
  }
});

test('une page inconnue renvoie une 404 soignée', async () => {
  const reponse = await fetch(base + '/inexistant');
  assert.equal(reponse.status, 404);
  assert.match(await reponse.text(), /Page introuvable/);
});

test('une demande valide est enregistrée', async () => {
  const reponse = await fetch(base + '/api/abonnements', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      nom: 'Awa Traoré',
      email: 'Awa.Traore@Example.com',
      boutique: 'Boutique Awa',
      telephone: '+225 07 00 00 00',
      formule: 'mensuel',
      message: 'Je veux tester sur deux téléphones.',
    }),
  });
  const corps = await reponse.json();
  assert.equal(reponse.status, 201);
  assert.equal(corps.ok, true);
  assert.match(corps.message, /enregistrée/);
});

test('un doublon d’email est refusé proprement, casse comprise', async () => {
  const reponse = await fetch(base + '/api/abonnements', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ nom: 'Awa', email: 'awa.traore@example.com', formule: 'trimestriel' }),
  });
  assert.equal(reponse.status, 409);
  assert.match((await reponse.json()).message, /déjà/);
});

test('les données invalides sont rejetées avec un message clair', async () => {
  const reponse = await fetch(base + '/api/abonnements', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ nom: 'A', email: 'pas-un-email', formule: 'mensuel' }),
  });
  assert.equal(reponse.status, 400);
  const corps = await reponse.json();
  assert.equal(corps.ok, false);
  assert.match(corps.message, /nom/);
});

test('le champ piège des robots ne crée aucune inscription', async () => {
  const avant = await fetch(base + '/admin/abonnes.csv', { redirect: 'manual' });
  assert.equal(avant.status, 302, 'l’export doit exiger une session');

  const reponse = await fetch(base + '/api/abonnements', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      nom: 'Robot',
      email: 'robot@example.com',
      formule: 'mensuel',
      societe: 'Spam SA',
    }),
  });
  assert.equal(reponse.status, 200);
  assert.equal((await reponse.json()).ok, true);
});

test('le back-office refuse un mauvais mot de passe', async () => {
  const reponse = await poster('/admin/connexion', { motdepasse: 'mauvais' });
  assert.equal(reponse.status, 401);
  assert.match(await reponse.text(), /Mot de passe incorrect/);
  assert.equal(cookieDe(reponse), '');
});

test('le back-office accepte le bon mot de passe et crée une session', async () => {
  const reponse = await poster('/admin/connexion', { motdepasse: 'motdepasse-de-test' });
  assert.equal(reponse.status, 302);
  assert.equal(reponse.headers.get('location'), '/admin/tableau-de-bord');
  const cookie = cookieDe(reponse);
  assert.match(cookie, /^mb_admin=\d+\./);

  const tableau = await fetch(base + '/admin/tableau-de-bord', {
    headers: { Cookie: cookie },
    redirect: 'manual',
  });
  assert.equal(tableau.status, 200);
  assert.match(await tableau.text(), /Tableau de bord/);
});

test('une session falsifiée n’ouvre pas le back-office', async () => {
  const reponse = await fetch(base + '/admin/tableau-de-bord', {
    headers: { Cookie: 'mb_admin=9999999999999.signature-invalide' },
    redirect: 'manual',
  });
  assert.equal(reponse.status, 302);
  assert.equal(reponse.headers.get('location'), '/admin');
});

test('publier une version l’ajoute au journal public', async () => {
  const session = await poster('/admin/connexion', { motdepasse: 'motdepasse-de-test' });
  const cookie = cookieDe(session);

  const publication = await poster(
    '/admin/versions',
    {
      version: '1.1.0',
      titre: 'Reprise réseau améliorée',
      notes: 'Reprise automatique après coupure\nNouveau bandeau hors ligne',
      lien_apk: 'https://example.invalid/app-1.1.0.apk',
      publiee_le: '2026-10-17',
    },
    cookie,
  );
  assert.equal(publication.status, 302);

  const journal = await fetch(base + '/mises-a-jour');
  const html = await journal.text();
  assert.match(html, /v1\.1\.0/);
  assert.match(html, /Reprise réseau améliorée/);
  assert.match(html, /Nouveau bandeau hors ligne/);
  assert.match(html, /\/telechargement\/ma-boutique-1\.1\.0\.apk/);
});

test('l’export CSV contient les inscrits et n’est pas public', async () => {
  const anonyme = await fetch(base + '/admin/abonnes.csv', { redirect: 'manual' });
  assert.equal(anonyme.status, 302);

  const session = await poster('/admin/connexion', { motdepasse: 'motdepasse-de-test' });
  const cookie = cookieDe(session);
  const export_ = await fetch(base + '/admin/abonnes.csv', { headers: { Cookie: cookie } });

  assert.equal(export_.status, 200);
  assert.match(export_.headers.get('content-type'), /text\/csv/);
  assert.match(export_.headers.get('content-disposition'), /abonnes-ma-boutique\.csv/);

  const lignes = (await export_.text()).split('\r\n');
  assert.match(lignes[0], /^﻿?date;nom;email/);
  assert.ok(lignes.some((l) => l.includes('awa.traore@example.com')));
  assert.ok(!lignes.some((l) => l.includes('robot@example.com')));
});

test('le statut d’une demande peut être mis à jour', async () => {
  const session = await poster('/admin/connexion', { motdepasse: 'motdepasse-de-test' });
  const cookie = cookieDe(session);

  const tableau = await (await fetch(base + '/admin/tableau-de-bord', { headers: { Cookie: cookie } })).text();
  const identifiant = tableau.match(/\/admin\/abonnements\/(\d+)\/statut/)?.[1];
  assert.ok(identifiant, 'identifiant d’abonnement introuvable');

  const reponse = await poster(
    `/admin/abonnements/${identifiant}/statut`,
    { statut: 'contacte' },
    cookie,
  );
  assert.equal(reponse.status, 302);

  const apres = await (await fetch(base + '/admin/tableau-de-bord', { headers: { Cookie: cookie } })).text();
  assert.match(apres, /value="contacte" selected/);
});

test('le health check répond pour Render', async () => {
  const reponse = await fetch(base + '/health');
  assert.equal(reponse.status, 200);
  assert.equal(await reponse.text(), 'ok');
});
