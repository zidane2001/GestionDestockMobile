// Gabarits HTML des pages publiques. Aucune dépendance de templating :
// des fonctions pures qui renvoient des chaînes, faciles à tester.

export function echapper(valeur = '') {
  return String(valeur)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function dateFr(valeur) {
  if (!valeur) return '';
  const date = valeur instanceof Date ? valeur : new Date(valeur);
  if (Number.isNaN(date.getTime())) return String(valeur);
  return date.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
    timeZone: 'UTC',
  });
}

const LIEN_RELEASES_DEFAUT = 'https://github.com/zidane2001/GestionDestockMobile/releases';

export function lienTelechargement(versions = []) {
  const derniere = versions[0];
  if (derniere?.lien_apk) return derniere.lien_apk;
  return process.env.LIEN_APK || LIEN_RELEASES_DEFAUT;
}

const NAVIGATION = [
  ['/', 'Accueil'],
  ['/fonctionnalites', 'Fonctionnalités'],
  ['/mises-a-jour', 'Mises à jour'],
  ['/installer', 'Installer'],
];

export function layout({ titre, description, contenu, actif = '/', admin = false }) {
  const nav = NAVIGATION.map(
    ([url, libelle]) =>
      `<a href="${url}"${url === actif ? ' aria-current="page"' : ''}>${libelle}</a>`,
  ).join('');

  return `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${echapper(titre)}</title>
<meta name="description" content="${echapper(description)}">
<meta name="theme-color" content="#0b1220">
<link rel="icon" href="/assets/icone.png" type="image/png">
<link rel="stylesheet" href="/styles.css">
</head>
<body${admin ? ' class="page-admin"' : ''}>
<a class="saut" href="#principal">Aller au contenu</a>
<header class="entete">
  <div class="conteneur entete__barre">
    <a class="marque" href="/">
      <img src="/assets/icone.png" alt="" width="34" height="34">
      <span>Ma&nbsp;Boutique</span>
    </a>
    <nav class="entete__nav" aria-label="Navigation principale">${nav}</nav>
    <a class="bouton bouton--petit" href="/#souscrire">Souscrire</a>
  </div>
</header>
<main id="principal">
${contenu}
</main>
<footer class="pied">
  <div class="conteneur pied__grille">
    <div>
      <strong>Ma Boutique</strong>
      <p>Gestion de stock, ventes et caisse pour les commerces de proximité.</p>
    </div>
    <div>
      <strong>Produit</strong>
      <p><a href="/fonctionnalites">Fonctionnalités</a><br>
      <a href="/mises-a-jour">Mises à jour</a><br>
      <a href="/installer">Installer l'application</a></p>
    </div>
    <div>
      <strong>Espace privé</strong>
      <p><a href="/admin">Administration</a><br>
      <a href="/#souscrire">Demander un accès</a></p>
    </div>
  </div>
  <div class="conteneur pied__bas">
    <span>© ${new Date().getFullYear()} Ma Boutique</span>
    <span>Application Android · synchronisation temps réel</span>
  </div>
</footer>
<script src="/site.js" defer></script>
</body>
</html>`;
}

function carteFonctionnalite({ icone, titre, texte }) {
  return `<article class="carte">
    <span class="carte__icone" aria-hidden="true">${icone}</span>
    <h3>${titre}</h3>
    <p>${texte}</p>
  </article>`;
}

function blocVersion(version, { compact = false, lienParDefaut = '' } = {}) {
  const lienVersion = version.lien_apk || lienParDefaut;
  const notes = (version.notes || '')
    .split('\n')
    .map((ligne) => ligne.trim())
    .filter(Boolean)
    .map((ligne) => `<li>${echapper(ligne.replace(/^[-*]\s*/, ''))}</li>`)
    .join('');

  return `<article class="version${compact ? ' version--compacte' : ''}">
    <header class="version__entete">
      <span class="etiquette">v${echapper(version.version)}</span>
      <time datetime="${echapper(version.publiee_le)}">${dateFr(version.publiee_le)}</time>
    </header>
    <h3>${echapper(version.titre)}</h3>
    ${notes ? `<ul class="version__notes">${notes}</ul>` : ''}
    ${
      lienVersion
        ? `<a class="lien-fleche" href="${echapper(lienVersion)}" rel="noopener">Télécharger cette version</a>`
        : ''
    }
  </article>`;
}

