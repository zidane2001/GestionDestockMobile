import React, {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  ReactNode } from
'react';
import {
  Activite,
  Appareil,
  Boutique,
  Depense,
  Employe,
  NotificationItem,
  NotifType,
  Permission,
  Pointage,
  Produit,
  Retour,
  Role,
  Vente } from
'../types';
import { permissionsParDefaut } from '../utils/permissions';
import {
  ACTIVITES_DEMO,
  APPAREILS_DEMO,
  BOUTIQUE_DEMO,
  DEPENSES_DEMO,
  EMPLOYES_DEMO,
  NOTIFICATIONS_DEMO,
  POINTAGES_DEMO,
  PRODUITS_DEMO,
  RETOURS_DEMO,
  VENTES_DEMO } from
'../data/seed';
import { formatMontant } from '../utils/format';

const uid = () => Math.random().toString(36).slice(2, 10);

interface Toast {
  id: string;
  message: string;
  ton: 'succes' | 'erreur' | 'info';
}

interface AppState {
  boutique: Boutique | null;
  employes: Employe[];
  produits: Produit[];
  ventes: Vente[];
  depenses: Depense[];
  retours: Retour[];
  notifications: NotificationItem[];
  pointages: Pointage[];
  activites: Activite[];
  appareils: Appareil[];
  session: Employe | null;
  verrouille: boolean;
  theme: 'clair' | 'sombre';
  enLigne: boolean;
  enAttenteSync: number;
  toasts: Toast[];
}

interface AppActions {
  creerBoutique: (input: {
    nom: string;
    styleCommerce: string;
    monnaie: Boutique['monnaie'];
    emailPatron: string;
    motDePasse: string;
    logoUrl: string | null;
  }) => void;
  definirLogo: (logoUrl: string | null) => void;
  connexion: (nomBoutique: string, role: Role, motDePasse: string) => string | null;
  deconnexion: () => void;
  deverrouiller: (pin: string) => boolean;
  verrouiller: () => void;
  basculerTheme: () => void;
  basculerReseau: () => void;
  enregistrerVente: (produitId: string, quantite: number, prixUnitaire: number) => string | null;
  signalerDefectueux: (produitId: string, description: string) => string | null;
  signalerRetour: (
  produitId: string,
  motif: 'remboursement' | 'echange',
  description: string,
  montant: number)
  => string | null;
  enregistrerDepense: (
  description: string,
  montant: number,
  type: 'depense' | 'sortie_justifiee')
  => string | null;
  ajouterProduit: (p: Omit<Produit, 'id' | 'actif'>) => void;
  modifierProduit: (id: string, p: Omit<Produit, 'id' | 'actif'>) => void;
  supprimerProduit: (id: string) => void;
  traiterRetour: (id: string, statut: Retour['statut']) => void;
  pointer: (sens: 'arrivee' | 'depart') => string | null;
  marquerNotificationsLues: () => void;
  creerEmploye: (
  nom: string,
  role: Role,
  motDePasse: string,
  permissions: Permission[])
  => void;
  modifierEmploye: (
  id: string,
  maj: {nom: string;role: Role;permissions: Permission[];})
  => void;
  basculerStatutEmploye: (id: string) => void;
  supprimerEmploye: (id: string) => void;
  reinitialiserMotDePasse: (id: string, motDePasse: string) => void;
  definirPin: (pin: string | null) => void;
  basculerBiometrie: () => void;
  revoquerAppareil: (id: string) => void;
  fermerToast: (id: string) => void;
  notifier: (message: string, ton?: Toast['ton']) => void;
}

