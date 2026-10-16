import React, { useEffect, useState } from 'react';
import { useApp } from '../../contexts/AppContext';
import { formatMontant } from '../../utils/format';
import { Sheet } from '../ui/Sheet';
import { Button } from '../ui/Button';
import { Field, inputClass } from '../ui/Field';

interface Props {
  ouvert: boolean;
  onFermer: () => void;
  type: 'depense' | 'sortie_justifiee';
}

const MOTIFS_RAPIDES = ['Loyer', 'Électricité', 'Eau', 'Impôts', 'Transport', 'Réassort'];

export function DepenseSheet({ ouvert, onFermer, type }: Props) {
  const { boutique, enregistrerDepense } = useApp();
  const monnaie = boutique?.monnaie ?? 'FCFA';
  const [description, setDescription] = useState('');
  const [montant, setMontant] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);

  useEffect(() => {
    if (!ouvert) return;
    setDescription('');
    setMontant('');
    setErreur(null);
  }, [ouvert, type]);

  const valider = () => {
    const message = enregistrerDepense(description, Number(montant) || 0, type);
    if (message) {
      setErreur(message);
      return;
    }
    onFermer();
  };

  const restant = (boutique?.soldeCaisse ?? 0) - (Number(montant) || 0);

  return (
    <Sheet
      ouvert={ouvert}
      onFermer={onFermer}
      titre={type === 'depense' ? 'Signaler une dépense' : 'Justifier une sortie de caisse'}
      sousTitre={`Caisse actuelle : ${formatMontant(boutique?.soldeCaisse ?? 0, monnaie)}`}>
      
      <div className="space-y-4 pb-2">
        <Field label="Motif" aide="Obligatoire">
          <input
            className={inputClass}
            value={description}
            onChange={(e) => {
              setDescription(e.target.value);
              setErreur(null);
            }}
            placeholder={type === 'depense' ? 'Ex. loyer du mois' : 'Ex. transport marchandise'} />
          
        </Field>

        <div className="flex flex-wrap gap-2">
          {MOTIFS_RAPIDES.map((m) =>
          <button
            key={m}
            type="button"
            onClick={() => setDescription(m)}
            className="rounded-full border border-line bg-surface2 px-3 py-1.5 text-2xs font-semibold text-muted transition-colors duration-150 ease-out hover:text-ink">
            
              {m}
            </button>
          )}
        </div>

        <Field label="Montant" erreur={erreur ?? undefined}>
          <input
            className={`${inputClass} tnum`}
            value={montant}
            inputMode="decimal"
            onChange={(e) => {
              setMontant(e.target.value.replace(/[^\d.]/g, ''));
              setErreur(null);
            }}
            placeholder="0" />
          
        </Field>

        <div className="flex items-baseline justify-between rounded-xl bg-surface2 px-3.5 py-3">
          <span className="text-[13px] font-semibold text-muted">Caisse après opération</span>
          <span
            className={`text-[17px] font-bold tnum ${restant < 0 ? 'text-danger' : 'text-ink'}`}>
            
            {formatMontant(restant, monnaie)}
          </span>
        </div>

        <Button taille="lg" pleineLargeur onClick={valider}>
          {type === 'depense' ? 'Enregistrer la dépense' : 'Justifier la sortie'}
        </Button>
      </div>
    </Sheet>);

}