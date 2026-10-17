// Accès à la base Postgres.
//
// En production (Render), la connexion vient de DATABASE_URL : Neon ou toute
// autre base Postgres. En local, si DATABASE_URL est absente, on utilise PGlite
// (Postgres compilé en WebAssembly) pour pouvoir tout tester sans serveur.
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const DOSSIER = path.dirname(fileURLToPath(import.meta.url));
const CHEMIN_SCHEMA = path.join(DOSSIER, 'schema.sql');

let executer;
let executerScript;
let fermer = async () => {};
let description = '';

export async function initialiserBase() {
  const url = process.env.DATABASE_URL;

  if (url) {
    const { default: pg } = await import('pg');
    const local = /localhost|127\.0\.0\.1/.test(url);
    // `sslmode` et `channel_binding` sont retirés de l'URL : le TLS est piloté
    // explicitement ci-dessous, ce qui évite les avertissements de pg et garde
    // la vérification du certificat active (sauf demande contraire).
    const adresse = new URL(url);
    adresse.searchParams.delete('sslmode');
    adresse.searchParams.delete('channel_binding');
    const pool = new pg.Pool({
      connectionString: adresse.toString(),
      ssl: local ? false : { rejectUnauthorized: process.env.DATABASE_SSL_VERIFY !== 'false' },
      max: 5,
    });
    executer = (texte, params = []) => pool.query(texte, params);
    executerScript = (texte) => pool.query(texte);
    fermer = () => pool.end();
    description = 'Postgres (DATABASE_URL)';
  } else {
    if (process.env.NODE_ENV === 'production') {
      throw new Error(
        'DATABASE_URL est obligatoire en production : sans elle, les abonnements seraient perdus au redéploiement.',
      );
    }
    const { PGlite } = await import('@electric-sql/pglite');
    const base = new PGlite(process.env.PGLITE_DIR || path.join(DOSSIER, '..', '.pglite'));
    await base.waitReady;
    executer = (texte, params = []) => base.query(texte, params);
    // exec() accepte plusieurs instructions séparées par « ; » (protocole simple).
    executerScript = (texte) => base.exec(texte);
    fermer = () => base.close();
    description = 'PGlite local (aucune DATABASE_URL fournie)';
  }

  const schema = await readFile(CHEMIN_SCHEMA, 'utf8');
  await executerScript(schema);
  console.log(`Base initialisée : ${description}`);
  return description;
}

export function sourceBase() {
  return description;
}

async function requete(texte, params = []) {
  if (!executer) throw new Error('Base non initialisée.');
  const resultat = await executer(texte, params);
  return resultat.rows;
}

export async function fermerBase() {
  await fermer();
}

// ---------- Versions publiées ----------

export async function listerVersions() {
  return requete(
    `SELECT id, version, titre, notes, lien_apk, publiee_le
       FROM versions
      ORDER BY publiee_le DESC, id DESC`,
  );
}

export async function derniereVersion() {
  const lignes = await requete(
    `SELECT id, version, titre, notes, lien_apk, publiee_le
       FROM versions
      ORDER BY publiee_le DESC, id DESC
      LIMIT 1`,
  );
  return lignes[0] ?? null;
}

export async function creerVersion({ version, titre, notes, lienApk, publieeLe }) {
  const lignes = await requete(
    `INSERT INTO versions (version, titre, notes, lien_apk, publiee_le)
          VALUES ($1, $2, $3, $4, COALESCE($5::date, CURRENT_DATE))
       ON CONFLICT (version) DO NOTHING
       RETURNING id`,
    [version, titre, notes, lienApk, publieeLe || null],
  );
  return lignes[0]?.id ?? null;
}

export async function supprimerVersion(id) {
  const lignes = await requete('DELETE FROM versions WHERE id = $1 RETURNING id', [id]);
  return Boolean(lignes[0]);
}

// ---------- Abonnements ----------

export async function enregistrerAbonnement({
  nom,
  email,
  boutique,
  telephone,
  formule,
  message,
}) {
  const lignes = await requete(
    `INSERT INTO abonnements (nom, email, boutique, telephone, formule, message)
          VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (LOWER(email)) DO NOTHING
       RETURNING id`,
    [nom, email, boutique, telephone, formule, message],
  );
  return { cree: Boolean(lignes[0]), id: lignes[0]?.id ?? null };
}

export async function listerAbonnements() {
  return requete(
    `SELECT id, nom, email, boutique, telephone, formule, message, statut, cree_le
       FROM abonnements
      ORDER BY cree_le DESC, id DESC`,
  );
}

export async function compterAbonnements() {
  const lignes = await requete('SELECT COUNT(*)::int AS total FROM abonnements');
  return lignes[0]?.total ?? 0;
}

export async function definirStatutAbonnement(id, statut) {
  const map = { nouveau: 'nouveau', contacte: 'contacte', abonne: 'abonne' };
  const valeur = map[statut];
  if (!valeur) return false;
  const lignes = await requete(
    'UPDATE abonnements SET statut = $2 WHERE id = $1 RETURNING id',
    [id, valeur],
  );
  return Boolean(lignes[0]);
}
