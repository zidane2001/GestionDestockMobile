import React, { ButtonHTMLAttributes, ReactNode } from 'react';

type Variante = 'primaire' | 'secondaire' | 'fantome' | 'danger';
type Taille = 'sm' | 'md' | 'lg';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variante?: Variante;
  taille?: Taille;
  pleineLargeur?: boolean;
  children: ReactNode;
}

const VARIANTES: Record<Variante, string> = {
  primaire: 'bg-primary text-onPrimary hover:bg-primary/90 active:scale-[0.985]',
  secondaire:
  'bg-surface2 text-ink border border-line hover:bg-line/60 active:scale-[0.985]',
  fantome: 'text-ink hover:bg-surface2 active:scale-[0.985]',
  danger: 'bg-danger text-white hover:bg-danger/90 active:scale-[0.985]'
};

const TAILLES: Record<Taille, string> = {
  sm: 'h-9 px-3 text-[13px] rounded-xl gap-1.5',
  md: 'h-11 px-4 text-sm rounded-xl gap-2',
  lg: 'h-14 px-5 text-[15px] rounded-2xl gap-2'
};

export function Button({
  variante = 'primaire',
  taille = 'md',
  pleineLargeur,
  className = '',
  children,
  ...props
}: ButtonProps) {
  return (
    <button
      {...props}
      className={[
      'inline-flex items-center justify-center font-semibold',
      'transition-[background-color,transform,color,border-color] duration-150 ease-out',
      'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2 focus-visible:ring-offset-surface',
      'disabled:opacity-45 disabled:pointer-events-none',
      VARIANTES[variante],
      TAILLES[taille],
      pleineLargeur ? 'w-full' : '',
      className].
      join(' ')}>
      
      {children}
    </button>);

}