export function pageAccueil({ versions = [], abonnes = 0 }) {
  const lien = lienTelechargement(versions);
  const derniere = versions[0];

  const contenu = `
<section class="hero">
  <div class="conteneur hero__grille">
    <div>
      <p class="pastille">Application Android · gestion de boutique</p>
      <h1>Votre boutique tient dans votre poche.</h1>
      <p class="hero__texte">
        Stock, ventes, caisse, retours, dépenses et pointage : une seule application,
        pensée pour les commerces de proximité, qui continue de fonctionner quand le
        réseau s'arrête et se synchronise dès qu'il revient.
      </p>
      <div class="hero__actions">
        <a class="bouton" href="#souscrire">Souscrire à l'application</a>
        <a class="bouton bouton--fantome" href="${echapper(lien)}" rel="noopener">
          Télécharger l'APK${derniere ? ` · v${echapper(derniere.version)}` : ''}
        </a>
      </div>
      <dl class="hero__chiffres">
        <div><dt>Fonctionne</dt><dd>hors ligne</dd></div>
        <div><dt>Synchronisation</dt><dd>temps réel</dd></div>
        <div><dt>Rôles</dt><dd>patron, manager, caissière</dd></div>
      </dl>
    </div>
    <figure class="hero__visuel">
      <img src="/assets/captures/accueil.png" alt="Écran d'accueil de l'application Ma Boutique">
    </figure>
  </div>
</section>

<section class="bande">
  <div class="conteneur bande__grille">
    <div><strong>Hors ligne d'abord</strong><span>Les opérations passent en file et partent au retour du réseau.</span></div>
    <div><strong>Multi-appareils</strong><span>Une vente saisie sur un téléphone apparaît sur les autres.</span></div>
    <div><strong>Permissions par rôle</strong><span>Chaque employé ne voit que ce qu'il doit voir.</span></div>
    <div><strong>${abonnes > 0 ? `${echapper(String(abonnes))} demande${abonnes > 1 ? 's' : ''}` : 'Ouvert aux inscriptions'}</strong><span>${abonnes > 1 ? 'reçues via ce site.' : abonnes === 1 ? 'reçue via ce site.' : 'Souscription en quelques secondes.'}</span></div>
  </div>
</section>

<section class="section" id="fonctionnalites">
  <div class="conteneur">
    <header class="section__tete">
      <h2>Tout le quotidien du commerce</h2>
      <p>Les gestes de la journée, sans tableur ni cahier.</p>
    </header>
    <div class="grille grille--3">
      ${carteFonctionnalite({ icone: '▦', titre: 'Stock en temps réel', texte: 'Produits, prix d\'achat et de vente, seuils de rupture, photos et recherche tolérante aux fautes.' })}
      ${carteFonctionnalite({ icone: '₣', titre: 'Ventes et caisse', texte: 'Encaissement, calcul de marge, journal des opérations et solde de caisse recalculé à chaque mouvement.' })}
      ${carteFonctionnalite({ icone: '⟳', titre: 'Retours et dépenses', texte: 'Produits défectueux, échanges, remboursements, sorties de caisse justifiées : tout est tracé.' })}
      ${carteFonctionnalite({ icone: '☍', titre: 'Synchronisation temps réel', texte: 'Les modifications du serveur arrivent en moins d\'une seconde sur les appareils de la boutique.' })}
      ${carteFonctionnalite({ icone: '☂', titre: 'Résistant aux coupures', texte: 'Sans réseau, l\'application continue d\'enregistrer ; la file locale se vide automatiquement au retour.' })}
      ${carteFonctionnalite({ icone: '⚿', titre: 'Rôles et permissions', texte: 'Patron, manager, caissière : droits détaillés, comptes suspendables, appareils révocables.' })}
    </div>
  </div>
</section>

<section class="section section--sombre">
  <div class="conteneur duo">
    <div>
      <h2>Un écran, une décision</h2>
      <p>Le tableau de bord rassemble le chiffre du jour, les alertes de stock et l'activité de l'équipe. Pas de menu à tiroirs : trois onglets, les actions les plus fréquentes à portée de pouce.</p>
      <ul class="liste-puces">
        <li>Vente en deux gestes, y compris sur un produit scanné.</li>
        <li>Alerte immédiate quand un article passe sous son seuil.</li>
        <li>Journal d'activité horodaté pour chaque rôle.</li>
      </ul>
    </div>
    <figure class="duo__image">
      <img src="/assets/captures/stock.png" alt="Écran de gestion du stock de l'application">
    </figure>
  </div>
</section>

<section class="section">
  <div class="conteneur">
    <header class="section__tete">
      <h2>L'application en images</h2>
      <p>Captures prises sur l'APK de production.</p>
    </header>
    <div class="galerie">
      <figure><img src="/assets/captures/creation.png" alt="Formulaire de création de boutique"><figcaption>Créer sa boutique</figcaption></figure>
      <figure><img src="/assets/captures/compte.png" alt="Création d'un compte employé"><figcaption>Comptes et rôles</figcaption></figure>
      <figure><img src="/assets/captures/produit.png" alt="Saisie d'un nouveau produit"><figcaption>Ajout d'un produit</figcaption></figure>
    </div>
  </div>
</section>

<section class="section section--formules" id="formules">
  <div class="conteneur">
    <header class="section__tete">
      <h2>Choisir sa formule</h2>
      <p>Le tarif est confirmé après étude de votre boutique ; l'inscription ne vous engage à rien.</p>
    </header>
    <div class="grille grille--3">
      <article class="carte carte--formule">
        <h3>Découverte</h3>
        <p class="carte__prix">Gratuit</p>
        <ul><li>Une boutique</li><li>Stock et ventes</li><li>Un appareil</li></ul>
      </article>
      <article class="carte carte--formule carte--mise-en-avant">
        <h3>Mensuel</h3>
        <p class="carte__prix">Sur devis</p>
        <ul><li>Appareils illimités</li><li>Synchronisation temps réel</li><li>Support prioritaire</li></ul>
      </article>
      <article class="carte carte--formule">
        <h3>Trimestriel</h3>
        <p class="carte__prix">Sur devis</p>
        <ul><li>Tout le mensuel</li><li>Facturation groupée</li><li>Accompagnement à la mise en route</li></ul>
      </article>
    </div>
  </div>
</section>

<section class="section" id="souscrire">
  <div class="conteneur duo duo--formulaire">
    <div>
      <h2>Souscrire à Ma Boutique</h2>
      <p>Laissez vos coordonnées : votre demande est enregistrée immédiatement et nous revenons vers vous pour activer la boutique et transmettre l'application.</p>
      <ul class="liste-puces">
        <li>Aucun paiement en ligne sur ce site.</li>
        <li>Vos informations servent uniquement à traiter la demande.</li>
        <li>Vous pouvez demander leur suppression à tout moment.</li>
      </ul>
    </div>
    <form class="formulaire" id="formulaire-abonnement" novalidate>
      <div class="champ">
        <label for="nom">Nom complet</label>
        <input id="nom" name="nom" autocomplete="name" required minlength="2" maxlength="80">
      </div>
      <div class="champ">
        <label for="email">Email</label>
        <input id="email" name="email" type="email" autocomplete="email" required maxlength="160">
      </div>
      <div class="champ">
        <label for="boutique">Nom de la boutique</label>
        <input id="boutique" name="boutique" maxlength="80">
      </div>
      <div class="champ">
        <label for="telephone">Téléphone</label>
        <input id="telephone" name="telephone" inputmode="tel" maxlength="25">
      </div>
      <div class="champ">
        <label for="formule">Formule souhaitée</label>
        <select id="formule" name="formule">
          <option value="decouverte">Découverte</option>
          <option value="mensuel" selected>Mensuel</option>
          <option value="trimestriel">Trimestriel</option>
        </select>
      </div>
      <div class="champ champ--large">
        <label for="message">Message (facultatif)</label>
        <textarea id="message" name="message" rows="3" maxlength="1000"></textarea>
      </div>
      <div class="champ champ--piege" aria-hidden="true">
        <label for="societe">Société</label>
        <input id="societe" name="societe" tabindex="-1" autocomplete="off">
      </div>
      <p class="formulaire__statut" id="statut-abonnement" role="status" aria-live="polite"></p>
      <button class="bouton" type="submit">Envoyer ma demande</button>
      <p class="formulaire__mentions">En envoyant ce formulaire, vous acceptez d'être contacté au sujet de Ma Boutique.</p>
    </form>
  </div>
</section>

<section class="section section--faq">
  <div class="conteneur">
    <header class="section__tete"><h2>Questions fréquentes</h2></header>
    <details><summary>L'application fonctionne-t-elle sans Internet ?</summary><p>Oui. Chaque opération est écrite localement et mise en file ; la synchronisation reprend seule dès que le réseau revient.</p></details>
    <details><summary>Sur quels téléphones ?</summary><p>Android 5.0 et plus. L'APK s'installe depuis le navigateur, en autorisant les sources inconnues.</p></details>
    <details><summary>Plusieurs employés peuvent-ils utiliser la même boutique ?</summary><p>Oui, avec des comptes distincts et des permissions par rôle. Chaque appareil peut être révoqué à distance.</p></details>
    <details><summary>Mes données sont-elles visibles par les autres boutiques ?</summary><p>Non : chaque boutique dispose de son propre espace, et l'accès est cloisonné côté serveur.</p></details>
  </div>
</section>`;

  return layout({
    titre: 'Ma Boutique — gestion de stock et caisse pour commerces',
    description:
      "Application Android de gestion de stock, ventes et caisse pour les commerces de proximité : hors ligne, synchronisation temps réel, rôles et permissions. Souscrivez depuis le site.",
    contenu,
    actif: '/',
  });
}

