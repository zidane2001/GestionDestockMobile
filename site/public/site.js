// Comportements côté navigateur : envoi du formulaire d'abonnement sans rechargement.
(() => {
  const formulaire = document.getElementById('formulaire-abonnement');
  if (!formulaire) return;

  const statut = document.getElementById('statut-abonnement');
  const bouton = formulaire.querySelector('button[type="submit"]');

  function afficher(etat, texte) {
    statut.dataset.etat = etat;
    statut.textContent = texte;
  }

  formulaire.addEventListener('submit', async (evenement) => {
    evenement.preventDefault();

    const donnees = new FormData(formulaire);
    const charge = Object.fromEntries(donnees.entries());

    bouton.disabled = true;
    afficher('', 'Envoi en cours…');

    try {
      const reponse = await fetch('/api/abonnements', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(charge),
      });
      const resultat = await reponse.json();

      if (reponse.ok && resultat.ok) {
        afficher('succes', resultat.message);
        formulaire.reset();
      } else {
        afficher('erreur', resultat.message || 'La demande n’a pas pu être envoyée.');
      }
    } catch {
      afficher(
        'erreur',
        'Le serveur est injoignable. Vérifiez votre connexion puis réessayez.',
      );
    } finally {
      bouton.disabled = false;
    }
  });
})();
