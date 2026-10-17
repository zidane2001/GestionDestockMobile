// Application Express : pages publiques, API d'abonnement et back-office.
import express from 'express';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  compterAbonnements,
  creerVersion,
  definirStatutAbonnement,
  enregistrerAbonnement,
  listerAbonnements,
  listerVersions,
  supprimerVersion,
} from './db.js';
import {
  cookieDeconnexion,
  cookieSession,
  estAdmin,
  motDePasseConfigure,
  motDePasseValide,
  noterEchec,
  reinitialiserTentatives,
  tropDeTentatives,
} from './auth.js';
import {
  pageAccueil,
  pageErreur,
  pageFonctionnalites,
  pageInstaller,
  pageMisesAJour,
} from './views.js';
import { pageConnexion, pageTableauDeBord } from './admin-views.js';

const DOSSIER = path.dirname(fileURLToPath(import.meta.url));
const PUBLIC = path.join(DOSSIER, '..', 'public');

const FORMULES = new Set(['decouverte', 'mensuel', 'trimestriel']);
const EMAIL = /^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i;

const routeAsync = (gestion) => (req, res, next) =>
  Promise.resolve(gestion(req, res, next)).catch(next);

function nettoyer(valeur, max) {
  return String(valeur ?? '').trim().slice(0, max);
}

/** Limitation simple en mémoire : 8 demandes d'abonnement par heure et par IP. */
const demandesParIp = new Map();

function quotaAbonnementDepasse(ip) {
  const entree = demandesParIp.get(ip);
  if (!entree || Date.now() - entree.debut > 60 * 60 * 1000) {
    demandesParIp.set(ip, { debut: Date.now(), nombre: 1 });
    return false;
  }
  entree.nombre += 1;
  return entree.nombre > 8;
}