type AppContextValue = AppState & AppActions & {notificationsRole: NotificationItem[];};

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: {children: ReactNode;}) {
  const [boutique, setBoutique] = useState<Boutique | null>(BOUTIQUE_DEMO);
  const [employes, setEmployes] = useState<Employe[]>(EMPLOYES_DEMO);
  const [produits, setProduits] = useState<Produit[]>(PRODUITS_DEMO);
  const [ventes, setVentes] = useState<Vente[]>(VENTES_DEMO);
  const [depenses, setDepenses] = useState<Depense[]>(DEPENSES_DEMO);
  const [retours, setRetours] = useState<Retour[]>(RETOURS_DEMO);
  const [notifications, setNotifications] = useState<NotificationItem[]>(NOTIFICATIONS_DEMO);
  const [pointages, setPointages] = useState<Pointage[]>(POINTAGES_DEMO);
  const [activites, setActivites] = useState<Activite[]>(ACTIVITES_DEMO);
  const [appareils, setAppareils] = useState<Appareil[]>(APPAREILS_DEMO);
  const [session, setSession] = useState<Employe | null>(null);
  const [verrouille, setVerrouille] = useState(false);
  const [theme, setTheme] = useState<'clair' | 'sombre'>('clair');
  const [enLigne, setEnLigne] = useState(true);
  const [enAttenteSync, setEnAttenteSync] = useState(0);
  const [toasts, setToasts] = useState<Toast[]>([]);

  const monnaie = boutique?.monnaie ?? 'FCFA';

  const notifier = useCallback((message: string, ton: Toast['ton'] = 'succes') => {
    const id = uid();
    setToasts((t) => [...t, { id, message, ton }]);
    window.setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 3200);
  }, []);

  const fermerToast = useCallback((id: string) => {
    setToasts((t) => t.filter((x) => x.id !== id));
  }, []);

  const pousserNotification = useCallback(
    (titre: string, message: string, type: NotifType, destinataires: Role[]) => {
      setNotifications((n) => [
      { id: uid(), destinataires, titre, message, type, estLu: false, date: new Date().toISOString() },
      ...n]
      );
    },
    []
  );

  const journaliser = useCallback(
    (type: Activite['type'], description: string, auteur: Employe | null) => {
      if (!auteur) return;
      setActivites((a) => [
      {
        id: uid(),
        employeNom: auteur.nom,
        employeRole: auteur.role,
        type,
        description,
        date: new Date().toISOString()
      },
      ...a]
      );
    },
    []
  );

  const majCaisse = useCallback((delta: number) => {
    setBoutique((b) => b ? { ...b, soldeCaisse: b.soldeCaisse + delta } : b);
  }, []);

  const compterSync = useCallback(() => {
    if (!enLigne) setEnAttenteSync((n) => n + 1);
  }, [enLigne]);

  /* ---------- Authentification ---------- */

  const creerBoutique: AppActions['creerBoutique'] = useCallback(
    (input) => {
      const patron: Employe = {
        id: uid(),
        nom: 'Patron',
        role: 'patron',
        permissions: permissionsParDefaut('patron'),
        motDePasse: input.motDePasse,
        statut: 'actif',
        pinActif: false,
        pin: '',
        biometrie: false,
        dateCreation: new Date().toISOString()
      };
      setBoutique({
        nom: input.nom,
        styleCommerce: input.styleCommerce,
        monnaie: input.monnaie,
        emailPatron: input.emailPatron,
        logoUrl: input.logoUrl,
        soldeCaisse: 0
      });
      setEmployes([patron]);
      setProduits([]);
      setVentes([]);
      setDepenses([]);
      setRetours([]);
      setNotifications([]);
      setPointages([]);
      setActivites([]);
      setAppareils([
      {
        id: uid(),
        employeNom: patron.nom,
        role: 'patron',
        nomAppareil: 'Cet appareil',
        derniereConnexion: new Date().toISOString(),
        actif: true
      }]
      );
      setSession(patron);
      notifier('Boutique créée. Bienvenue !');
    },
    [notifier]
  );

  const definirLogo: AppActions['definirLogo'] = useCallback(
    (logoUrl) => {
      setBoutique((b) => b ? { ...b, logoUrl } : b);
      notifier(logoUrl ? 'Logo mis à jour' : 'Logo retiré', logoUrl ? 'succes' : 'info');
    },
    [notifier]
  );

  const connexion: AppActions['connexion'] = useCallback(
    (nomBoutique, role, motDePasse) => {
      if (!boutique || boutique.nom.toLowerCase() !== nomBoutique.trim().toLowerCase()) {
        return 'Nom de boutique inconnu.';
      }
      const employe = employes.find((e) => e.role === role);
      if (!employe || employe.motDePasse !== motDePasse) return 'Mot de passe incorrect.';
      if (employe.statut === 'suspendu') return 'Compte suspendu. Contactez le patron.';
      setSession(employe);
      setVerrouille(employe.pinActif);
      journaliser('connexion', `Connexion de ${employe.nom}`, employe);
      return null;
    },
    [boutique, employes, journaliser]
  );

  const deconnexion = useCallback(() => {
    setSession(null);
    setVerrouille(false);
  }, []);

  const deverrouiller = useCallback(
    (pin: string) => {
      if (session && session.pin === pin) {
        setVerrouille(false);
        return true;
      }
      return false;
    },
    [session]
  );

  const verrouiller = useCallback(() => setVerrouille(true), []);

  const basculerTheme = useCallback(() => {
    setTheme((t) => t === 'clair' ? 'sombre' : 'clair');
  }, []);

  const basculerReseau = useCallback(() => {
    setEnLigne((v) => {
      if (!v) {
        setEnAttenteSync(0);
        notifier('Synchronisation terminée. Équipe à jour.', 'info');
      }
      return !v;
    });
  }, [notifier]);

  /* ---------- Opérations métier ---------- */

  const enregistrerVente: AppActions['enregistrerVente'] = useCallback(
    (produitId, quantite, prixUnitaire) => {
      const produit = produits.find((p) => p.id === produitId);
      if (!produit) return 'Produit introuvable.';
      if (quantite <= 0) return 'La quantité doit être supérieure à 0.';
      if (quantite > produit.quantite) return `Stock insuffisant : ${produit.quantite} en stock.`;
      if (prixUnitaire <= 0) return 'Le prix de vente doit être supérieur à 0.';

      const total = quantite * prixUnitaire;
      const vente: Vente = {
        id: uid(),
        produitId,
        produitNom: produit.nom,
        quantite,
        prixUnitaireReel: prixUnitaire,
        prixAchatUnitaire: produit.prixAchat,
        total,
        vendeurId: session!.id,
        vendeurNom: session!.nom,
        vendeurRole: session!.role,
        date: new Date().toISOString()
      };
      setVentes((v) => [vente, ...v]);
      setProduits((ps) =>
      ps.map((p) => p.id === produitId ? { ...p, quantite: p.quantite - quantite } : p)
      );
      majCaisse(total);
      pousserNotification(
        'Nouvelle vente',
        `${session!.nom} a vendu ${quantite} × ${produit.nom} — ${formatMontant(total, monnaie)}`,
        'vente',
        ['patron', 'manager', 'caissiere']
      );
      if (produit.quantite - quantite === 0) {
        pousserNotification('Rupture de stock', `${produit.nom} est épuisé (0 en stock).`, 'stock', [
        'patron',
        'manager',
        'caissiere']
        );
      }
      journaliser(
        'vente',
        `Vente de ${quantite} × ${produit.nom} pour ${formatMontant(total, monnaie)}`,
        session
      );
      compterSync();
      notifier(`Vente enregistrée · ${formatMontant(total, monnaie)}`);
      return null;
    },
    [produits, session, majCaisse, pousserNotification, journaliser, monnaie, notifier, compterSync]
  );

  const signalerDefectueux: AppActions['signalerDefectueux'] = useCallback(
    (produitId, description) => {
      const produit = produits.find((p) => p.id === produitId);
      if (!produit) return 'Produit introuvable.';
      if (!description.trim()) return 'La description du problème est obligatoire.';
      if (produit.quantite < 1) return 'Aucune pièce en stock pour ce produit.';
      setProduits((ps) =>
      ps.map((p) => p.id === produitId ? { ...p, quantite: p.quantite - 1 } : p)
      );
      setRetours((r) => [
      {
        id: uid(),
        produitId,
        produitNom: produit.nom,
        motif: 'defectueux',
        description,
        montant: 0,
        auteurNom: session!.nom,
        statut: 'en_attente',
        date: new Date().toISOString()
      },
      ...r]
      );
      pousserNotification(
        'Produit défectueux signalé',
        `${produit.nom} — ${description}`,
        'retour',
        ['patron', 'manager']
      );
      journaliser('retour', `Produit défectueux : ${produit.nom}`, session);
      compterSync();
      notifier('Article défectueux signalé');
      return null;
    },
    [produits, session, pousserNotification, journaliser, notifier, compterSync]
  );

  const signalerRetour: AppActions['signalerRetour'] = useCallback(
    (produitId, motif, description, montant) => {
      const produit = produits.find((p) => p.id === produitId);
      if (!produit) return 'Produit introuvable.';
      if (!description.trim()) return 'La description est obligatoire.';
      if (motif === 'remboursement') {
        if (montant <= 0) return 'Le montant remboursé doit être supérieur à 0.';
        if (!boutique || montant > boutique.soldeCaisse)
        return 'Solde de caisse insuffisant : la caisse ne peut pas être négative.';
      }
      setProduits((ps) =>
      ps.map((p) => p.id === produitId ? { ...p, quantite: p.quantite + 1 } : p)
      );
      if (motif === 'remboursement') majCaisse(-montant);
      setRetours((r) => [
      {
        id: uid(),
        produitId,
        produitNom: produit.nom,
        motif,
        description,
        montant: motif === 'remboursement' ? montant : 0,
        auteurNom: session!.nom,
        statut: 'en_attente',
        date: new Date().toISOString()
      },
      ...r]
      );
      pousserNotification(
        'Retour produit signalé',
        `${produit.nom} — ${motif === 'remboursement' ? 'remboursement' : 'échange'}`,
        'retour',
        ['patron']
      );
      journaliser('retour', `Retour ${motif} : ${produit.nom}`, session);
      compterSync();
      notifier('Retour enregistré');
      return null;
    },
    [produits, boutique, session, majCaisse, pousserNotification, journaliser, notifier, compterSync]
  );

  const enregistrerDepense: AppActions['enregistrerDepense'] = useCallback(
    (description, montant, type) => {
      if (!description.trim()) return 'Le motif est obligatoire.';
      if (montant <= 0) return 'Le montant doit être supérieur à 0.';
      if (!boutique || montant > boutique.soldeCaisse)
      return 'Solde de caisse insuffisant : la caisse ne peut pas être négative.';
      setDepenses((d) => [
      {
        id: uid(),
        description,
        montant,
        auteurNom: session!.nom,
        auteurRole: session!.role,
        type,
        date: new Date().toISOString()
      },
      ...d]
      );
      majCaisse(-montant);
      pousserNotification(
        type === 'depense' ? 'Dépense enregistrée' : 'Diminution de caisse justifiée',
        `${description} — ${formatMontant(montant, monnaie)} par ${session!.nom}`,
        'depense',
        type === 'depense' ? ['patron', 'manager', 'caissiere'] : ['patron', 'manager']
      );
      journaliser('depense', `${description} — ${formatMontant(montant, monnaie)}`, session);
      compterSync();
      notifier(type === 'depense' ? 'Dépense enregistrée' : 'Sortie de caisse justifiée');
      return null;
    },
    [boutique, session, majCaisse, pousserNotification, journaliser, monnaie, notifier, compterSync]
  );

  const ajouterProduit: AppActions['ajouterProduit'] = useCallback(
    (p) => {
      setProduits((ps) => [{ ...p, id: uid(), actif: true }, ...ps]);
      pousserNotification('Nouveau produit ajouté', `${p.nom} — ${p.quantite} pièces`, 'produit', [
      'patron',
      'manager',
      'caissiere']
      );
      journaliser('produit', `Produit ajouté : ${p.nom} (${p.quantite} pièces)`, session);
      compterSync();
      notifier('Produit ajouté au stock');
    },
    [pousserNotification, journaliser, session, notifier, compterSync]
  );

  const modifierProduit: AppActions['modifierProduit'] = useCallback(
    (id, p) => {
      setProduits((ps) => ps.map((x) => x.id === id ? { ...x, ...p } : x));
      journaliser('produit', `Produit modifié : ${p.nom}`, session);
      compterSync();
      notifier('Produit mis à jour');
    },
    [journaliser, session, notifier, compterSync]
  );

  const supprimerProduit: AppActions['supprimerProduit'] = useCallback(
    (id) => {
      const produit = produits.find((p) => p.id === id);
      setProduits((ps) => ps.map((x) => x.id === id ? { ...x, actif: false } : x));
      journaliser('produit', `Produit supprimé : ${produit?.nom ?? ''}`, session);
      notifier('Produit retiré du stock actif — historique conservé', 'info');
    },
    [produits, journaliser, session, notifier]
  );

  const traiterRetour: AppActions['traiterRetour'] = useCallback(
    (id, statut) => {
      setRetours((rs) => rs.map((r) => r.id === id ? { ...r, statut } : r));
      journaliser('retour', `Retour ${statut === 'traite' ? 'traité' : 'refusé'}`, session);
      notifier(statut === 'traite' ? 'Retour marqué comme traité' : 'Retour refusé', 'info');
    },
    [journaliser, session, notifier]
  );

  const pointer: AppActions['pointer'] = useCallback(
    (sens) => {
      if (!session) return 'Session expirée.';
      const jour = new Date().toISOString().slice(0, 10);
      const heureNow = new Date().toLocaleTimeString('fr-FR', {
        hour: '2-digit',
        minute: '2-digit'
      });
      const existant = pointages.find((p) => p.employeId === session.id && p.date === jour);
      if (sens === 'arrivee') {
        if (existant) return "Vous avez déjà pointé votre arrivée aujourd'hui.";
        setPointages((ps) => [
        {
          id: uid(),
          employeId: session.id,
          employeNom: session.nom,
          role: session.role,
          date: jour,
          heureArrivee: heureNow,
          heureDepart: null
        },
        ...ps]
        );
      } else {
        if (!existant) return "Pointez d'abord votre arrivée.";
        if (existant.heureDepart) return 'Départ déjà pointé.';
        setPointages((ps) =>
        ps.map((p) => p.id === existant.id ? { ...p, heureDepart: heureNow } : p)
        );
      }
      pousserNotification(
        'Pointage',
        `${session.nom} a pointé son ${sens === 'arrivee' ? 'arrivée' : 'départ'} à ${heureNow}.`,
        'pointage',
        ['patron']
      );
      journaliser('pointage', `Pointage ${sens} à ${heureNow}`, session);
      notifier(`Pointage ${sens === 'arrivee' ? "d'arrivée" : 'de départ'} enregistré · ${heureNow}`);
      return null;
    },
    [session, pointages, pousserNotification, journaliser, notifier]
  );

  const marquerNotificationsLues = useCallback(() => {
    if (!session) return;
    setNotifications((ns) =>
    ns.map((n) => n.destinataires.includes(session.role) ? { ...n, estLu: true } : n)
    );
  }, [session]);

  const creerEmploye: AppActions['creerEmploye'] = useCallback(
    (nom, role, motDePasse, permissions) => {
      const employe: Employe = {
        id: uid(),
        nom,
        role,
        permissions: permissions.length > 0 ? permissions : permissionsParDefaut(role),
        motDePasse,
        statut: 'actif',
        pinActif: false,
        pin: '1234',
        biometrie: false,
        dateCreation: new Date().toISOString()
      };
      setEmployes((es) => [...es, employe]);
      pousserNotification('Compte créé', `${nom} — ${role}`, 'compte', ['patron']);
      journaliser(
        'compte',
        `Compte créé : ${nom} (${role}) avec ${employe.permissions.length} droits`,
        session
      );
      notifier('Compte employé créé');
    },
    [pousserNotification, journaliser, session, notifier]
  );

  const modifierEmploye: AppActions['modifierEmploye'] = useCallback(
    (id, maj) => {
      setEmployes((es) => es.map((e) => e.id === id ? { ...e, ...maj } : e));
      setSession((s) => s && s.id === id ? { ...s, ...maj } : s);
      journaliser('compte', `Droits mis à jour : ${maj.nom} (${maj.role})`, session);
      notifier('Rôle et permissions enregistrés');
    },
    [journaliser, session, notifier]
  );

  const basculerStatutEmploye: AppActions['basculerStatutEmploye'] = useCallback(
    (id) => {
      setEmployes((es) =>
      es.map((e) =>
      e.id === id ? { ...e, statut: e.statut === 'actif' ? 'suspendu' : 'actif' } : e
      )
      );
      const cible = employes.find((e) => e.id === id);
      const suspendu = cible?.statut === 'actif';
      journaliser('compte', `Compte ${suspendu ? 'suspendu' : 'réactivé'} : ${cible?.nom}`, session);
      notifier(suspendu ? 'Compte suspendu' : 'Compte réactivé', 'info');
    },
    [employes, journaliser, session, notifier]
  );

  const supprimerEmploye: AppActions['supprimerEmploye'] = useCallback(
    (id) => {
      const cible = employes.find((e) => e.id === id);
      setEmployes((es) => es.filter((e) => e.id !== id));
      journaliser('compte', `Compte supprimé : ${cible?.nom}`, session);
      notifier('Compte supprimé', 'info');
    },
    [employes, journaliser, session, notifier]
  );

  const reinitialiserMotDePasse: AppActions['reinitialiserMotDePasse'] = useCallback(
    (id, motDePasse) => {
      setEmployes((es) => es.map((e) => e.id === id ? { ...e, motDePasse } : e));
      notifier('Mot de passe réinitialisé');
    },
    [notifier]
  );

  const definirPin: AppActions['definirPin'] = useCallback(
    (pin) => {
      if (!session) return;
      const maj = { ...session, pinActif: pin !== null, pin: pin ?? session.pin };
      setSession(maj);
      setEmployes((es) => es.map((e) => e.id === session.id ? maj : e));
      notifier(pin ? 'Code PIN enregistré' : 'Code PIN désactivé', pin ? 'succes' : 'info');
    },
    [session, notifier]
  );

  const basculerBiometrie = useCallback(() => {
    if (!session) return;
    const maj = { ...session, biometrie: !session.biometrie };
    setSession(maj);
    setEmployes((es) => es.map((e) => e.id === session.id ? maj : e));
    notifier(maj.biometrie ? 'Biométrie activée' : 'Biométrie désactivée', 'info');
  }, [session, notifier]);

  const revoquerAppareil: AppActions['revoquerAppareil'] = useCallback(
    (id) => {
      setAppareils((as) => as.map((a) => a.id === id ? { ...a, actif: !a.actif } : a));
      const cible = appareils.find((a) => a.id === id);
      journaliser('compte', `Appareil ${cible?.actif ? 'révoqué' : 'autorisé'} : ${cible?.nomAppareil}`, session);
      notifier(cible?.actif ? 'Appareil révoqué et déconnecté' : 'Appareil autorisé', 'info');
    },
    [appareils, journaliser, session, notifier]
  );

  const notificationsRole = useMemo(
    () => session ? notifications.filter((n) => n.destinataires.includes(session.role)) : [],
    [notifications, session]
  );

  const value: AppContextValue = {
    boutique,
    employes,
    produits,
    ventes,
    depenses,
    retours,
    notifications,
    pointages,
    activites,
    appareils,
    session,
    verrouille,
    theme,
    enLigne,
    enAttenteSync,
    toasts,
    notificationsRole,
    creerBoutique,
    definirLogo,
    connexion,
    deconnexion,
    deverrouiller,
    verrouiller,
    basculerTheme,
    basculerReseau,
    enregistrerVente,
    signalerDefectueux,
    signalerRetour,
    enregistrerDepense,
    ajouterProduit,
    modifierProduit,
    supprimerProduit,
    traiterRetour,
    pointer,
    marquerNotificationsLues,
    creerEmploye,
    modifierEmploye,
    basculerStatutEmploye,
    supprimerEmploye,
    reinitialiserMotDePasse,
    definirPin,
    basculerBiometrie,
    revoquerAppareil,
    fermerToast,
    notifier
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp doit être utilisé dans AppProvider');
  return ctx;
}