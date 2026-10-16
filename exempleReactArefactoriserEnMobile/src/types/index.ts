export type Role = 'patron' | 'manager' | 'caissiere';

export type Permission =
'vendre' |
'defectueux' |
'retour' |
'depense' |
'sortieCaisse' |
'gererProduits' |
'voirPrixAchat' |
'voirBenefices' |
'voirCourbeVentes' |
'historiqueComplet' |
'exporter' |
'journal' |
'pointages' |
'gererComptes' |
'appareils' |
'pointer' |
'traiterRetours';

export interface Boutique {
  nom: string;
  styleCommerce: string;
  monnaie: 'FCFA' | 'EUR' | 'USD';
  emailPatron: string;
  logoUrl: string | null;
  soldeCaisse: number;
}

export interface Employe {
  id: string;
  nom: string;
  role: Role;
  permissions: Permission[];
  motDePasse: string;
  statut: 'actif' | 'suspendu';
  pinActif: boolean;
  pin: string;
  biometrie: boolean;
  dateCreation: string;
}

export interface Produit {
  id: string;
  nom: string;
  prixAchat: number;
  prixVente: number;
  quantite: number;
  actif: boolean;
}

export interface Vente {
  id: string;
  produitId: string;
  produitNom: string;
  quantite: number;
  prixUnitaireReel: number;
  prixAchatUnitaire: number;
  total: number;
  vendeurId: string;
  vendeurNom: string;
  vendeurRole: Role;
  date: string;
}

export interface Depense {
  id: string;
  description: string;
  montant: number;
  auteurNom: string;
  auteurRole: Role;
  type: 'depense' | 'sortie_justifiee';
  date: string;
}

export interface Retour {
  id: string;
  produitId: string;
  produitNom: string;
  motif: 'remboursement' | 'echange' | 'defectueux';
  description: string;
  montant: number;
  auteurNom: string;
  statut: 'en_attente' | 'traite' | 'refuse';
  date: string;
}

export type NotifType =
'vente' |
'depense' |
'stock' |
'produit' |
'retour' |
'compte' |
'pointage';

export interface NotificationItem {
  id: string;
  destinataires: Role[];
  titre: string;
  message: string;
  type: NotifType;
  estLu: boolean;
  date: string;
}

export interface Pointage {
  id: string;
  employeId: string;
  employeNom: string;
  role: Role;
  date: string;
  heureArrivee: string;
  heureDepart: string | null;
}

export interface Activite {
  id: string;
  employeNom: string;
  employeRole: Role;
  type: NotifType | 'connexion';
  description: string;
  date: string;
}

export interface Appareil {
  id: string;
  employeNom: string;
  role: Role;
  nomAppareil: string;
  derniereConnexion: string;
  actif: boolean;
}