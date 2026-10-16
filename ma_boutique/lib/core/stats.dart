import '../models/models.dart';

class PointSerie {
  final String cle;
  final String label;
  final double valeur;

  PointSerie({required this.cle, required this.label, required this.valeur});
}

const _jourMs = 86400000;

DateTime _debutJour(DateTime d) => DateTime(d.year, d.month, d.day);

/// Série journalière du chiffre d'affaires (ou de la marge) sur N jours glissants.
List<PointSerie> serieJournaliere(
  List<Vente> ventes,
  int jours, [
  String mesure = 'ca',
]) {
  final base = _debutJour(DateTime.now());
  final points = <PointSerie>[];
  for (int i = jours - 1; i >= 0; i--) {
    final jour = base.subtract(Duration(milliseconds: i * _jourMs));
    final cle = _cleIso(jour.toUtc());
    double total = 0;
    for (final v in ventes) {
      if (v.date.startsWith(cle)) {
        total += mesure == 'ca'
            ? v.total
            : (v.prixUnitaireReel - v.prixAchatUnitaire) * v.quantite;
      }
    }
    points.add(PointSerie(
      cle: cle,
      label:
          '${jour.day.toString().padLeft(2, '0')}/${jour.month.toString().padLeft(2, '0')}',
      valeur: total,
    ));
  }
  return points;
}

String _cleIso(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

List<Vente> ventesRecentes(List<Vente> ventes, int jours) {
  final limite = DateTime.now().millisecondsSinceEpoch - jours * _jourMs;
  return ventes.where((v) => DateTime.parse(v.date).millisecondsSinceEpoch >= limite).toList();
}

double chiffreAffaires(List<Vente> ventes) {
  return ventes.fold(0, (s, v) => s + v.total);
}

double margeTotale(List<Vente> ventes) {
  return ventes.fold(0, (s, v) => s + (v.prixUnitaireReel - v.prixAchatUnitaire) * v.quantite);
}

double beneficeNet(List<Vente> ventes, List<Depense> depenses) {
  final depensesTotal = depenses.fold(0.0, (s, d) => s + d.montant);
  return margeTotale(ventes) - depensesTotal;
}

double piecesVendues(List<Vente> ventes) {
  return ventes.fold(0, (s, v) => s + v.quantite);
}

class LigneProduit {
  final String produitId;
  final String nom;
  double pieces;
  double ca;
  double marge;

  LigneProduit({
    required this.produitId,
    required this.nom,
    this.pieces = 0,
    this.ca = 0,
    this.marge = 0,
  });
}

List<LigneProduit> classementProduits(List<Vente> ventes) {
  final map = <String, LigneProduit>{};
  for (final v in ventes) {
    final l = map.putIfAbsent(
      v.produitId,
      () => LigneProduit(produitId: v.produitId, nom: v.produitNom),
    );
    l.pieces += v.quantite;
    l.ca += v.total;
    l.marge += (v.prixUnitaireReel - v.prixAchatUnitaire) * v.quantite;
  }
  final liste = map.values.toList();
  liste.sort((a, b) => b.pieces.compareTo(a.pieces));
  return liste;
}

/// Variation en % entre la période courante et la précédente, de même durée.
double tendance(List<Vente> ventes, int jours) {
  final maintenant = DateTime.now().millisecondsSinceEpoch;
  final courant = chiffreAffaires(ventes
      .where((v) => DateTime.parse(v.date).millisecondsSinceEpoch >= maintenant - jours * _jourMs)
      .toList());
  final precedent = chiffreAffaires(ventes.where((v) {
    final t = DateTime.parse(v.date).millisecondsSinceEpoch;
    return t < maintenant - jours * _jourMs &&
        t >= maintenant - 2 * jours * _jourMs;
  }).toList());
  if (precedent == 0) return courant > 0 ? 100 : 0;
  return ((courant - precedent) / precedent * 100).roundToDouble();
}

double valeurStock(List<Produit> produits) {
  return produits
      .where((p) => p.actif)
      .fold(0, (s, p) => s + p.prixVente * p.quantite);
}

const Map<String, String> _sansAccent = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ñ': 'n',
  'œ': 'oe',
  'æ': 'ae',
};

/// Normalise un libellé pour la recherche : minuscules, accents retirés,
/// ponctuation réduite à des espaces, espaces multiples compactés.
String normaliserRecherche(String valeur) {
  final buffer = StringBuffer();
  for (final rune in valeur.toLowerCase().runes) {
    final caractere = String.fromCharCode(rune);
    buffer.write(_sansAccent[caractere] ?? caractere);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r"[^a-z0-9]+"), ' ')
      .trim();
}

