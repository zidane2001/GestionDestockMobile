import { Employe, Permission, Role } from '../types';

export type { Permission } from '../types';

/** Droits attribués par défaut à chaque rôle (matrice du cahier des charges §5). */
const PAR_DEFAUT: Record<Role, Permission[]> = {
  patron: [
  'vendre',
  'defectueux',
  'retour',
  'depense',
  'sortieCaisse',
  'gererProduits',
  'voirPrixAchat',
  'voirBenefices',
  'voirCourbeVentes',
  'historiqueComplet',
  'exporter',
  'journal',
  'pointages',
  'gererComptes',
  'appareils',
  'traiterRetours'],

  manager: [
  'vendre',
  'defectueux',
  'retour',
  'depense',
  'sortieCaisse',
  'voirCourbeVentes',
  'historiqueComplet',
  'exporter',
  'pointer'],

  caissiere: ['vendre', 'defectueux', 'retour', 'sortieCaisse', 'pointer']
};

export function permissionsParDefaut(role: Role): Permission[] {
  return [...PAR_DEFAUT[role]];
}

type Sujet = Employe | Pick<Employe, 'role' | 'permissions'> | Role | null | undefined;

export function peut(sujet: Sujet, permission: Permission): boolean {
  if (!sujet) return false;
  if (typeof sujet === 'string') return PAR_DEFAUT[sujet].includes(permission);
  const liste = sujet.permissions?.length ? sujet.permissions : PAR_DEFAUT[sujet.role];
  return liste.includes(permission);
}

/** Droits réservés au patron : non attribuables à un employé. */
export const PERMISSIONS_RESERVEES: Permission[] = [
'gererComptes',
'appareils',
'traiterRetours'];


export interface GroupePermissions {
  titre: string;
  items: {cle: Permission;label: string;description: string;}[];
}

/** Droits que le patron peut cocher / décocher pour un employé. */
export const GROUPES_PERMISSIONS: GroupePermissions[] = [
{
  titre: 'Opérations de caisse',
  items: [
  { cle: 'vendre', label: 'Enregistrer une vente', description: 'Stock et caisse mis à jour' },
  { cle: 'defectueux', label: 'Signaler un défectueux', description: 'Retire une pièce du stock' },
  { cle: 'retour', label: 'Signaler un retour', description: 'Remboursement ou échange' },
  { cle: 'depense', label: 'Signaler une dépense', description: 'Loyer, factures…' },
  {
    cle: 'sortieCaisse',
    label: 'Justifier une sortie de caisse',
    description: 'Motif obligatoire'
  }]

},
{
  titre: 'Stock',
  items: [
  {
    cle: 'gererProduits',
    label: 'Gérer les produits',
    description: 'Ajouter, modifier, supprimer'
  },
  {
    cle: 'voirPrixAchat',
    label: "Voir les prix d'achat",
    description: 'Donnée sensible — patron par défaut'
  }]

},
{
  titre: 'Chiffres & rapports',
  items: [
  { cle: 'voirCourbeVentes', label: 'Voir les courbes de ventes', description: '7 et 30 jours' },
  {
    cle: 'historiqueComplet',
    label: "Voir l'historique de toute l'équipe",
    description: 'Sinon, ses ventes uniquement'
  },
  {
    cle: 'voirBenefices',
    label: 'Voir les bénéfices et marges',
    description: 'Donnée sensible — patron par défaut'
  },
  { cle: 'exporter', label: 'Exporter des rapports', description: 'Fichier CSV partageable' },
  { cle: 'journal', label: "Consulter le journal d'activité", description: "Toutes les actions" },
  { cle: 'pointages', label: 'Consulter les pointages', description: "Arrivées et départs de l'équipe" }]

},
{
  titre: 'Présence',
  items: [
  { cle: 'pointer', label: 'Pointer arrivée / départ', description: 'Un pointage par jour' }]

}];