function csv(valeur) {
  const texte = String(valeur ?? '');
  return /[";\n\r]/.test(texte) ? `"${texte.replaceAll('"', '""')}"` : texte;
}

export function creerApplication() {
  const app = express();
  app.disable('x-powered-by');
  app.set('trust proxy', 1);

  app.use((req, res, suite) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader(
      'Content-Security-Policy',
      "default-src 'self'; img-src 'self' data:; form-action 'self'; base-uri 'none'; frame-ancestors 'none'; object-src 'none'",
    );
    suite();
  });

  app.use(express.json({ limit: '32kb' }));
  app.use(express.urlencoded({ extended: false, limit: '32kb' }));
  app.use(
    express.static(PUBLIC, {
      maxAge: process.env.NODE_ENV === 'production' ? '7d' : 0,
      extensions: false,
    }),
  );

  // ---------- Pages publiques ----------

  app.get(
    '/',
    routeAsync(async (req, res) => {
      const [versions, abonnes] = await Promise.all([listerVersions(), compterAbonnements()]);
      res.type('html').send(pageAccueil({ versions, abonnes }));
    }),
  );

  app.get('/fonctionnalites', (req, res) => {
    res.type('html').send(pageFonctionnalites());
  });

  app.get(
    '/mises-a-jour',
    routeAsync(async (req, res) => {
      const versions = await listerVersions();
      res.type('html').send(pageMisesAJour({ versions }));
    }),
  );

  app.get(
    '/installer',
    routeAsync(async (req, res) => {
      const versions = await listerVersions();
      res.type('html').send(pageInstaller({ versions }));
    }),
  );

  app.get('/health', (req, res) => res.type('text').send('ok'));

  // ---------- Souscription ----------

  app.post(
    '/api/abonnements',
    routeAsync(async (req, res) => {
      if (quotaAbonnementDepasse(req.ip)) {
        return res.status(429).json({
          ok: false,
          message: 'Trop de demandes envoyées depuis cet appareil. Réessayez plus tard.',
        });
      }

      const corps = req.body ?? {};

      // Champ piège : rempli par les robots, on fait semblant d'accepter.
      if (String(corps.societe ?? '').trim() !== '') {
        return res.json({ ok: true, message: 'Demande enregistrée.' });
      }

      const nom = nettoyer(corps.nom, 80);
      const email = nettoyer(corps.email, 160).toLowerCase();
      const boutique = nettoyer(corps.boutique, 80);
      const telephone = nettoyer(corps.telephone, 25);
      const formule = nettoyer(corps.formule, 20) || 'mensuel';
      const message = nettoyer(corps.message, 1000);

      const erreurs = [];
      if (nom.length < 2) erreurs.push('Indiquez votre nom.');
      if (!EMAIL.test(email)) erreurs.push('Indiquez une adresse email valide.');
      if (!FORMULES.has(formule)) erreurs.push('Formule inconnue.');

      if (erreurs.length) {
        return res.status(400).json({ ok: false, message: erreurs.join(' ') });
      }

      const resultat = await enregistrerAbonnement({
        nom,
        email,
        boutique,
        telephone,
        formule,
        message,
      });

      if (!resultat.cree) {
        return res.status(409).json({
          ok: false,
          message: 'Cette adresse email a déjà une demande enregistrée. Nous vous recontactons.',
        });
      }

      res.status(201).json({
        ok: true,
        message: 'Merci ! Votre demande est enregistrée, nous vous contactons rapidement.',
      });
    }),
  );

  // ---------- Back-office ----------

  app.get(
    '/admin',
    routeAsync(async (req, res) => {
      if (!estAdmin(req)) {
        res.type('html').send(
          pageConnexion({
            erreur: motDePasseConfigure() ? '' : 'ADMIN_PASSWORD n\'est pas configuré sur le serveur.',
          }),
        );
        return;
      }
      res.redirect('/admin/tableau-de-bord');
    }),
  );

  app.post(
    '/admin/connexion',
    routeAsync(async (req, res) => {
      if (!motDePasseConfigure()) {
        res.status(503).type('html').send(
          pageConnexion({ erreur: 'ADMIN_PASSWORD n\'est pas configuré sur le serveur.' }),
        );
        return;
      }
      if (tropDeTentatives(req.ip)) {
        res.status(429).type('html').send(
          pageConnexion({ erreur: 'Trop de tentatives. Réessayez dans quelques minutes.' }),
        );
        return;
      }
      const saisie = String(req.body?.motdepasse ?? '');
      if (!motDePasseValide(saisie)) {
        noterEchec(req.ip);
        res.status(401).type('html').send(pageConnexion({ erreur: 'Mot de passe incorrect.' }));
        return;
      }
      reinitialiserTentatives(req.ip);
      res.setHeader('Set-Cookie', cookieSession());
      res.redirect('/admin/tableau-de-bord');
    }),
  );

  app.post('/admin/deconnexion', (req, res) => {
    res.setHeader('Set-Cookie', cookieDeconnexion());
    res.redirect('/admin');
  });

  app.get(
    '/admin/tableau-de-bord',
    routeAsync(async (req, res) => {
      if (!estAdmin(req)) {
        res.redirect('/admin');
        return;
      }
      const [versions, abonnements] = await Promise.all([listerVersions(), listerAbonnements()]);
      res.type('html').send(pageTableauDeBord({ versions, abonnements }));
    }),
  );

  app.post(
    '/admin/versions',
    routeAsync(async (req, res) => {
      if (!estAdmin(req)) {
        res.redirect('/admin');
        return;
      }
      const version = nettoyer(req.body?.version, 20);
      const titre = nettoyer(req.body?.titre, 120);
      const notes = nettoyer(req.body?.notes, 4000);
      const lienApk = nettoyer(req.body?.lien_apk, 400);
      const publieeLe = nettoyer(req.body?.publiee_le, 10);

      if (!version || !titre) {
        res.redirect('/admin/tableau-de-bord');
        return;
      }
      await creerVersion({ version, titre, notes, lienApk, publieeLe });
      res.redirect('/admin/tableau-de-bord');
    }),
  );

  app.post(
    '/admin/versions/:id/supprimer',
    routeAsync(async (req, res) => {
      if (!estAdmin(req)) {
        res.redirect('/admin');
        return;
      }
      await supprimerVersion(Number(req.params.id));
      res.redirect('/admin/tableau-de-bord');
    }),
  );

  app.post(
    '/admin/abonnements/:id/statut',
    routeAsync(async (req, res) => {
      if (!estAdmin(req)) {
        res.redirect('/admin');
        return;
      }
      await definirStatutAbonnement(Number(req.params.id), nettoyer(req.body?.statut, 20));
      res.redirect('/admin/tableau-de-bord');
    }),
  );

  app.get(
    '/admin/abonnes.csv',
    routeAsync(async (req, res) => {
      if (!estAdmin(req)) {
        res.redirect('/admin');
        return;
      }
      const abonnements = await listerAbonnements();
      const entetes = ['date', 'nom', 'email', 'boutique', 'telephone', 'formule', 'message', 'statut'];
      const lignes = abonnements.map((a) =>
        [
          new Date(a.cree_le).toISOString(),
          a.nom,
          a.email,
          a.boutique,
          a.telephone,
          a.formule,
          a.message,
          a.statut,
        ]
          .map(csv)
          .join(';'),
      );
      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', 'attachment; filename="abonnes-ma-boutique.csv"');
      res.send('\uFEFF' + [entetes.join(';'), ...lignes].join('\r\n'));
    }),
  );

  app.use((req, res) => {
    res.status(404).type('html').send(pageErreur({ code: 404 }));
  });

  // eslint-disable-next-line no-unused-vars
  app.use((erreur, req, res, suite) => {
    console.error('Erreur non gérée :', erreur.message);
    if (res.headersSent) return;
    const statut = erreur.status === 400 ? 400 : 500;
    if (req.path.startsWith('/api/')) {
      res.status(statut).json({ ok: false, message: 'Une erreur est survenue. Réessayez.' });
      return;
    }
    res.status(statut).type('html').send(pageErreur({ code: statut }));
  });

  return app;
}
