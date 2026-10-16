import React, { ReactNode } from 'react';

interface FieldProps {
  label: string;
  children: ReactNode;
  aide?: string;
  erreur?: string;
  htmlFor?: string;
}

export function Field({ label, children, aide, erreur, htmlFor }: FieldProps) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={htmlFor} className="block text-[13px] font-semibold text-ink">
        {label}
      </label>
      {children}
      {erreur ?
      <p className="text-2xs font-medium text-danger">{erreur}</p> :
      aide ?
      <p className="text-2xs text-muted">{aide}</p> :
      null}
    </div>);

}

export const inputClass =
'w-full h-12 rounded-xl bg-surface2 border border-line px-3.5 text-[15px] text-ink placeholder:text-muted/70 ' +
'transition-[border-color,box-shadow] duration-150 ease-out ' +
'focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20';

export const textareaClass =
'w-full min-h-[88px] rounded-xl bg-surface2 border border-line px-3.5 py-2.5 text-[15px] text-ink placeholder:text-muted/70 ' +
'transition-[border-color,box-shadow] duration-150 ease-out resize-none ' +
'focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20';