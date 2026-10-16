import {
  Activite,
  Appareil,
  Boutique,
  Depense,
  Employe,
  NotificationItem,
  Pointage,
  Produit,
  Retour,
  Vente } from
'../types';
import { permissionsParDefaut } from '../utils/permissions';

const now = Date.now();
const JOUR = 86_400_000;
const iso = (offsetMs: number) => new Date(now - offsetMs).toISOString();

export const BOUTIQUE_DEMO: Boutique = {
  nom: 'Boutique Kadi',
  styleCommerce: 'Vêtements & accessoires',
  monnaie: 'FCFA',
  emailPatron: 'kadi.patron@gmail.com',
  logoUrl: "/766bb7d5-f667-4476-a87f-1507be00b042.jpg",

  soldeCaisse: 486_500
};

export const EMPLOYES_DEMO: Employe[] = [
{
  id: 'e1',
  nom: 'Kadi Traoré',
  role: 'patron',
  permissions: permissionsParDefaut('patron'),
  motDePasse: 'patron123',
  statut: 'actif',
  pinActif: true,
  pin: '1234',
  biometrie: true,
  dateCreation: iso(120 * JOUR)
},
{
  id: 'e2',
  nom: 'Ibrahim Sow',
  role: 'manager',
  permissions: [...permissionsParDefaut('manager'), 'pointages'],
  motDePasse: 'manager123',
  statut: 'actif',
  pinActif: true,
  pin: '1234',
  biometrie: false,
  dateCreation: iso(90 * JOUR)
},
{
  id: 'e3',
  nom: 'Aminata Diallo',
  role: 'caissiere',
  permissions: permissionsParDefaut('caissiere'),
  motDePasse: 'caisse123',
  statut: 'actif',
  pinActif: false,
  pin: '1234',
  biometrie: false,
  dateCreation: iso(60 * JOUR)
}];


export const PRODUITS_DEMO: Produit[] = [
{ id: 'p1', nom: 'Chemise coton homme', prixAchat: 4500, prixVente: 7500, quantite: 18, actif: true },
{ id: 'p2', nom: 'Robe wax femme', prixAchat: 9000, prixVente: 15000, quantite: 7, actif: true },
{ id: 'p3', nom: 'Jean slim bleu', prixAchat: 7000, prixVente: 12000, quantite: 0, actif: true },
{ id: 'p4', nom: 'Sandales cuir', prixAchat: 5500, prixVente: 9000, quantite: 12, actif: true },
{ id: 'p5', nom: 'Sac à main simili', prixAchat: 6000, prixVente: 11000, quantite: 4, actif: true },
{ id: 'p6', nom: 'T-shirt uni', prixAchat: 2000, prixVente: 3500, quantite: 42, actif: true },
{ id: 'p7', nom: 'Foulard imprimé', prixAchat: 1500, prixVente: 3000, quantite: 25, actif: true },
{ id: 'p8', nom: 'Ceinture homme', prixAchat: 2500, prixVente: 5000, quantite: 2, actif: true }];


const VENDEURS = [
{ id: 'e1', nom: 'Kadi Traoré', role: 'patron' as const },
{ id: 'e2', nom: 'Ibrahim Sow', role: 'manager' as const },
{ id: 'e3', nom: 'Aminata Diallo', role: 'caissiere' as const }];


function genererVentes(): Vente[] {
  const ventes: Vente[] = [];
  let n = 0;
  for (let j = 29; j >= 0; j--) {
    const nb = 1 + (j * 7 + 3) % 4 + (j % 6 === 0 ? 2 : 0);
    for (let k = 0; k < nb; k++) {
      const produit = PRODUITS_DEMO[(j + k * 3) % PRODUITS_DEMO.length];
      const vendeur = VENDEURS[(j + k) % 3];
      const quantite = 1 + (j + k) % 3;
      const remise = (j + k) % 5 === 0 ? 500 : 0;
      const prix = produit.prixVente - remise;
      ventes.push({
        id: `v${n++}`,
        produitId: produit.id,
        produitNom: produit.nom,
        quantite,
        prixUnitaireReel: prix,
        prixAchatUnitaire: produit.prixAchat,
        total: prix * quantite,
        vendeurId: vendeur.id,
        vendeurNom: vendeur.nom,
        vendeurRole: vendeur.role,
        date: iso(j * JOUR - (9 + k * 2) * 3_600_000 + JOUR)
      });
    }
  }
  return ventes.filter((v) => new Date(v.date).getTime() <= now);
}

export const VENTES_DEMO: Vente[] = genererVentes();

export const DEPENSES_DEMO: Depense[] = [
{
  id: 'd1',
  description: 'Loyer du mois',
  montant: 75_000,
  auteurNom: 'Kadi Traoré',
  auteurRole: 'patron',
  type: 'depense',
  date: iso(6 * JOUR)
},
{
  id: 'd2',
  description: 'Facture électricité',
  montant: 18_500,
  auteurNom: 'Ibrahim Sow',
  auteurRole: 'manager',
  type: 'depense',
  date: iso(3 * JOUR)
},
{
  id: 'd3',
  description: 'Transport marchandise — reçu n°42',
  montant: 6_000,
  auteurNom: 'Aminata Diallo',
  auteurRole: 'caissiere',
  type: 'sortie_justifiee',
  date: iso(1 * JOUR)
}];


