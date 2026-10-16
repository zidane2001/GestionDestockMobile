import React, { useEffect, useState } from 'react';
import { useApp } from '../../contexts/AppContext';
import { Produit } from '../../types';
import { formatMontant } from '../../utils/format';
import { Sheet } from '../ui/Sheet';
import { Button } from '../ui/Button';
import { Field, inputClass, textareaClass } from '../ui/Field';
import { SegmentedControl } from '../ui/SegmentedControl';
import { ProduitPicker } from '../ProduitPicker';

interface Props {
  ouvert: boolean;
  onFermer: () => void;
  produitInitial: Produit | null;
}

export function RetourSheet({ ouvert, onFermer, produitInitial }: Props) {
  const { produits, boutique, signalerRetour } = useApp();
  const monnaie = boutique?.monnaie ?? 'FCFA';
  const [produit, setProduit] = useState<Produit | null>(null);
  const [motif, setMotif] = useState<'remboursement' | 'echange'>('remboursement');
  const [montant, setMontant] = useState('');
  const [description, setDescription] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);

  useEffect(() => {
    if (!ouvert) return;
    setProduit(produitInitial ?? null);
    setMotif('remboursement');
    setMontant(produitInitial ? String(produitInitial.prixVente) : '');
    setDescription('');
    setErreur(null);
  }, [ouvert, produitInitial]);

  const choisir = (p: Produit) => {
    setProduit(p);
    setMontant(String(p.prixVente));
  };

  const valider = () => {
    if (!produit) return;
    const message = signalerRetour(produit.id, motif, description, Number(montant) || 0);
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
      titre="Retour produit"
      sousTitre="Le produit revient en stock ; le patron traite le retour">
      
      {!produit ?
      <ProduitPicker produits={produits} onSelect={choisir} monnaie={monnaie} autoriserRuptures /> :

      <div className="space-y-4 pb-2">
          <div className="flex items-center justify-between rounded-xl bg-surface2 px-3.5 py-3">
            <div className="min-w-0">
              <p className="truncate text-[14px] font-semibold text-ink">{produit.nom}</p>
              <p className="text-2xs text-muted tnum">
                Prix catalogue {formatMontant(produit.prixVente, monnaie)}
              </p>
            </div>
            <button
            type="button"
            onClick={() => setProduit(null)}
            className="shrink-0 text-2xs font-semibold text-primary">
            
              Changer
            </button>
          </div>

          <Field label="Motif du retour">
            <SegmentedControl
            ariaLabel="Motif du retour"
            valeur={motif}
            onChange={(v) => {
              setMotif(v);
              setErreur(null);
            }}
            options={[
            { valeur: 'remboursement', label: 'Remboursement' },
            { valeur: 'echange', label: 'Échange' }]
            } />
          
          </Field>

          {motif === 'remboursement' &&
        <Field label="Montant remboursé" aide="Retiré de la caisse">
              <input
            className={`${inputClass} tnum`}
            value={montant}
            inputMode="decimal"
            onChange={(e) => setMontant(e.target.value.replace(/[^\d.]/g, ''))}
            aria-label="Montant remboursé" />
          
            </Field>
        }

          <Field label="Description" erreur={erreur ?? undefined} aide="Obligatoire">
            <textarea
            className={textareaClass}
            value={description}
            onChange={(e) => {
              setDescription(e.target.value);
              setErreur(null);
            }}
            placeholder={
            motif === 'remboursement' ?
            'Ex. cliente non satisfaite de la taille' :
            'Ex. échange contre la pointure 41'
            } />
          
          </Field>

          <Button taille="lg" pleineLargeur onClick={valider}>
            Enregistrer le retour
          </Button>
        </div>
      }
    </Sheet>);

}