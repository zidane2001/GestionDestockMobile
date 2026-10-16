import React, { ReactNode } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { XIcon } from 'lucide-react';

interface SheetProps {
  ouvert: boolean;
  onFermer: () => void;
  titre: string;
  sousTitre?: string;
  children: ReactNode;
}

const EASE = [0.23, 1, 0.32, 1] as const;

export function Sheet({ ouvert, onFermer, titre, sousTitre, children }: SheetProps) {
  return (
    <AnimatePresence>
      {ouvert &&
      <div className="absolute inset-0 z-40 flex flex-col justify-end">
          <motion.button
          type="button"
          aria-label="Fermer"
          onClick={onFermer}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2, ease: 'easeOut' }}
          className="absolute inset-0 bg-black/45" />
        
          <motion.div
          role="dialog"
          aria-modal="true"
          aria-label={titre}
          initial={{ y: '100%' }}
          animate={{ y: 0 }}
          exit={{ y: '100%' }}
          transition={{ duration: 0.28, ease: EASE }}
          className="relative max-h-[86%] overflow-y-auto no-scrollbar rounded-t-3xl bg-surface border-t border-line pb-6">
          
            <div className="sticky top-0 z-10 bg-surface px-5 pt-3 pb-3 border-b border-line">
              <div className="mx-auto mb-3 h-1 w-10 rounded-full bg-line" />
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="text-[17px] font-bold text-ink">{titre}</h2>
                  {sousTitre && <p className="mt-0.5 text-[13px] text-muted">{sousTitre}</p>}
                </div>
                <button
                type="button"
                onClick={onFermer}
                aria-label="Fermer"
                className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-surface2 text-muted transition-colors duration-150 ease-out hover:text-ink">
                
                  <XIcon size={18} />
                </button>
              </div>
            </div>
            <div className="px-5 pt-4">{children}</div>
          </motion.div>
        </div>
      }
    </AnimatePresence>);

}