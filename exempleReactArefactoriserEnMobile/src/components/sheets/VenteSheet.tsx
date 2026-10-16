import React, { useEffect, useState } from 'react';
import { MinusIcon, PlusIcon } from 'lucide-react';
import { useApp } from '../../contexts/AppContext';
import { Produit } from '../../types';
import { formatMontant } from '../../utils/format';
import { Sheet } from '../ui/Sheet';
import { Button } from '../ui/Button';
import { Field, inputClass } from '../ui/Field';
import { ProduitPicker } from '../ProduitPicker';

interface Props {
  ouvert: boolean;
  onFermer: () => void;
  produitInitial: Produit | null;
}

export function VenteSheet({ ouvert, onFermer, produitInitial }: Props) {
  const { produits, boutique, enregistrerVente } = useApp();
  const monnaie = boutique?.monnaie ?? 'FCFA';
  const [produit, setProduit] = useState<Produit | null>(null);
  const [quantite, setQuantite] = useState(1);
  const [prix, setPrix] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);

  useEffect(() => {
    if (!ouvert) return;
    setProduit(produitInitial ?? null);
    setQuantite(1);
    setPrix(produitInitial ? String(produitInitial.prixVente) : '');
    setErreur(null);
  }, [ouvert, produitInitial]);

  const choisir = (p: Produit) => {
    setProduit(p);
    setPrix(String(p.prixVente));
    setQuantite(1);
    setErreur(null);
  };

  const total = (Number(prix) || 0) * quantite;

  const valider = () => {
    if (!produit) return;
    const message = enregistrerVente(produit.id, quantite, Number(prix) || 0);
    if (message) {
      setErreur(message);
      return;
    }
    onFermer();
  };

  return (
    <Sheet
      ouvert={ouvert}
      onFermer={onFermer}
      titre="Enregistrer une vente"
      sousTitre={produit ? produit.nom : 'Choisissez le produit vendu'}>
      
      {!produit ?
      <ProduitPicker produits={produits} onSelect={choisir} monnaie={monnaie} /> :

      <div className="space-y-4 pb-2">
          <div className="flex items-center justify-between rounded-xl bg-surface2 px-3.5 py-3">
            <div className="min-w-0">
              <p className="truncate text-[14px] font-semibold text-ink">{produit.nom}</p>
              <p className="text-2xs text-muted tnum">{produit.quantite} en stock</p>
            </div>
            <button
            type="button"
            onClick={() => setProduit(null)}
            className="shrink-0 text-2xs font-semibold text-primary">
            
              Changer
            </button>
          </div>

          <Field label="Quantité" aide={`Maximum ${produit.quantite}`}>
            <div className="flex items-center gap-3">
              <button
              type="button"
              onClick={() => setQuantite((q) => Math.max(1, q - 1))}
              aria-label="Diminuer la quantité"
              className="grid h-12 w-12 place-items-center rounded-xl bg-surface2 text-ink transition-colors duration-150 ease-out hover:bg-line/60">
              
                <MinusIcon size={18} />
              </button>
              <input
              className={`${inputClass} text-center text-[18px] font-bold tnum`}
              value={quantite}
              inputMode="numeric"
              onChange={(e) => setQuantite(Math.max(1, Number(e.target.value.replace(/\D/g, '')) || 1))}
              aria-label="Quantité" />
            
              <button
              type="button"
              onClick={() => setQuantite((q) => Math.min(produit.quantite, q + 1))}
              aria-label="Augmenter la quantité"
              className="grid h-12 w-12 place-items-center rounded-xl bg-surface2 text-ink transition-colors duration-150 ease-out hover:bg-line/60">
              
                <PlusIcon size={18} />
              </button>
            </div>
          </Field>

          <Field label="Prix de vente réel (unitaire)" aide="Modifiable pour appliquer une remise">
            <input
            className={`${inputClass} tnum`}
            value={prix}
            inputMode="decimal"
            onChange={(e) => setPrix(e.target.value.replace(/[^\d.]/g, ''))}
            aria-label="Prix de vente unitaire" />
          
          </Field>

          <div className="flex items-baseline justify-between rounded-xl border border-primary/25 bg-primarySoft px-3.5 py-3">
            <span className="text-[13px] font-semibold text-primary">Total encaissé</span>
            <span className="text-[20px] font-extrabold text-primary tnum">
              {formatMontant(total, monnaie)}
            </span>
          </div>

          {erreur && <p className="text-[13px] font-medium text-danger">{erreur}</p>}

          <Button taille="lg" pleineLargeur onClick={valider}>
            Signaler vendu
          </Button>
          <p className="pb-1 text-center text-2xs text-muted">
            Le stock diminue, la caisse augmente et l'équipe est notifiée avec votre nom.
          </p>
        </div>
      }
    </Sheet>);

}