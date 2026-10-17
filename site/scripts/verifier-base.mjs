// Diagnostic de la base utilisée par le site.
// Usage : node --env-file=.env scripts/verifier-base.mjs
import { compterAbonnements, fermerBase, initialiserBase, listerVersions } from '../src/db.js';

const source = await initialiserBase();
const versions = await listerVersions();
const abonnes = await compterAbonnements();

console.log(`Source : ${source}`);
console.log(`Versions publiées : ${versions.length}`);
for (const v of versions) {
  console.log(`  - v${v.version} · ${v.titre}`);
}
console.log(`Abonnements enregistrés : ${abonnes}`);

await fermerBase();
