// Copie les captures existantes du dépôt dans les assets du site.
// Lancer depuis site/ : npm run captures
import { copyFile, mkdir, stat } from 'node:fs/promises';
import path from 'node:path';

const racine = path.resolve(import.meta.dirname, '..', '..');
const sortie = path.resolve(import.meta.dirname, '..', 'public', 'assets');

const captures = [
  ['emulateur_accueil.png', 'captures/accueil.png'],
  ['ma_boutique/qa/evidence/2026-10-16/03-stock.png', 'captures/stock.png'],
  ['emulateur_creation_boutique.png', 'captures/creation.png'],
  ['qa_compte_cree.png', 'captures/compte.png'],
  ['qa_produit_saisie.png', 'captures/produit.png'],
  ['ma_boutique/assets/icon_smart_stock.png', 'icone.png'],
];

await mkdir(path.join(sortie, 'captures'), { recursive: true });

for (const [source, cible] of captures) {
  const depuis = path.join(racine, source);
  const vers = path.join(sortie, cible);
  try {
    await copyFile(depuis, vers);
    const { size } = await stat(vers);
    console.log(`${cible.padEnd(26)} ${(size / 1024).toFixed(0)} Ko  ← ${source}`);
  } catch (erreur) {
    console.warn(`Ignoré (${source}) : ${erreur.code ?? erreur.message}`);
  }
}
