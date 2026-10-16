import React, { useMemo, useState } from 'react';
import {
  AlertTriangleIcon,
  ArrowLeftRightIcon,
  BanknoteIcon,
  LogInIcon,
  LogOutIcon,
  PackagePlusIcon,
  PencilIcon,
  PlusIcon,
  ReceiptTextIcon,
  SearchIcon,
  ShoppingCartIcon,
  Trash2Icon } from
'lucide-react';
import { useApp } from '../contexts/AppContext';
import { TypeSheet } from './Home';
import { Produit } from '../types';
import { peut } from '../utils/permissions';
import { formatMontant } from '../utils/format';
import { rechercheProduits, valeurStock } from '../utils/stats';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { EmptyState } from '../components/ui/EmptyState';
import { inputClass } from '../components/ui/Field';

interface Props {
  onOuvrirSheet: (type: TypeSheet, produit?: Produit | null) => void;
}

export function ActionsStock({ onOuvrirSheet }: Props) {
  const { produits, session, boutique, pointages, pointer, supprimerProduit, notifier } = useApp();
  const [requete, setRequete] = useState('');
  const [aSupprimer, setASupprimer] = useState<Produit | null>(null);
  /** Les droits sont portés par le compte, pas seulement par le rôle. */
  const acteur = session;
  const monnaie = boutique?.monnaie ?? 'FCFA';

  const actifs = useMemo(() => produits.filter((p) => p.actif), [produits]);
  const liste = useMemo(() => rechercheProduits(actifs, requete), [actifs, requete]);
  const ruptures = actifs.filter((p) => p.quantite === 0).length;

  const jour = new Date().toISOString().slice(0, 10);
  const monPointage = pointages.find((p) => p.employeId === session?.id && p.date === jour);

  const actions = [
  {
    cle: 'vente' as TypeSheet,
    label: 'Enregistrer une vente',
    description: 'Article vendu',
    icone: ShoppingCartIcon,
    visible: peut(acteur, 'vendre'),
    principal: true
  },
  {
    cle: 'defectueux' as TypeSheet,
    label: 'Article défectueux',
    description: 'Retirer du stock',
    icone: AlertTriangleIcon,
    visible: peut(acteur, 'defectueux')
  },
  {
    cle: 'retour' as TypeSheet,
    label: 'Retour produit',
    description: 'Remboursement / échange',
    icone: ArrowLeftRightIcon,
    visible: peut(acteur, 'retour')
  },
  {
    cle: 'depense' as TypeSheet,
    label: 'Dépense',
    description: 'Loyer, factures…',
    icone: ReceiptTextIcon,
    visible: peut(acteur, 'depense')
  },
  {
    cle: 'sortie' as TypeSheet,
    label: 'Sortie de caisse',
    description: 'Justifier une diminution',
    icone: BanknoteIcon,
    visible: peut(acteur, 'sortieCaisse')
  },
  {
    cle: 'produit' as TypeSheet,
    label: 'Ajouter un produit',
    description: 'Nouvel article en stock',
    icone: PackagePlusIcon,
    visible: peut(acteur, 'gererProduits')
  }].
  filter((a) => a.visible);

  const principale = actions.find((a) => a.principal);
  const secondaires = actions.filter((a) => !a.principal);

  return (
    <div className="space-y-4 px-4 pb-16 pt-4">
      {/* Pointage — selon le droit attribué au compte */}
      {peut(acteur, 'pointer') &&
      <section className="flex items-center gap-3 rounded-2xl border border-line bg-surface px-4 py-3">
          <div className="min-w-0 flex-1">
            <p className="text-[13px] font-bold text-ink">Ma journée</p>
            <p className="mt-0.5 text-2xs text-muted tnum">
              {monPointage ?
            `Arrivée ${monPointage.heureArrivee}${
            monPointage.heureDepart ? ` · Départ ${monPointage.heureDepart}` : ' · en poste'}` :

            "Pas encore pointé aujourd'hui"}
            </p>
          </div>
          {!monPointage ?
        <Button
          taille="sm"
          onClick={() => {
            const err = pointer('arrivee');
            if (err) notifier(err, 'erreur');
          }}>
          
              <LogInIcon size={15} /> Arrivée
            </Button> :
        !monPointage.heureDepart ?
        <Button
          taille="sm"
          variante="secondaire"
          onClick={() => {
            const err = pointer('depart');
            if (err) notifier(err, 'erreur');
          }}>
          
              <LogOutIcon size={15} /> Départ
            </Button> :

        <Badge ton="succes">Journée terminée</Badge>
        }
        </section>
      }

      {/* Action principale mise en avant, actions secondaires en dessous */}
      {principale &&
      <button
        type="button"
        onClick={() => onOuvrirSheet(principale.cle)}
        className="flex w-full items-center gap-4 rounded-2xl bg-primary px-5 py-5 text-left text-onPrimary transition-transform duration-150 ease-out active:scale-[0.99]">
        
          <span className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-white/15">
            <ShoppingCartIcon size={21} />
          </span>
          <span>
            <span className="block text-[16px] font-bold">Enregistrer une vente</span>
            <span className="block text-[13px] opacity-80">
              Stock et caisse mis à jour, équipe notifiée
            </span>
          </span>
        </button>
      }

      <section className="grid grid-cols-2 gap-2.5">
        {secondaires.map((a) => {
          const Icone = a.icone;
          return (
            <button
              key={a.label}
              type="button"
              onClick={() => onOuvrirSheet(a.cle)}
              className="flex flex-col gap-2 rounded-2xl border border-line bg-surface px-3.5 py-3.5 text-left transition-colors duration-150 ease-out hover:bg-surface2">
              
              <Icone size={19} className="text-primary" />
              <span>
                <span className="block text-[13px] font-semibold leading-tight text-ink">{a.label}</span>
                <span className="mt-0.5 block text-2xs text-muted">{a.description}</span>
              </span>
            </button>);

        })}
      </section>

      {/* Stock */}
      <section>
        <div className="flex items-end justify-between gap-3">
          <div>
            <h2 className="text-[15px] font-bold text-ink">Stock</h2>
            <p className="mt-0.5 text-2xs text-muted tnum">
              {actifs.length} produits · valeur {formatMontant(valeurStock(actifs), monnaie)}
              {ruptures > 0 && ` · ${ruptures} en rupture`}
            </p>
          </div>
          {peut(acteur, 'gererProduits') &&
          <Button taille="sm" variante="secondaire" onClick={() => onOuvrirSheet('produit')}>
              <PlusIcon size={15} /> Produit
            </Button>
          }
        </div>

        <div className="relative mt-3">
          <SearchIcon size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
          <input
            className={`${inputClass} pl-10`}
            value={requete}
            onChange={(e) => setRequete(e.target.value)}
            placeholder="Rechercher un produit…"
            aria-label="Rechercher dans le stock" />
          
        </div>

        {liste.length === 0 ?
        <EmptyState
          icone={<SearchIcon size={20} />}
          titre="Aucun résultat"
          texte={`Aucun produit ne correspond à « ${requete} ». Vérifiez l'orthographe.`} /> :


        <ul className="mt-3 space-y-2">
            {liste.map((p) =>
          <li
            key={p.id}
            className="rounded-2xl border border-line bg-surface px-4 py-3">
            
                <div className="flex items-start gap-3">
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[14px] font-semibold text-ink">{p.nom}</p>
                    <p className="mt-0.5 text-2xs text-muted tnum">
                      Prix de vente {formatMontant(p.prixVente, monnaie)}
                      {peut(acteur, 'voirPrixAchat') &&
                  ` · achat ${formatMontant(p.prixAchat, monnaie)} · marge ${formatMontant(
                    p.prixVente - p.prixAchat,
                    monnaie
                  )}`}
                    </p>
                  </div>
                  <div className="shrink-0 text-right">
                    <p
                  className={`text-[17px] font-extrabold leading-none tnum ${
                  p.quantite === 0 ? 'text-danger' : 'text-ink'}`
                  }>
                  
                      {p.quantite}
                    </p>
                    <p className="text-2xs text-muted">en stock</p>
                  </div>
                </div>

                <div className="mt-3 flex items-center gap-2">
                  {p.quantite === 0 ?
              <Badge ton="danger">Rupture de stock</Badge> :

              <Button taille="sm" variante="secondaire" onClick={() => onOuvrirSheet('vente', p)}>
                      Vendre
                    </Button>
              }
                  {peut(acteur, 'gererProduits') &&
              <>
                      <button
                  type="button"
                  onClick={() => onOuvrirSheet('produit', p)}
                  aria-label={`Modifier ${p.nom}`}
                  className="grid h-9 w-9 place-items-center rounded-xl bg-surface2 text-muted transition-colors duration-150 ease-out hover:text-ink">
                  
                        <PencilIcon size={15} />
                      </button>
                      <button
                  type="button"
                  onClick={() => setASupprimer(p)}
                  aria-label={`Supprimer ${p.nom}`}
                  className="grid h-9 w-9 place-items-center rounded-xl bg-surface2 text-muted transition-colors duration-150 ease-out hover:text-danger">
                  
                        <Trash2Icon size={15} />
                      </button>
                    </>
              }
                </div>

                {aSupprimer?.id === p.id &&
            <div className="mt-3 rounded-xl border border-danger/30 bg-danger/10 px-3.5 py-3">
                    <p className="text-[13px] font-medium text-ink">
                      Supprimer « {p.nom} » du stock actif ? L'historique des ventes est conservé.
                    </p>
                    <div className="mt-2.5 flex gap-2">
                      <Button
                  taille="sm"
                  variante="danger"
                  onClick={() => {
                    supprimerProduit(p.id);
                    setASupprimer(null);
                  }}>
                  
                        Supprimer
                      </Button>
                      <Button taille="sm" variante="fantome" onClick={() => setASupprimer(null)}>
                        Annuler
                      </Button>
                    </div>
                  </div>
            }
              </li>
          )}
          </ul>
        }
      </section>
    </div>);

}