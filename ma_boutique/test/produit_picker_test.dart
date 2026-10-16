import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/core/theme.dart';
import 'package:ma_boutique/models/models.dart';
import 'package:ma_boutique/widgets/produit_picker.dart';

Produit _p(String id, String nom, {double quantite = 5, String categorie = 'vetement'}) => Produit(
      id: id,
      nom: nom,
      prixAchat: 1000,
      prixVente: 2000,
      quantite: quantite,
      categorie: categorie,
    );

/// Le sélecteur est toujours présenté dans une feuille modale qui défile :
/// la hauteur disponible n'est donc pas bornée (comme dans `ouvrirFeuille`).
Widget _cadre(Widget enfant) => MaterialApp(
      theme: buildTheme(AppColors.clair, Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: enfant,
        ),
      ),
    );

void main() {
  testWidgets('annonce le stock disponible dès l\'ouverture', (tester) async {
    await tester.pumpWidget(_cadre(ProduitPicker(
      produits: [_p('p1', 'Chemise'), _p('p2', 'Pantalon'), _p('p3', 'Rupture', quantite: 0)],
      onSelect: (_) {},
    )));

    expect(find.textContaining('2 produits en stock'), findsOneWidget);
    // Une rupture n'est pas proposée pour une vente.
    expect(find.text('Rupture'), findsNothing);
  });

  testWidgets('filtre les suggestions à chaque frappe, sans validation', (tester) async {
    await tester.pumpWidget(_cadre(ProduitPicker(
      produits: [_p('p1', 'Chemise blanche'), _p('p2', 'Pantalon')],
      onSelect: (_) {},
    )));

    await tester.enterText(find.byType(TextField), 'chem');
    await tester.pump();

    expect(find.text('Chemise blanche'), findsOneWidget);
    expect(find.text('Pantalon'), findsNothing);
    expect(find.textContaining('1 suggestion'), findsOneWidget);
  });

  testWidgets('retrouve un produit malgré une faute de frappe', (tester) async {
    await tester.pumpWidget(_cadre(ProduitPicker(
      produits: [_p('p1', 'Chemise'), _p('p2', 'Pantalon')],
      onSelect: (_) {},
    )));

    await tester.enterText(find.byType(TextField), 'chemisse');
    await tester.pump();

    expect(find.text('Chemise'), findsOneWidget);
  });

  testWidgets('efface la recherche et restaure toutes les suggestions', (tester) async {
    await tester.pumpWidget(_cadre(ProduitPicker(
      produits: [_p('p1', 'Chemise'), _p('p2', 'Pantalon')],
      onSelect: (_) {},
    )));

    await tester.enterText(find.byType(TextField), 'chem');
    await tester.pump();
    expect(find.text('Pantalon'), findsNothing);

    await tester.tap(find.byTooltip('Effacer la recherche'));
    await tester.pump();

    expect(find.text('Chemise'), findsOneWidget);
    expect(find.text('Pantalon'), findsOneWidget);
  });

  testWidgets('sélectionne le produit choisi', (tester) async {
    Produit? choisi;
    await tester.pumpWidget(_cadre(ProduitPicker(
      produits: [_p('p1', 'Chemise'), _p('p2', 'Pantalon')],
      onSelect: (p) => choisi = p,
    )));

    await tester.tap(find.text('Pantalon'));
    await tester.pump();

    expect(choisi?.id, 'p2');
  });

  testWidgets('affiche les ruptures quand la vente les autorise', (tester) async {
    await tester.pumpWidget(_cadre(ProduitPicker(
      produits: [_p('p1', 'Chemise', quantite: 0)],
      autoriserRuptures: true,
      onSelect: (_) {},
    )));

    expect(find.text('Chemise'), findsOneWidget);
    expect(find.text('rupture'), findsOneWidget);
  });
}
