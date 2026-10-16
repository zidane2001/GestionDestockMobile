import { Depense, Produit, Vente } from '../types';

export interface PointSerie {
  cle: string;
  label: string;
  valeur: number;
}

function debutJour(d: Date): Date {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

/** Série journalière du chiffre d'affaires (ou de la marge) sur N jours glissants. */
export function serieJournaliere(
ventes: Vente[],
jours: number,
mesure: 'ca' | 'marge' = 'ca')
: PointSerie[] {
  const base = debutJour(new Date());
  const points: PointSerie[] = [];
  for (let i = jours - 1; i >= 0; i--) {
    const jour = new Date(base.getTime() - i * 86_400_000);
    const cle = jour.toISOString().slice(0, 10);
    const total = ventes.
    filter((v) => v.date.slice(0, 10) === cle).
    reduce(
      (s, v) =>
      s + (
      mesure === 'ca' ?
      v.total :
      (v.prixUnitaireReel - v.prixAchatUnitaire) * v.quantite),
      0
    );
    points.push({
      cle,
      label: jour.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' }),
      valeur: total
    });
  }
  return points;
}

export function ventesRecentes(ventes: Vente[], jours: number): Vente[] {
  const limite = Date.now() - jours * 86_400_000;
  return ventes.filter((v) => new Date(v.date).getTime() >= limite);
}

export function chiffreAffaires(ventes: Vente[]): number {
  return ventes.reduce((s, v) => s + v.total, 0);
}

export function margeTotale(ventes: Vente[]): number {
  return ventes.reduce((s, v) => s + (v.prixUnitaireReel - v.prixAchatUnitaire) * v.quantite, 0);
}

export function beneficeNet(ventes: Vente[], depenses: Depense[]): number {
  return margeTotale(ventes) - depenses.reduce((s, d) => s + d.montant, 0);
}

export function piecesVendues(ventes: Vente[]): number {
  return ventes.reduce((s, v) => s + v.quantite, 0);
}

export interface LigneProduit {
  produitId: string;
  nom: string;
  pieces: number;
  ca: number;
  marge: number;
}

export function classementProduits(ventes: Vente[]): LigneProduit[] {
  const map = new Map<string, LigneProduit>();
  ventes.forEach((v) => {
    const l =
    map.get(v.produitId) ??
    { produitId: v.produitId, nom: v.produitNom, pieces: 0, ca: 0, marge: 0 };
    l.pieces += v.quantite;
    l.ca += v.total;
    l.marge += (v.prixUnitaireReel - v.prixAchatUnitaire) * v.quantite;
    map.set(v.produitId, l);
  });
  return [...map.values()].sort((a, b) => b.pieces - a.pieces);
}

/** Variation en % entre la période courante et la précédente, de même durée. */
export function tendance(ventes: Vente[], jours: number): number {
  const maintenant = Date.now();
  const courant = chiffreAffaires(
    ventes.filter((v) => new Date(v.date).getTime() >= maintenant - jours * 86_400_000)
  );
  const precedent = chiffreAffaires(
    ventes.filter((v) => {
      const t = new Date(v.date).getTime();
      return t < maintenant - jours * 86_400_000 && t >= maintenant - 2 * jours * 86_400_000;
    })
  );
  if (precedent === 0) return courant > 0 ? 100 : 0;
  return Math.round((courant - precedent) / precedent * 100);
}

export function valeurStock(produits: Produit[]): number {
  return produits.filter((p) => p.actif).reduce((s, p) => s + p.prixVente * p.quantite, 0);
}

/** Recherche tolérante aux fautes : sous-chaîne, puis distance de Levenshtein. */
export function rechercheProduits(produits: Produit[], requete: string): Produit[] {
  const q = requete.trim().toLowerCase();
  if (!q) return produits;
  const exacts = produits.filter((p) => p.nom.toLowerCase().includes(q));
  if (exacts.length > 0) return exacts;
  return produits.
  map((p) => ({
    p,
    score: Math.min(
      ...p.nom.
      toLowerCase().
      split(/\s+/).
      map((mot) => distance(mot, q)),
      distance(p.nom.toLowerCase(), q)
    )
  })).
  filter((x) => x.score <= Math.max(2, Math.floor(q.length / 3))).
  sort((a, b) => a.score - b.score).
  map((x) => x.p);
}

function distance(a: string, b: string): number {
  const m = a.length;
  const n = b.length;
  const d: number[][] = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
  for (let i = 0; i <= m; i++) d[i][0] = i;
  for (let j = 0; j <= n; j++) d[0][j] = j;
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      d[i][j] = Math.min(
        d[i - 1][j] + 1,
        d[i][j - 1] + 1,
        d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)
      );
    }
  }
  return d[m][n];
}

export function exporterCsv(nomFichier: string, lignes: (string | number)[][]): void {
  const contenu = lignes.
  map((l) =>
  l.
  map((c) => typeof c === 'string' && /[;"\n]/.test(c) ? `"${c.replace(/"/g, '""')}"` : c).
  join(';')
  ).
  join('\n');
  const blob = new Blob([`\uFEFF${contenu}`], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = nomFichier;
  a.click();
  URL.revokeObjectURL(url);
}