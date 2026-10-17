// Authentification du back-office.
//
// Un seul compte administrateur : le mot de passe vient de ADMIN_PASSWORD
// (variable d'environnement Render). La session est un cookie signé HMAC,
// SameSite=Strict, sans état côté serveur.
import crypto from 'node:crypto';

const COOKIE = 'mb_admin';
const DUREE_MS = 8 * 60 * 60 * 1000;

function secret() {
  const valeur = process.env.SESSION_SECRET;
  if (!valeur || valeur.length < 16) {
    throw new Error(
      'SESSION_SECRET est obligatoire (16 caractères minimum) pour signer les sessions.',
    );
  }
  return valeur;
}

export function motDePasseConfigure() {
  return Boolean(process.env.ADMIN_PASSWORD && process.env.ADMIN_PASSWORD.length >= 8);
}

/** Comparaison à temps constant : évite de fuiter le mot de passe par le timing. */
export function motDePasseValide(saisie) {
  const attendu = process.env.ADMIN_PASSWORD || '';
  if (!attendu) return false;
  const a = crypto.createHash('sha256').update(String(saisie)).digest();
  const b = crypto.createHash('sha256').update(attendu).digest();
  return crypto.timingSafeEqual(a, b);
}

function signer(corps) {
  return crypto.createHmac('sha256', secret()).update(corps).digest('base64url');
}

export function creerSession() {
  const corps = String(Date.now() + DUREE_MS);
  return `${corps}.${signer(corps)}`;
}

export function sessionValide(valeur) {
  if (typeof valeur !== 'string' || !valeur.includes('.')) return false;
  const [corps, signature] = valeur.split('.');
  if (!corps || !signature) return false;
  const attendu = signer(corps);
  const ok =
    signature.length === attendu.length &&
    crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(attendu));
  if (!ok) return false;
  return Number(corps) > Date.now();
}

export function lireCookies(entete = '') {
  const out = {};
  for (const morceau of entete.split(';')) {
    const index = morceau.indexOf('=');
    if (index === -1) continue;
    out[morceau.slice(0, index).trim()] = decodeURIComponent(morceau.slice(index + 1).trim());
  }
  return out;
}

export function cookieSession() {
  const securise = process.env.NODE_ENV === 'production' ? '; Secure' : '';
  return `${COOKIE}=${creerSession()}; HttpOnly; Path=/; SameSite=Strict; Max-Age=${
    DUREE_MS / 1000
  }${securise}`;
}

export function cookieDeconnexion() {
  return `${COOKIE}=; HttpOnly; Path=/; SameSite=Strict; Max-Age=0`;
}

export function estAdmin(req) {
  return sessionValide(lireCookies(req.headers.cookie)[COOKIE]);
}

/** Limitation des tentatives de connexion : 6 essais par quart d'heure et par IP. */
const tentatives = new Map();

export function tropDeTentatives(ip) {
  const entree = tentatives.get(ip);
  if (!entree) return false;
  if (Date.now() - entree.debut > 15 * 60 * 1000) {
    tentatives.delete(ip);
    return false;
  }
  return entree.nombre >= 6;
}

export function noterEchec(ip) {
  const entree = tentatives.get(ip);
  if (!entree || Date.now() - entree.debut > 15 * 60 * 1000) {
    tentatives.set(ip, { debut: Date.now(), nombre: 1 });
    return;
  }
  entree.nombre += 1;
}

export function reinitialiserTentatives(ip) {
  tentatives.delete(ip);
}