export function pageFonctionnalites() {
  const contenu = `
<section class="section section--haut">
  <div class="conteneur">
    <header class="section__tete">
      <p class="pastille">Fonctionnalités</p>
      <h1>Ce que fait Ma Boutique, concrètement</h1>
      <p>Chaque fonctionnalité listée ici est présente dans l'application publiée sur ce site.</p>
    </header>
    <div class="grille grille--2">
      <article class="carte"><h3>Stock</h3><ul class="liste-puces">
        <li>Produits avec photo, catégorie, prix d'achat et de vente.</li>
        <li>Recherche instantanée, tolérante aux accents et aux fautes de frappe.</li>
        <li>Signalement des ruptures et des articles peu mouvementés.</li>
        <li>Désactivation d'un produit sans perdre son historique.</li>
      </ul></article>
      <article class="carte"><h3>Ventes et caisse</h3><ul class="liste-puces">
        <li>Encaissement avec quantité et prix ajustable.</li>
        <li>Refus des survontes et des montants incohérents.</li>
        <li>Solde de caisse mis à jour à chaque vente, dépense ou retour.</li>
        <li>Journal horodaté de chaque opération.</li>
      </ul></article>
      <article class="carte"><h3>Retours, dépenses, pointage</h3><ul class="liste-puces">
        <li>Produits défectueux avec description obligatoire.</li>
        <li>Échange ou remboursement, statut de traitement suivi.</li>
        <li>Dépenses et sorties de caisse justifiées.</li>
        <li>Arrivée et départ de chaque employé.</li>
      </ul></article>
      <article class="carte"><h3>Équipe et sécurité</h3><ul class="liste-puces">
        <li>Trois rôles avec permissions détaillées.</li>
        <li>Connexion par mot de passe, code PIN ou biométrie.</li>
        <li>Comptes suspendables, appareils révocables.</li>
        <li>Notifications internes par rôle.</li>
      </ul></article>
      <article class="carte"><h3>Synchronisation</h3><ul class="liste-puces">
        <li>Écriture locale immédiate, envoi en arrière-plan.</li>
        <li>Réception des changements des autres appareils en temps réel.</li>
        <li>Reprise automatique après une coupure réseau.</li>
        <li>File persistée : rien n'est perdu au redémarrage.</li>
      </ul></article>
      <article class="carte"><h3>Abonnement et boutique</h3><ul class="liste-puces">
        <li>Création de boutique en quelques champs.</li>
        <li>Logo, monnaie et préférences de notification.</li>
        <li>Suivi de la période d'abonnement.</li>
        <li>Export et sauvegarde des données locales.</li>
      </ul></article>
    </div>
  </div>
</section>`;
  return layout({
    titre: 'Fonctionnalités — Ma Boutique',
    description:
      "Stock, ventes, caisse, retours, dépenses, pointage, rôles et synchronisation temps réel : le détail des fonctionnalités de l'application Ma Boutique.",
    contenu,
    actif: '/fonctionnalites',
  });
}

