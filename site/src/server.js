// Point d'entrée : initialise la base puis écoute sur le port fourni par Render.
import { creerApplication } from './app.js';
import { creerVersion, fermerBase, initialiserBase, listerVersions } from './db.js';

const PORT = Number(process.env.PORT) || 3000;

await initialiserBase();

// Première publication : uniquement si le journal est vide, pour ne jamais
// écraser une version ajoutée depuis le back-office.
if ((await listerVersions()).length === 0) {
  await creerVersion({
    version: process.env.VERSION_INITIALE || '1.0.0',
    titre: 'Mise en ligne de Ma Boutique',
    notes:
      "Première version publiée : gestion du stock, ventes, caisse, retours, dépenses et pointage.\n" +
      'Fonctionnement hors ligne et synchronisation temps réel entre les appareils de la boutique.',
    lienApk: process.env.LIEN_APK || 'https://github.com/zidane2001/GestionDestockMobile/releases',
    publieeLe: null,
  });
  console.log('Version initiale publiée dans le journal.');
}

const app = creerApplication();
const serveur = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Site Ma Boutique à l'écoute sur http://0.0.0.0:${PORT}`);
});

async function arreter(signal) {
  console.log(`${signal} reçu, arrêt du serveur.`);
  serveur.close(async () => {
    await fermerBase();
    process.exit(0);
  });
  setTimeout(() => process.exit(0), 5000).unref();
}

process.on('SIGTERM', () => arreter('SIGTERM'));
process.on('SIGINT', () => arreter('SIGINT'));
