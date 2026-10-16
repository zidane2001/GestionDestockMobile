import React, { useMemo } from 'react';
import { ClockIcon } from 'lucide-react';
import { useApp } from '../contexts/AppContext';
import { SubScreen } from '../components/SubScreen';
import { Badge } from '../components/ui/Badge';
import { EmptyState } from '../components/ui/EmptyState';
import { ROLE_LABEL } from '../utils/format';

export function Pointages() {
  const { pointages } = useApp();

  const parJour = useMemo(() => {
    const map = new Map<string, typeof pointages>();
    [...pointages].
    sort((a, b) => a.date < b.date ? 1 : -1).
    forEach((p) => map.set(p.date, [...(map.get(p.date) ?? []), p]));
    return [...map.entries()];
  }, [pointages]);

  const aujourdhui = new Date().toISOString().slice(0, 10);

  return (
    <SubScreen titre="Pointages" sousTitre="Arrivées et départs de l'équipe">
      {parJour.length === 0 ?
      <EmptyState
        icone={<ClockIcon size={20} />}
        titre="Aucun pointage"
        texte="Les arrivées et départs pointés par vos employés apparaîtront ici." /> :


      <div className="space-y-4 px-4 py-4">
          {parJour.map(([jour, items]) =>
        <section key={jour}>
              <h2 className="mb-2 text-2xs font-bold uppercase tracking-wide text-muted">
                {jour === aujourdhui ?
            "Aujourd'hui" :
            new Date(jour).toLocaleDateString('fr-FR', {
              weekday: 'long',
              day: '2-digit',
              month: 'long'
            })}
              </h2>
              <ul className="overflow-hidden rounded-2xl border border-line bg-surface">
                {items.map((p, i) =>
            <li
              key={p.id}
              className={`flex items-center gap-3 px-4 py-3 ${i > 0 ? 'border-t border-line' : ''}`}>
              
                    <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-primarySoft text-[13px] font-bold text-primary">
                      {p.employeNom.slice(0, 1)}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-[14px] font-semibold text-ink">{p.employeNom}</p>
                      <p className="text-2xs text-muted">{ROLE_LABEL[p.role]}</p>
                    </div>
                    <div className="shrink-0 text-right">
                      <p className="text-[13px] font-semibold text-ink tnum">
                        {p.heureArrivee} → {p.heureDepart ?? '—'}
                      </p>
                      {!p.heureDepart && <Badge ton="primaire">En poste</Badge>}
                    </div>
                  </li>
            )}
              </ul>
            </section>
        )}
        </div>
      }
    </SubScreen>);

}