export function pageMisesAJour({ versions = [] }) {
  const lienParDefaut = process.env.LIEN_APK || LIEN_RELEASES_DEFAUT;
  const liste = versions.length
    ? versions.map((v) => blocVersion(v, { lienParDefaut })).join('')
    : '<p class="vide">Aucune version publiée pour le moment.</p>';

  const contenu = `
<section class="section section--haut">
  <div class="conteneur">
    <header class="section__tete">
      <p class="pastille">Journal des versions</p>
      <h1>Mises à jour de l'application</h1>
      <p>Chaque publication est ajoutée ici depuis le back-office, avec ses notes et son lien de téléchargement.</p>
    </header>
    <div class="fil-versions">${liste}</div>
  </div>
</section>`;
  return layout({
    titre: 'Mises à jour — Ma Boutique',
    description:
      "Historique des versions de l'application Ma Boutique : notes de version, date de publication et lien de téléchargement.",
    contenu,
    actif: '/mises-a-jour',
  });
}

export function pageInstaller({ versions = [] }) {
  const lien = lienTelechargement(versions);
  const derniere = versions[0];

  const contenu = `
<section class="section section--haut">
  <div class="conteneur etroit">
    <header class="section__tete">
      <p class="pastille">Installation</p>
      <h1>Installer Ma Boutique sur Android</h1>
      <p>L'application se distribue en APK, hors magasin d'applications.${
        derniere ? ` Version courante : <strong>v${echapper(derniere.version)}</strong>.` : ''
      }</p>
    </header>
    <ol class="etapes">
      <li><strong>Télécharger l'APK</strong><span>Depuis <a href="${echapper(lien)}" rel="noopener">la page de téléchargement</a>, sur le téléphone qui servira en boutique.</span></li>
      <li><strong>Autoriser l'installation</strong><span>Android demande d'accepter les applications de source inconnue pour le navigateur ou le gestionnaire de fichiers utilisé.</span></li>
      <li><strong>Ouvrir le fichier</strong><span>L'installation prend quelques secondes ; l'icône Ma Boutique apparaît sur l'écran d'accueil.</span></li>
      <li><strong>Créer ou rejoindre la boutique</strong><span>Au premier lancement, créez la boutique du patron, puis les comptes des employés depuis l'application.</span></li>
    </ol>
    <div class="encadre">
      <h2>À savoir</h2>
      <ul class="liste-puces">
        <li>Android 5.0 ou plus récent est nécessaire.</li>
        <li>Les mises à jour s'installent par-dessus l'ancienne version, sans effacer les données.</li>
        <li>Une connexion est utile pour la synchronisation, pas pour vendre.</li>
      </ul>
    </div>
    <p><a class="bouton" href="${echapper(lien)}" rel="noopener">Télécharger l'APK</a></p>
  </div>
</section>`;
  return layout({
    titre: "Installer l'application — Ma Boutique",
    description:
      "Comment installer l'application Android Ma Boutique : téléchargement de l'APK, autorisation d'installation et première configuration.",
    contenu,
    actif: '/installer',
  });
}

export function pageErreur({ code = 404 }) {
  const contenu = `
<section class="section section--haut">
  <div class="conteneur etroit centre">
    <p class="pastille">Erreur ${code}</p>
    <h1>${code === 404 ? 'Page introuvable' : 'Une erreur est survenue'}</h1>
    <p>Le lien demandé n'existe pas ou a changé.</p>
    <p><a class="bouton" href="/">Retour à l'accueil</a></p>
  </div>
</section>`;
  return layout({
    titre: 'Page introuvable — Ma Boutique',
    description: 'La page demandée est introuvable.',
    contenu,
  });
}
