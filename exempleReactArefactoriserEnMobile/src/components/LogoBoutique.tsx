import React from 'react';
import { StoreIcon } from 'lucide-react';

interface Props {
  logoUrl?: string | null;
  nom?: string;
  taille?: number;
  className?: string;
}

/** Logo de la boutique, avec repli sur une icône si aucun logo n'a été fourni. */
export function LogoBoutique({ logoUrl, nom, taille = 40, className = '' }: Props) {
  const style = { width: taille, height: taille };

  if (logoUrl) {
    return (
      <img
        src={logoUrl}
        alt={nom ? `Logo de ${nom}` : 'Logo de la boutique'}
        style={style}
        className={`shrink-0 rounded-xl border border-line object-cover ${className}`} />);


  }

  return (
    <span
      style={style}
      aria-hidden="true"
      className={`grid shrink-0 place-items-center rounded-xl bg-primary text-onPrimary ${className}`}>
      
      <StoreIcon size={Math.round(taille * 0.48)} />
    </span>);

}