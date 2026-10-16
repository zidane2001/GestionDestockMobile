import React from 'react';
import { useNavigate } from 'react-router-dom';
import { BellIcon, SettingsIcon } from 'lucide-react';
import { useApp } from '../contexts/AppContext';
import { LogoBoutique } from './LogoBoutique';
import { ROLE_LABEL } from '../utils/format';

export function AppHeader() {
  const navigate = useNavigate();
  const { boutique, session, notificationsRole, enLigne, enAttenteSync } = useApp();
  const nonLues = notificationsRole.filter((n) => !n.estLu).length;

  return (
    <header className="flex items-center gap-3 border-b border-line bg-surface px-4 py-3">
      <LogoBoutique logoUrl={boutique?.logoUrl} nom={boutique?.nom} taille={40} />
      <div className="min-w-0 flex-1">
        <h1 className="truncate text-[15px] font-bold leading-tight text-ink">{boutique?.nom}</h1>
        <p className="truncate text-2xs text-muted">
          {session ? `${ROLE_LABEL[session.role]} · ${session.nom}` : ''}
          {!enLigne && ` · ${enAttenteSync} en attente de synchro`}
        </p>
      </div>

      <button
        type="button"
        onClick={() => navigate('/notifications')}
        aria-label={`Notifications${nonLues > 0 ? `, ${nonLues} non lues` : ''}`}
        className="relative grid h-10 w-10 place-items-center rounded-full bg-surface2 text-ink transition-colors duration-150 ease-out hover:bg-line/60">
        
        <BellIcon size={18} />
        {nonLues > 0 &&
        <span className="absolute -right-0.5 -top-0.5 grid h-[18px] min-w-[18px] place-items-center rounded-full bg-danger px-1 text-[10px] font-bold text-white tnum">
            {nonLues}
          </span>
        }
      </button>
      <button
        type="button"
        onClick={() => navigate('/parametres')}
        aria-label="Paramètres"
        className="grid h-10 w-10 place-items-center rounded-full bg-surface2 text-ink transition-colors duration-150 ease-out hover:bg-line/60">
        
        <SettingsIcon size={18} />
      </button>
    </header>);

}