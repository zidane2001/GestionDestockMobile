// Relie une version publiée à la source de son APK.
//
// Usage :
//   node --env-file=.env scripts/lier-apk.mjs 1.0.0 https://…/ma-boutique.apk
//   node --env-file=.env scripts/lier-apk.mjs --tout https://…/ma-boutique.apk
import { creerLienVersion, fermerBase, initialiserBase, listerVersions } from '../src/db.js';

const [, , premier, deuxieme] = process.argv;
if (!premier || !deuxieme) {
  console.error('Usage: node --env-file=.env scripts/lier-apk.mjs <version|--tout> <url>');
  process.exit(2);
}

await initialiserBase();
const versions = await listerVersions();

if (premier === '--tout') {
  for (const v of versions) {
    await creerLienVersion(v.version, deuxieme);
    console.log(`v${v.version} → ${deuxieme}`);
  }
} else {
  const cible = versions.find((v) => v.version === premier);
  if (!cible) {
    console.error(`Version introuvable : ${premier}. Existantes : ${versions.map((v) => v.version).join(', ')}`);
    await fermerBase();
    process.exit(1);
  }
  await creerLienVersion(cible.version, deuxieme);
  console.log(`v${cible.version} → ${deuxieme}`);
}

const apres = await listerVersions();
console.log(`Versions en base : ${apres.map((v) => `v${v.version}`).join(', ')}`);
await fermerBase();