export const RETOURS_DEMO: Retour[] = [
{
  id: 'r1',
  produitId: 'p2',
  produitNom: 'Robe wax femme',
  motif: 'remboursement',
  description: 'Taille trop petite, cliente pas satisfaite.',
  montant: 15_000,
  auteurNom: 'Aminata Diallo',
  statut: 'en_attente',
  date: iso(0.4 * JOUR)
},
{
  id: 'r2',
  produitId: 'p4',
  produitNom: 'Sandales cuir',
  motif: 'echange',
  description: 'Échange contre la pointure 41.',
  montant: 0,
  auteurNom: 'Ibrahim Sow',
  statut: 'traite',
  date: iso(2 * JOUR)
},
{
  id: 'r3',
  produitId: 'p8',
  produitNom: 'Ceinture homme',
  motif: 'defectueux',
  description: 'Boucle cassée à la réception du carton.',
  montant: 0,
  auteurNom: 'Ibrahim Sow',
  statut: 'en_attente',
  date: iso(4 * JOUR)
}];


export const NOTIFICATIONS_DEMO: NotificationItem[] = [
{
  id: 'n1',
  destinataires: ['patron', 'manager', 'caissiere'],
  titre: 'Nouvelle vente',
  message: 'Aminata Diallo a vendu 2 × T-shirt uni — 7 000 FCFA',
  type: 'vente',
  estLu: false,
  date: iso(0.02 * JOUR)
},
{
  id: 'n2',
  destinataires: ['patron', 'manager', 'caissiere'],
  titre: 'Rupture de stock',
  message: 'Jean slim bleu est épuisé (0 en stock).',
  type: 'stock',
  estLu: false,
  date: iso(0.2 * JOUR)
},
{
  id: 'n3',
  destinataires: ['patron'],
  titre: 'Retour produit signalé',
  message: 'Remboursement demandé sur Robe wax femme.',
  type: 'retour',
  estLu: false,
  date: iso(0.4 * JOUR)
},
{
  id: 'n4',
  destinataires: ['patron', 'manager', 'caissiere'],
  titre: 'Dépense enregistrée',
  message: 'Facture électricité — 18 500 FCFA par Ibrahim Sow',
  type: 'depense',
  estLu: true,
  date: iso(3 * JOUR)
},
{
  id: 'n5',
  destinataires: ['patron'],
  titre: 'Pointage',
  message: 'Aminata Diallo a pointé son arrivée à 08:12.',
  type: 'pointage',
  estLu: true,
  date: iso(0.5 * JOUR)
}];


export const POINTAGES_DEMO: Pointage[] = [
{
  id: 'pt1',
  employeId: 'e3',
  employeNom: 'Aminata Diallo',
  role: 'caissiere',
  date: new Date(now).toISOString().slice(0, 10),
  heureArrivee: '08:12',
  heureDepart: null
},
{
  id: 'pt2',
  employeId: 'e2',
  employeNom: 'Ibrahim Sow',
  role: 'manager',
  date: new Date(now).toISOString().slice(0, 10),
  heureArrivee: '07:55',
  heureDepart: null
},
{
  id: 'pt3',
  employeId: 'e3',
  employeNom: 'Aminata Diallo',
  role: 'caissiere',
  date: new Date(now - JOUR).toISOString().slice(0, 10),
  heureArrivee: '08:04',
  heureDepart: '19:10'
},
{
  id: 'pt4',
  employeId: 'e2',
  employeNom: 'Ibrahim Sow',
  role: 'manager',
  date: new Date(now - JOUR).toISOString().slice(0, 10),
  heureArrivee: '08:00',
  heureDepart: '19:30'
}];


export const ACTIVITES_DEMO: Activite[] = [
{
  id: 'a1',
  employeNom: 'Aminata Diallo',
  employeRole: 'caissiere',
  type: 'vente',
  description: 'Vente de 2 × T-shirt uni pour 7 000 FCFA',
  date: iso(0.02 * JOUR)
},
{
  id: 'a2',
  employeNom: 'Aminata Diallo',
  employeRole: 'caissiere',
  type: 'retour',
  description: 'Retour signalé : Robe wax femme (remboursement)',
  date: iso(0.4 * JOUR)
},
{
  id: 'a3',
  employeNom: 'Ibrahim Sow',
  employeRole: 'manager',
  type: 'depense',
  description: 'Dépense : Facture électricité — 18 500 FCFA',
  date: iso(3 * JOUR)
},
{
  id: 'a4',
  employeNom: 'Kadi Traoré',
  employeRole: 'patron',
  type: 'produit',
  description: 'Produit ajouté : Foulard imprimé (25 pièces)',
  date: iso(5 * JOUR)
},
{
  id: 'a5',
  employeNom: 'Ibrahim Sow',
  employeRole: 'manager',
  type: 'connexion',
  description: 'Connexion depuis Tecno Spark 10',
  date: iso(6 * JOUR)
}];


export const APPAREILS_DEMO: Appareil[] = [
{
  id: 'ap1',
  employeNom: 'Kadi Traoré',
  role: 'patron',
  nomAppareil: 'Samsung Galaxy A54',
  derniereConnexion: iso(0.01 * JOUR),
  actif: true
},
{
  id: 'ap2',
  employeNom: 'Ibrahim Sow',
  role: 'manager',
  nomAppareil: 'Tecno Spark 10',
  derniereConnexion: iso(0.1 * JOUR),
  actif: true
},
{
  id: 'ap3',
  employeNom: 'Aminata Diallo',
  role: 'caissiere',
  nomAppareil: 'Infinix Hot 12',
  derniereConnexion: iso(0.3 * JOUR),
  actif: true
},
{
  id: 'ap4',
  employeNom: 'Aminata Diallo',
  role: 'caissiere',
  nomAppareil: 'Itel A56 (inconnu)',
  derniereConnexion: iso(9 * JOUR),
  actif: false
}];