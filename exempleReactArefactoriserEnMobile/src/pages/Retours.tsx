import React, { useMemo, useState } from 'react';
import { ArrowLeftRightIcon } from 'lucide-react';
import { useApp } from '../contexts/AppContext';
import { SubScreen } from '../components/SubScreen';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { EmptyState } from '../components/ui/EmptyState';
import { dateHeure, formatMontant } from '../utils/format';
import { Retour } from '../types';

const MOTIF_LABEL: Record<Retour['motif'], string> = {
  remboursement: 'Remboursement',
  echange: 'Échange',
  defectueux: 'Défectueux'
};

const STATUT_LABEL: Record<Retour['statut'], string> = {
  en_attente: 'En attente',
  traite: 'Traité',
  refuse: 'Refusé'
};

export function Retours() {
  const { retours, traiterRetour, boutique } = useApp();
  const monnaie = boutique?.monnaie ?? 'FCFA';
  const [filtre, setFiltre] = useState<'tous' | Retour['statut']>('en_attente');

  const liste = useMemo(
    () => retours.filter((r) => filtre === 'tous' || r.statut === filtre),
    [retours, filtre]
  );

  return (
    <SubScreen
      titre="Retours & défectueux"
      sousTitre={`${retours.filter((r) => r.statut === 'en_attente').length} en attente de traitement`}>
      
      <div className="flex gap-1.5 border-b border-line bg-canvas px-4 py-3">
        {(['en_attente', 'traite', 'refuse', 'tous'] as const).map((f) =>
        <button
          key={f}
          type="button"
          onClick={() => setFiltre(f)}
          className={`rounded-full border px-3 py-1.5 text-2xs font-semibold transition-colors duration-150 ease-out ${
          filtre === f ?
          'border-primary bg-primarySoft text-primary' :
          'border-line bg-surface text-muted hover:text-ink'}`
          }>
          
            {f === 'tous' ? 'Tous' : STATUT_LABEL[f]}
          </button>
        )}
      </div>

      {liste.length === 0 ?
      <EmptyState
        icone={<ArrowLeftRightIcon size={20} />}
        titre="Aucun retour"
        texte="Les retours et articles défectueux signalés par l'équipe s'afficheront ici." /> :


      <ul className="space-y-2 px-4 py-4">
          {liste.map((r) =>
        <li key={r.id} className="rounded-2xl border border-line bg-surface px-4 py-3.5">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="truncate text-[14px] font-semibold text-ink">{r.produitNom}</p>
                  <p className="mt-0.5 text-2xs text-muted">
                    {MOTIF_LABEL[r.motif]}
                    {r.montant > 0 && ` · ${formatMontant(r.montant, monnaie)}`} · {r.auteurNom}
                  </p>
                </div>
                <Badge
              ton={
              r.statut === 'traite' ? 'succes' : r.statut === 'refuse' ? 'danger' : 'accent'
              }>
              
                  {STATUT_LABEL[r.statut]}
                </Badge>
              </div>

              <p className="mt-2 rounded-xl bg-surface2 px-3 py-2 text-[13px] leading-snug text-ink">
                {r.description}
              </p>
              <p className="mt-1.5 text-2xs text-muted tnum">{dateHeure(r.date)}</p>

              {r.statut === 'en_attente' &&
          <div className="mt-3 flex gap-2">
                  <Button taille="sm" onClick={() => traiterRetour(r.id, 'traite')}>
                    Marquer traité
                  </Button>
                  <Button
              taille="sm"
              variante="secondaire"
              onClick={() => traiterRetour(r.id, 'refuse')}>
              
                    Refuser
                  </Button>
                </div>
          }
            </li>
        )}
        </ul>
      }
    </SubScreen>);

}