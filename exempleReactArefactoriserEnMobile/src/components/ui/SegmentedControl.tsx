import React from 'react';

interface Option<T extends string> {
  valeur: T;
  label: string;
}

interface Props<T extends string> {
  options: Option<T>[];
  valeur: T;
  onChange: (v: T) => void;
  ariaLabel: string;
}

export function SegmentedControl<T extends string>({
  options,
  valeur,
  onChange,
  ariaLabel
}: Props<T>) {
  return (
    <div
      role="tablist"
      aria-label={ariaLabel}
      className="inline-flex rounded-xl bg-surface2 p-0.5 border border-line">
      
      {options.map((o) => {
        const actif = o.valeur === valeur;
        return (
          <button
            key={o.valeur}
            role="tab"
            aria-selected={actif}
            type="button"
            onClick={() => onChange(o.valeur)}
            className={[
            'rounded-[10px] px-3 py-1.5 text-[13px] font-semibold',
            'transition-[background-color,color] duration-150 ease-out',
            actif ? 'bg-surface text-ink shadow-sm' : 'text-muted hover:text-ink'].
            join(' ')}>
            
            {o.label}
          </button>);

      })}
    </div>);

}