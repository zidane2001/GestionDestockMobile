import React, { useMemo, useState } from 'react';
import { HistoryIcon } from 'lucide-react';
import { useApp } from '../contexts/AppContext';
import { SubScreen } from '../components/SubScreen';
import { EmptyState } from '../components/ui/EmptyState';
import { dateHeure, ROLE_LABEL } from '../utils/format';

const FILTRES = [
{ cle: 'tous', label: 'Tout' },
{ cle: 'vente', label: 'Ventes' },
{ cle: 'depense', label: 'Dépenses' },
{ cle: 'produit', label: 'Produits' },
{ cle: 'retour', label: 'Retours' },
{ cle: 'pointage', label: 'Pointages' },
{ cle: 'compte', label: 'Comptes' },
{ cle: 'connexion', label: 'Connexions' }];


export function Journal() {
  const { activites, employes } = useApp();
  const [type, setType] = useState('tous');
  const [employe, setEmploye] = useState('tous');

  const liste = useMemo(
    () =>
    activites.filter(
      (a) =>
      (type === 'tous' || a.type === type) && (employe === 'tous' || a.employeNom === employe)
    ),
    [activites, type, employe]
  );

  return (
    <SubScreen titre="Journal d'activité" sousTitre={`${liste.length} événement(s)`}>
      <div className="sticky top-0 z-10 space-y-2 border-b border-line bg-canvas/95 px-4 py-3 backdrop-blur">
        <div className="flex gap-1.5 overflow-x-auto no-scrollbar">
          {FILTRES.map((f) =>
          <button
            key={f.cle}
            type="button"
            onClick={() => setType(f.cle)}
            className={`shrink-0 rounded-full border px-3 py-1.5 text-2xs font-semibold transition-colors duration-150 ease-out ${
            type === f.cle ?
            'border-primary bg-primarySoft text-primary' :
            'border-line bg-surface text-muted hover:text-ink'}`
            }>
            
              {f.label}
            </button>
          )}
        </div>
        <div className="flex gap-1.5 overflow-x-auto no-scrollbar">
          {[{ id: 'tous', nom: 'Toute l’équipe' }, ...employes].map((e) =>
          <button
            key={e.id}
            type="button"
            onClick={() => setEmploye(e.nom === 'Toute l’équipe' ? 'tous' : e.nom)}
            className={`shrink-0 rounded-full border px-3 py-1.5 text-2xs font-semibold transition-colors duration-150 ease-out ${
            employe === 'tous' && e.id === 'tous' || employe === e.nom ?
            'border-primary bg-primarySoft text-primary' :
            'border-line bg-surface text-muted hover:text-ink'}`
            }>
            
              {e.nom}
            </button>
          )}
        </div>
      </div>

      {liste.length === 0 ?
      <EmptyState
        icone={<HistoryIcon size={20} />}
        titre="Aucun événement"
        texte="Aucune action ne correspond à ces filtres." /> :


      <ol className="px-4 py-4">
          {liste.map((a, i) =>
        <li key={a.id} className="flex gap-3">
              <div className="flex flex-col items-center pt-1.5">
                <span className="h-2 w-2 rounded-full bg-primary" />
                {i < liste.length - 1 && <span className="w-px flex-1 bg-line" />}
              </div>
              <div className={`min-w-0 flex-1 ${i < liste.length - 1 ? 'pb-5' : ''}`}>
                <p className="text-[14px] font-semibold leading-snug text-ink">{a.description}</p>
                <p className="mt-0.5 text-2xs text-muted tnum">
                  {a.employeNom} ({ROLE_LABEL[a.employeRole]}) · {dateHeure(a.date)}
                </p>
              </div>
            </li>
        )}
        </ol>
      }
    </SubScreen>);

}