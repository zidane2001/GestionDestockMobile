import React, { ReactNode } from 'react';

export function EmptyState({
  icone,
  titre,
  texte,
  action





}: {icone: ReactNode;titre: string;texte: string;action?: ReactNode;}) {
  return (
    <div className="flex flex-col items-center justify-center px-8 py-14 text-center">
      <div className="mb-3 grid h-12 w-12 place-items-center rounded-2xl bg-surface2 text-muted">
        {icone}
      </div>
      <h3 className="text-[15px] font-bold text-ink">{titre}</h3>
      <p className="mt-1 max-w-[26ch] text-[13px] leading-relaxed text-muted">{texte}</p>
      {action && <div className="mt-4">{action}</div>}
    </div>);

}