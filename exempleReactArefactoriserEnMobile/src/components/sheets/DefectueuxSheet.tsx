import React, { useEffect, useState } from 'react';
import { useApp } from '../../contexts/AppContext';
import { Produit } from '../../types';
import { Sheet } from '../ui/Sheet';
import { Button } from '../ui/Button';
import { Field, textareaClass } from '../ui/Field';
import { ProduitPicker } from '../ProduitPicker';

interface Props {
  ouvert: boolean;
  onFermer: () => void;
  produitInitial: Produit | null;
}

export function DefectueuxSheet({ ouvert, onFermer, produitInitial }: Props) {
  const { produits, boutique, signalerDefectueux } = useApp();
  const monnaie = boutique?.monnaie ?? 'FCFA';
  const [produit, setProduit] = useState<Produit | null>(null);
  const [description, setDescription] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);

  useEffect(() => {
    if (!ouvert) return;
    setProduit(produitInitial ?? null);
    setDescription('');
    setErreur(null);
  }, [ouvert, produitInitial]);

  const valider = () => {
    if (!produit) return;
    const message = signalerDefectueux(produit.id, description);
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
      titre="Article défectueux"
      sousTitre="Une pièce est retirée du stock et le patron est prévenu">
      
      {!produit ?
      <ProduitPicker produits={produits} onSelect={setProduit} monnaie={monnaie} /> :

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

          <Field label="Description du problème" erreur={erreur ?? undefined} aide="Obligatoire">
            <textarea
            className={textareaClass}
            value={description}
            onChange={(e) => {
              setDescription(e.target.value);
              setErreur(null);
            }}
            placeholder="Ex. couture déchirée sur la manche droite" />
          
          </Field>

          <Button taille="lg" pleineLargeur variante="danger" onClick={valider}>
            Signaler l'article défectueux
          </Button>
        </div>
      }
    </Sheet>);

}