/// Score « aucune correspondance » : au-delà, le produit est écarté.
const int scoreAucuneCorrespondance = 99;

/// Seuil de tolérance (en caractères) aux fautes de frappe.
int seuilTolerance(String requeteNormalisee) {
  final brut = (requeteNormalisee.length / 3).floor();
  return brut > 2 ? brut : 2;
}

/// Score de correspondance : 0 = meilleur, [scoreAucuneCorrespondance] = exclu.
int scoreCorrespondance(Produit produit, String requeteNormalisee) {
  final nom = normaliserRecherche(produit.nom);
  if (nom.isEmpty) return scoreAucuneCorrespondance;
  if (nom == requeteNormalisee) return 0;
  if (nom.startsWith(requeteNormalisee)) return 1;
  final mots = nom.split(' ');
  if (mots.any((m) => m.startsWith(requeteNormalisee))) return 2;
  final tokens = requeteNormalisee.split(' ').where((t) => t.isNotEmpty).toList();
  // Requête en plusieurs mots : chaque mot doit préfixer un mot du nom.
  if (tokens.length > 1 && tokens.every((t) => mots.any((m) => m.startsWith(t)))) {
    return 3;
  }
  if (nom.contains(requeteNormalisee)) return 4;
  // Catégorie : le libellé affiché et le code interne sont tous deux acceptés
  // (ex. « Vêtement » comme « vetement »).
  final categorie = normaliserRecherche('${produit.categorieLabel} ${produit.categorie}');
  if (categorie.isNotEmpty && categorie.contains(requeteNormalisee)) return 5;
  // Tolérance aux fautes de frappe : distance de Levenshtein par mot.
  final seuil = seuilTolerance(requeteNormalisee);
  var meilleure = distance(nom, requeteNormalisee);
  for (final mot in mots) {
    final d = distance(mot, requeteNormalisee);
    if (d < meilleure) meilleure = d;
  }
  if (tokens.length > 1) {
    var cumul = 0;
    for (final t in tokens) {
      var minMot = distance(mots.first, t);
      for (final m in mots) {
        final d = distance(m, t);
        if (d < minMot) minMot = d;
      }
      cumul += minMot;
    }
    if (cumul < meilleure) meilleure = cumul;
  }
  if (meilleure <= seuil) return 6 + meilleure;
  return scoreAucuneCorrespondance;
}

/// Recherche instantanée : préfixe, début de mot, sous-chaîne, puis fautes de
/// frappe. À score égal, les produits réellement en stock remontent d'abord
/// pour que la saisie propose ce qui est vendable. [limite] borne l'affichage.
List<Produit> rechercheProduits(List<Produit> produits, String requete, {int? limite}) {
  final q = normaliserRecherche(requete);
  if (q.isEmpty) return produits;
  final resultats = <({Produit p, int score})>[];
  for (final p in produits) {
    final score = scoreCorrespondance(p, q);
    if (score < scoreAucuneCorrespondance) resultats.add((p: p, score: score));
  }
  resultats.sort((a, b) {
    final parScore = a.score.compareTo(b.score);
    if (parScore != 0) return parScore;
    final parStock = (b.p.quantite > 0 ? 1 : 0) - (a.p.quantite > 0 ? 1 : 0);
    if (parStock != 0) return parStock;
    final parQuantite = b.p.quantite.compareTo(a.p.quantite);
    if (parQuantite != 0) return parQuantite;
    return normaliserRecherche(a.p.nom).compareTo(normaliserRecherche(b.p.nom));
  });
  final liste = resultats.map((x) => x.p).toList();
  if (limite != null && liste.length > limite) return liste.sublist(0, limite);
  return liste;
}

int distance(String a, String b) {
  final m = a.length;
  final n = b.length;
  final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (int i = 0; i <= m; i++) {
    d[i][0] = i;
  }
  for (int j = 0; j <= n; j++) {
    d[0][j] = j;
  }
  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      d[i][j] = [
        d[i - 1][j] + 1,
        d[i][j - 1] + 1,
        d[i - 1][j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
      ].reduce((x, y) => x < y ? x : y);
    }
  }
  return d[m][n];
}

/// Contenu CSV (séparateur `;`, BOM UTF-8, guillemets si nécessaire).
String exporterCsvContent(List<List<Object>> lignes) {
  final buffer = StringBuffer();
  for (final l in lignes) {
    final contenu = l
        .map((c) {
          final s = c.toString();
          return RegExp(r'[;"\n]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
        })
        .join(';');
    buffer.write('$contenu\n');
  }
  return '\uFEFF$buffer';
}