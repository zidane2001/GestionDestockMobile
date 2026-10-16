import React from 'react';
import { SmartphoneIcon } from 'lucide-react';
import { useApp } from '../contexts/AppContext';
import { SubScreen } from '../components/SubScreen';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { ilYA, ROLE_LABEL } from '../utils/format';

export function Appareils() {
  const { appareils, revoquerAppareil } = useApp();
  const actifs = appareils.filter((a) => a.actif).length;

  return (
    <SubScreen titre="Appareils connectés" sousTitre={`${actifs} appareil(s) autorisé(s)`}>
      <div className="px-4 py-4">
        <p className="text-[13px] leading-relaxed text-muted">
          Chaque téléphone est enregistré au premier lancement. Révoquez un appareil inconnu : il est
          déconnecté immédiatement et ne peut plus se reconnecter.
        </p>

        <ul className="mt-4 space-y-2">
          {appareils.map((a) =>
          <li key={a.id} className="rounded-2xl border border-line bg-surface px-4 py-3.5">
              <div className="flex items-start gap-3">
                <span
                className={`grid h-10 w-10 shrink-0 place-items-center rounded-xl ${
                a.actif ? 'bg-primarySoft text-primary' : 'bg-surface2 text-muted'}`
                }>
                
                  <SmartphoneIcon size={18} />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[14px] font-semibold text-ink">{a.nomAppareil}</p>
                  <p className="text-2xs text-muted">
                    {ROLE_LABEL[a.role]} · {a.employeNom} · {ilYA(a.derniereConnexion)}
                  </p>
                </div>
                {a.actif ? <Badge ton="succes">Autorisé</Badge> : <Badge ton="danger">Révoqué</Badge>}
              </div>
              <div className="mt-3">
                <Button
                taille="sm"
                variante={a.actif ? 'danger' : 'secondaire'}
                onClick={() => revoquerAppareil(a.id)}>
                
                  {a.actif ? 'Révoquer cet appareil' : 'Autoriser à nouveau'}
                </Button>
              </div>
            </li>
          )}
        </ul>
      </div>
    </SubScreen>);

}