import React, { useMemo, useState } from 'react';
import { SearchIcon } from 'lucide-react';
import { Produit } from '../types';
import { rechercheProduits } from '../utils/stats';
import { formatMontant } from '../utils/format';
import { inputClass } from './ui/Field';

interface Props {
  produits: Produit[];
  onSelect: (p: Produit) => void;
  monnaie: string;
  autoriserRuptures?: boolean;
}

export function ProduitPicker({ produits, onSelect, monnaie, autoriserRuptures }: Props) {
  const [requete, setRequete] = useState('');
  const liste = useMemo(() => {
    const base = produits.filter((p) => p.actif && (autoriserRuptures || p.quantite > 0));
    return rechercheProduits(base, requete);
  }, [produits, requete, autoriserRuptures]);

  return (
    <div className="space-y-3">
      <div className="relative">
        <SearchIcon size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
        <input
          className={`${inputClass} pl-10`}
          value={requete}
          onChange={(e) => setRequete(e.target.value)}
          placeholder="Rechercher un produit…"
          aria-label="Rechercher un produit" />
        
      </div>

      {liste.length === 0 ?
      <p className="py-6 text-center text-[13px] text-muted">
          Aucun produit ne correspond à « {requete} ».
        </p> :

      <ul className="max-h-[46vh] space-y-1.5 overflow-y-auto no-scrollbar">
          {liste.map((p) =>
        <li key={p.id}>
              <button
            type="button"
            onClick={() => onSelect(p)}
            className="flex w-full items-center justify-between gap-3 rounded-xl border border-line bg-surface2 px-3.5 py-3 text-left transition-colors duration-150 ease-out hover:border-primary/40">
            
                <span className="min-w-0">
                  <span className="block truncate text-[14px] font-semibold text-ink">{p.nom}</span>
                  <span className="block text-2xs text-muted tnum">
                    {formatMontant(p.prixVente, monnaie)}
                  </span>
                </span>
                <span
              className={`shrink-0 text-[13px] font-bold tnum ${
              p.quantite === 0 ? 'text-danger' : 'text-muted'}`
              }>
              
                  {p.quantite} en stock
                </span>
              </button>
            </li>
        )}
        </ul>
      }
    </div>);

}