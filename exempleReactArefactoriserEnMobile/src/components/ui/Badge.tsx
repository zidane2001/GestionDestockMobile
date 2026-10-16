import React, { ReactNode } from 'react';

type Ton = 'neutre' | 'primaire' | 'succes' | 'danger' | 'accent';

const TONS: Record<Ton, string> = {
  neutre: 'bg-surface2 text-muted border-line',
  primaire: 'bg-primarySoft text-primary border-primary/25',
  succes: 'bg-success/10 text-success border-success/25',
  danger: 'bg-danger/10 text-danger border-danger/25',
  accent: 'bg-accent/10 text-accent border-accent/25'
};

export function Badge({
  children,
  ton = 'neutre',
  className = ''




}: {children: ReactNode;ton?: Ton;className?: string;}) {
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-2xs font-semibold ${TONS[ton]} ${className}`}>
      
      {children}
    </span>);

}