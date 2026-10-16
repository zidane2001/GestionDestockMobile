import React, { useEffect } from 'react';
import {
  AlertTriangleIcon,
  ArrowLeftRightIcon,
  BellIcon,
  ClockIcon,
  PackagePlusIcon,
  ReceiptTextIcon,
  ShoppingCartIcon,
  UserCogIcon } from
'lucide-react';
import { useApp } from '../contexts/AppContext';
import { SubScreen } from '../components/SubScreen';
import { EmptyState } from '../components/ui/EmptyState';
import { ilYA } from '../utils/format';
import { NotifType } from '../types';

const ICONES: Record<NotifType, typeof BellIcon> = {
  vente: ShoppingCartIcon,
  depense: ReceiptTextIcon,
  stock: AlertTriangleIcon,
  produit: PackagePlusIcon,
  retour: ArrowLeftRightIcon,
  compte: UserCogIcon,
  pointage: ClockIcon
};

export function Notifications() {
  const { notificationsRole, marquerNotificationsLues } = useApp();
  const nonLues = notificationsRole.filter((n) => !n.estLu).length;

  useEffect(() => {
    const t = window.setTimeout(marquerNotificationsLues, 1200);
    return () => window.clearTimeout(t);
  }, [marquerNotificationsLues]);

  return (
    <SubScreen
      titre="Notifications"
      sousTitre={nonLues > 0 ? `${nonLues} non lue${nonLues > 1 ? 's' : ''}` : 'Tout est à jour'}
      action={
      nonLues > 0 ?
      <button
        type="button"
        onClick={marquerNotificationsLues}
        className="text-2xs font-semibold text-primary">
        
            Tout marquer lu
          </button> :
      undefined
      }>
      
      {notificationsRole.length === 0 ?
      <EmptyState
        icone={<BellIcon size={20} />}
        titre="Aucune notification"
        texte="Les ventes, dépenses et alertes de stock de l'équipe s'afficheront ici." /> :


      <ul className="divide-y divide-line">
          {notificationsRole.map((n) => {
          const Icone = ICONES[n.type];
          return (
            <li
              key={n.id}
              className={`flex gap-3 px-4 py-3.5 ${n.estLu ? 'bg-canvas' : 'bg-surface'}`}>
              
                <span
                className={`mt-0.5 grid h-9 w-9 shrink-0 place-items-center rounded-xl ${
                n.estLu ? 'bg-surface2 text-muted' : 'bg-primarySoft text-primary'}`
                }>
                
                  <Icone size={17} />
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-baseline justify-between gap-2">
                    <p className="truncate text-[14px] font-semibold text-ink">{n.titre}</p>
                    <span className="shrink-0 text-2xs text-muted">{ilYA(n.date)}</span>
                  </div>
                  <p className="mt-0.5 text-[13px] leading-snug text-muted">{n.message}</p>
                </div>
                {!n.estLu && <span className="mt-2 h-2 w-2 shrink-0 rounded-full bg-primary" />}
              </li>);

        })}
        </ul>
      }
    </SubScreen>);

}