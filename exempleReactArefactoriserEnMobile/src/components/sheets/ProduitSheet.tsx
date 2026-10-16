import React, { useEffect, useState } from 'react';
import { useApp } from '../../contexts/AppContext';
import { Produit } from '../../types';
import { formatMontant } from '../../utils/format';
import { Sheet } from '../ui/Sheet';
import { Button } from '../ui/Button';
import { Field, inputClass } from '../ui/Field';

interface Props {
  ouvert: boolean;
  onFermer: () => void;
  produitInitial: Produit | null;
}

export function ProduitSheet({ ouvert, onFermer, produitInitial }: Props) {
  const { ajouterProduit, modifierProduit, boutique } = useApp();
  const monnaie = boutique?.monnaie ?? 'FCFA';
  const [nom, setNom] = useState('');
  const [prixAchat, setPrixAchat] = useState('');
  const [prixVente, setPrixVente] = useState('');
  const [quantite, setQuantite] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);

  useEffect(() => {
    if (!ouvert) return;
    setNom(produitInitial?.nom ?? '');
    setPrixAchat(produitInitial ? String(produitInitial.prixAchat) : '');
    setPrixVente(produitInitial ? String(produitInitial.prixVente) : '');
    setQuantite(produitInitial ? String(produitInitial.quantite) : '');
    setErreur(null);
  }, [ouvert, produitInitial]);

  const marge = (Number(prixVente) || 0) - (Number(prixAchat) || 0);

  const valider = () => {
    if (nom.trim().length < 2) return setErreur('Le nom du produit est obligatoire.');
    if (Number(prixAchat) <= 0) return setErreur("Le prix d'achat doit être supérieur à 0.");
    if (Number(prixVente) <= 0) return setErreur('Le prix de vente doit être supérieur à 0.');
    if (Number(quantite) < 0 || quantite === '') return setErreur('Indiquez la quantité en stock.');
    const donnees = {
      nom: nom.trim(),
      prixAchat: Number(prixAchat),
      prixVente: Number(prixVente),
      quantite: Number(quantite)
    };
    if (produitInitial) modifierProduit(produitInitial.id, donnees);else
    ajouterProduit(donnees);
    onFermer();
  };

  return (
    <Sheet
      ouvert={ouvert}
      onFermer={onFermer}
      titre={produitInitial ? 'Modifier le produit' : 'Ajouter un produit'}
      sousTitre="Le prix d'achat reste visible par vous seul">
      
      <div className="space-y-4 pb-2">
        <Field label="Nom du produit">
          <input
            className={inputClass}
            value={nom}
            onChange={(e) => setNom(e.target.value)}
            placeholder="Ex. Chemise coton homme" />
          
        </Field>

        <div className="grid grid-cols-2 gap-3">
          <Field label="Prix d'achat">
            <input
              className={`${inputClass} tnum`}
              value={prixAchat}
              inputMode="decimal"
              onChange={(e) => setPrixAchat(e.target.value.replace(/[^\d.]/g, ''))}
              placeholder="0" />
            
          </Field>
          <Field label="Prix de vente">
            <input
              className={`${inputClass} tnum`}
              value={prixVente}
              inputMode="decimal"
              onChange={(e) => setPrixVente(e.target.value.replace(/[^\d.]/g, ''))}
              placeholder="0" />
            
          </Field>
        </div>

        <Field label={produitInitial ? 'Quantité en stock' : 'Quantité initiale'}>
          <input
            className={`${inputClass} tnum`}
            value={quantite}
            inputMode="numeric"
            onChange={(e) => setQuantite(e.target.value.replace(/\D/g, ''))}
            placeholder="0" />
          
        </Field>

        <div className="flex items-baseline justify-between rounded-xl bg-surface2 px-3.5 py-3">
          <span className="text-[13px] font-semibold text-muted">Marge par pièce</span>
          <span className={`text-[17px] font-bold tnum ${marge <= 0 ? 'text-danger' : 'text-ink'}`}>
            {formatMontant(marge, monnaie)}
          </span>
        </div>

        {erreur && <p className="text-[13px] font-medium text-danger">{erreur}</p>}

        <Button taille="lg" pleineLargeur onClick={valider}>
          {produitInitial ? 'Enregistrer les modifications' : 'Ajouter au stock'}
        </Button>
      </div>
    </Sheet>);

}