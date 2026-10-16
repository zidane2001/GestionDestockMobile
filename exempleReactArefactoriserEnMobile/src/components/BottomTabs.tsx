import React from 'react';
import { LayoutDashboardIcon, PackageIcon } from 'lucide-react';

export type Onglet = 'tableau' | 'actions';

export function BottomTabs({
  actif,
  onChange



}: {actif: Onglet;onChange: (o: Onglet) => void;}) {
  const items: {cle: Onglet;label: string;icone: typeof PackageIcon;}[] = [
  { cle: 'tableau', label: 'Tableau de bord', icone: LayoutDashboardIcon },
  { cle: 'actions', label: 'Actions & Stock', icone: PackageIcon }];


  return (
    <nav
      aria-label="Navigation principale"
      className="grid grid-cols-2 gap-1 border-t border-line bg-surface px-3 pb-3 pt-2">
      
      {items.map((i) => {
        const Icone = i.icone;
        const estActif = actif === i.cle;
        return (
          <button
            key={i.cle}
            type="button"
            onClick={() => onChange(i.cle)}
            aria-current={estActif ? 'page' : undefined}
            className={[
            'flex flex-col items-center gap-1 rounded-xl py-2',
            'transition-[background-color,color] duration-150 ease-out',
            estActif ? 'bg-primarySoft text-primary' : 'text-muted hover:text-ink'].
            join(' ')}>
            
            <Icone size={20} />
            <span className="text-2xs font-semibold">{i.label}</span>
          </button>);

      })}
    </nav>);

}