import React, { ReactNode } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { ChevronLeftIcon } from 'lucide-react';

interface Props {
  titre: string;
  sousTitre?: string;
  action?: ReactNode;
  children: ReactNode;
}

export function SubScreen({ titre, sousTitre, action, children }: Props) {
  const navigate = useNavigate();
  return (
    <motion.section
      initial={{ opacity: 0, x: 24 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.22, ease: [0.23, 1, 0.32, 1] }}
      className="flex h-full flex-col bg-canvas">
      
      <header className="flex items-center gap-3 border-b border-line bg-surface px-4 py-3">
        <button
          type="button"
          onClick={() => navigate(-1)}
          aria-label="Retour"
          className="grid h-9 w-9 place-items-center rounded-full bg-surface2 text-ink transition-colors duration-150 ease-out hover:bg-line/60">
          
          <ChevronLeftIcon size={20} />
        </button>
        <div className="min-w-0 flex-1">
          <h1 className="truncate text-[16px] font-bold text-ink">{titre}</h1>
          {sousTitre && <p className="truncate text-2xs text-muted">{sousTitre}</p>}
        </div>
        {action}
      </header>
      <div className="flex-1 overflow-y-auto no-scrollbar">{children}</div>
    </motion.section>);

}