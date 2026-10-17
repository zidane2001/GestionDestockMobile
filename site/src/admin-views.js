// Gabarits du back-office protégé : connexion, tableau de bord, versions et abonnés.
import { echapper, layout } from './views.js';

function dateHeure(valeur) {
  if (!valeur) return '';
  const date = valeur instanceof Date ? valeur : new Date(valeur);
  if (Number.isNaN(date.getTime())) return String(valeur);
  return date.toLocaleString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function dateCourte(valeur) {
  if (!valeur) return '';
  const date = valeur instanceof Date ? valeur : new Date(valeur);
  if (Number.isNaN(date.getTime())) return String(valeur).slice(0, 10);
  return date.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    timeZone: 'UTC',
  });
}

export function pageConnexion({ erreur = '', message = '' } = {}) {
  const contenu = `
<section class="section section--haut">
  <div class="conteneur etroit">
    <header class="section__tete">
      <p class="pastille">Espace privé</p>
      <h1>Administration du site</h1>
      <p>Publier une version de l'application et consulter les demandes d'abonnement.</p>
    </header>
    ${erreur ? `<p class="alerte alerte--erreur" role="alert">${echapper(erreur)}</p>` : ''}
    ${message ? `<p class="alerte alerte--succes" role="status">${echapper(message)}</p>` : ''}
    <form class="formulaire" method="post" action="/admin/connexion">
      <div class="champ champ--large">
        <label for="motdepasse">Mot de passe administrateur</label>
        <input id="motdepasse" name="motdepasse" type="password" autocomplete="current-password" required>
      </div>
      <button class="bouton" type="submit">Se connecter</button>
    </form>
  </div>
</section>`;
  return layout({
    titre: 'Administration — Ma Boutique',
    description: 'Espace privé de gestion du site Ma Boutique.',
    contenu,
    admin: true,
  });
}

function tableauVersions(versions) {
  if (!versions.length) return '<p class="vide">Aucune version publiée.</p>';
  const lignes = versions
    .map(
      (v) => `<tr>
        <td><span class="etiquette">v${echapper(v.version)}</span></td>
        <td>${echapper(v.titre)}</td>
        <td>${echapper(dateCourte(v.publiee_le))}</td>
        <td>${v.lien_apk ? `<a href="${echapper(v.lien_apk)}" rel="noopener">lien</a>` : '—'}</td>
        <td>
          <form method="post" action="/admin/versions/${echapper(v.id)}/supprimer" class="en-ligne">
            <button class="bouton bouton--danger bouton--petit" type="submit">Supprimer</button>
          </form>
        </td>
      </tr>`,
    )
    .join('');
  return `<div class="tableau-defilant"><table class="tableau">
    <thead><tr><th>Version</th><th>Titre</th><th>Publiée le</th><th>APK</th><th></th></tr></thead>
    <tbody>${lignes}</tbody>
  </table></div>`;
}

const LIBELLES_STATUT = { nouveau: 'Nouveau', contacte: 'Contacté', abonne: 'Abonné' };

function tableauAbonnes(abonnements) {
  if (!abonnements.length) return '<p class="vide">Aucune demande pour le moment.</p>';
  const lignes = abonnements
    .map(
      (a) => `<tr>
        <td>${dateHeure(a.cree_le)}</td>
        <td><strong>${echapper(a.nom)}</strong><br><a href="mailto:${echapper(a.email)}">${echapper(a.email)}</a></td>
        <td>${echapper(a.boutique || '—')}</td>
        <td>${echapper(a.telephone || '—')}</td>
        <td>${echapper(a.formule)}</td>
        <td>${echapper(a.message || '')}</td>
        <td>
          <form method="post" action="/admin/abonnements/${echapper(a.id)}/statut" class="en-ligne">
            <select name="statut" aria-label="Statut de ${echapper(a.nom)}">
              ${Object.entries(LIBELLES_STATUT)
                .map(
                  ([valeur, libelle]) =>
                    `<option value="${valeur}"${a.statut === valeur ? ' selected' : ''}>${libelle}</option>`,
                )
                .join('')}
            </select>
            <button class="bouton bouton--petit bouton--fantome" type="submit">Mettre à jour</button>
          </form>
        </td>
      </tr>`,
    )
    .join('');
  return `<div class="tableau-defilant"><table class="tableau">
    <thead><tr><th>Reçue le</th><th>Contact</th><th>Boutique</th><th>Téléphone</th><th>Formule</th><th>Message</th><th>Statut</th></tr></thead>
    <tbody>${lignes}</tbody>
  </table></div>`;
}

export function pageTableauDeBord({ versions = [], abonnements = [], message = '' }) {
  const nouveaux = abonnements.filter((a) => a.statut === 'nouveau').length;

  const contenu = `
<section class="section section--haut">
  <div class="conteneur">
    <div class="barre-admin">
      <div>
        <p class="pastille">Back-office</p>
        <h1>Tableau de bord</h1>
      </div>
      <form method="post" action="/admin/deconnexion">
        <button class="bouton bouton--fantome bouton--petit" type="submit">Se déconnecter</button>
      </form>
    </div>
    ${message ? `<p class="alerte alerte--succes" role="status">${echapper(message)}</p>` : ''}

    <div class="grille grille--3 stats-admin">
      <div class="carte"><span class="carte__icone">▤</span><h3>${versions.length}</h3><p>version(s) publiée(s)</p></div>
      <div class="carte"><span class="carte__icone">✉</span><h3>${abonnements.length}</h3><p>demande(s) d'abonnement</p></div>
      <div class="carte"><span class="carte__icone">●</span><h3>${nouveaux}</h3><p>à traiter</p></div>
    </div>

    <section class="bloc-admin">
      <h2>Publier une version</h2>
      <p>La publication apparaît immédiatement sur la page <a href="/mises-a-jour">Mises à jour</a> du site.</p>
      <form class="formulaire formulaire--grille" method="post" action="/admin/versions">
        <div class="champ">
          <label for="version">Numéro de version</label>
          <input id="version" name="version" placeholder="1.1.0" required maxlength="20">
        </div>
        <div class="champ">
          <label for="titre">Titre</label>
          <input id="titre" name="titre" placeholder="Correctifs de synchronisation" required maxlength="120">
        </div>
        <div class="champ">
          <label for="publiee_le">Date de publication</label>
          <input id="publiee_le" name="publiee_le" type="date">
        </div>
        <div class="champ">
          <label for="lien_apk">Lien de téléchargement (facultatif)</label>
          <input id="lien_apk" name="lien_apk" type="url" placeholder="https://github.com/…/releases/download/…">
        </div>
        <div class="champ champ--large">
          <label for="notes">Notes de version (une ligne par point)</label>
          <textarea id="notes" name="notes" rows="5" maxlength="4000" placeholder="Correction de la reprise après coupure réseau&#10;Nouveau bandeau hors ligne"></textarea>
        </div>
        <button class="bouton" type="submit">Publier la version</button>
      </form>
    </section>

    <section class="bloc-admin">
      <h2>Versions publiées</h2>
      ${tableauVersions(versions)}
    </section>

    <section class="bloc-admin">
      <div class="barre-admin">
        <h2>Demandes d'abonnement</h2>
        <a class="bouton bouton--fantome bouton--petit" href="/admin/abonnes.csv">Exporter en CSV</a>
      </div>
      ${tableauAbonnes(abonnements)}
    </section>
  </div>
</section>`;
  return layout({
    titre: 'Tableau de bord — Ma Boutique',
    description: "Back-office du site Ma Boutique : publication des versions et suivi des abonnements.",
    contenu,
    admin: true,
  });
}
