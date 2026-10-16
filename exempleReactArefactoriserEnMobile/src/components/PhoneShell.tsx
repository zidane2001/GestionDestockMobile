import React, { ReactNode } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import {
  CheckCircle2Icon,
  CloudOffIcon,
  CloudIcon,
  InfoIcon,
  MoonIcon,
  StoreIcon,
  SunIcon,
  TriangleAlertIcon,
  WifiIcon } from
'lucide-react';
import { useApp } from '../contexts/AppContext';
import { LogoBoutique } from './LogoBoutique';
import { ROLE_LABEL } from '../utils/format';

const TONS = {
  succes: { icone: CheckCircle2Icon, classe: 'border-success/30 bg-success/10 text-success' },
  erreur: { icone: TriangleAlertIcon, classe: 'border-danger/30 bg-danger/10 text-danger' },
  info: { icone: InfoIcon, classe: 'border-line bg-surface2 text-ink' }
} as const;

export function PhoneShell({ children }: {children: ReactNode;}) {
  const { theme, basculerTheme, enLigne, basculerReseau, enAttenteSync, session, boutique, toasts } =
  useApp();

  return (
    <div className={theme === 'sombre' ? 'dark' : undefined}>
      <div className="flex min-h-screen w-full bg-canvas">
        <aside className="hidden w-[320px] shrink-0 flex-col border-r border-line bg-surface px-7 py-8 lg:flex">
          <div className="flex items-center gap-2.5">
            <div className="grid h-9 w-9 place-items-center rounded-xl bg-primary text-onPrimary">
              <StoreIcon size={18} />
            </div>
            <div>
              <p className="text-[15px] font-bold leading-tight text-ink">Ma Boutique</p>
              <p className="text-2xs text-muted">Maquette interactive · v1.0</p>
            </div>
          </div>

          <p className="mt-7 text-[13px] leading-relaxed text-muted">
            Gestion de stock, caisse et équipe pour une petite boutique. Trois rôles, une base
            partagée, fonctionnement hors-ligne.
          </p>

          <dl className="mt-7 space-y-3 border-t border-line pt-6 text-[13px]">
            <div className="flex items-center justify-between gap-3">
              <dt className="text-muted">Boutique</dt>
              <dd className="flex items-center gap-2 font-semibold text-ink">
                <LogoBoutique logoUrl={boutique?.logoUrl} nom={boutique?.nom} taille={22} />
                {boutique?.nom ?? '—'}
              </dd>
            </div>
            <div className="flex justify-between gap-3">
              <dt className="text-muted">Session</dt>
              <dd className="font-semibold text-ink">
                {session ? ROLE_LABEL[session.role] : 'Déconnecté'}
              </dd>
            </div>
            <div className="flex justify-between gap-3">
              <dt className="text-muted">Monnaie</dt>
              <dd className="font-semibold text-ink">{boutique?.monnaie ?? 'FCFA'}</dd>
            </div>
          </dl>

          <div className="mt-7 space-y-2 border-t border-line pt-6">
            <button
              type="button"
              onClick={basculerReseau}
              className="flex w-full items-center justify-between rounded-xl bg-surface2 px-3.5 py-3 text-[13px] font-semibold text-ink transition-colors duration-150 ease-out hover:bg-line/60">
              
              <span className="flex items-center gap-2">
                {enLigne ? <CloudIcon size={16} /> : <CloudOffIcon size={16} />}
                {enLigne ? 'En ligne' : 'Hors-ligne'}
              </span>
              <span className="text-2xs font-medium text-muted">
                {enLigne ? 'simuler une coupure' : `${enAttenteSync} en attente`}
              </span>
            </button>
            <button
              type="button"
              onClick={basculerTheme}
              className="flex w-full items-center justify-between rounded-xl bg-surface2 px-3.5 py-3 text-[13px] font-semibold text-ink transition-colors duration-150 ease-out hover:bg-line/60">
              
              <span className="flex items-center gap-2">
                {theme === 'clair' ? <SunIcon size={16} /> : <MoonIcon size={16} />}
                Thème {theme}
              </span>
              <span className="text-2xs font-medium text-muted">basculer</span>
            </button>
          </div>

          <div className="mt-auto rounded-xl border border-line p-4 text-2xs leading-relaxed text-muted">
            <p className="mb-1 font-semibold text-ink">Comptes de démonstration</p>
            Boutique <span className="font-semibold text-ink">Boutique Kadi</span>
            <br />
            Patron · patron123
            <br />
            Manager · manager123
            <br />
            Caissière · caisse123
            <br />
            Code PIN · 1234
          </div>
        </aside>

        <main className="flex flex-1 items-center justify-center px-0 py-0 sm:px-6 sm:py-10">
          <div className="relative w-full max-w-[400px] sm:w-[400px]">
            <div className="relative h-[100svh] w-full overflow-hidden bg-canvas sm:h-[840px] sm:rounded-[42px] sm:border-[9px] sm:border-[#0c1016] sm:shadow-2xl">
              <div className="flex h-6 items-center justify-between bg-canvas px-6 pt-2 text-2xs font-semibold text-ink tnum">
                <span>
                  {new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
                </span>
                <span className="flex items-center gap-1.5">
                  {!enLigne &&
                  <span className="flex items-center gap-1 text-accent">
                      <CloudOffIcon size={11} /> hors-ligne
                    </span>
                  }
                  <WifiIcon size={12} />
                  <span className="inline-block h-2.5 w-5 rounded-[3px] border border-ink/60">
                    <span className="block h-full w-3/4 rounded-[2px] bg-ink/70" />
                  </span>
                </span>
              </div>

              <div className="relative h-[calc(100%-24px)] overflow-hidden">{children}</div>

              <div className="pointer-events-none absolute bottom-1.5 left-1/2 hidden h-1 w-32 -translate-x-1/2 rounded-full bg-ink/25 sm:block" />

              <div className="pointer-events-none absolute inset-x-0 top-8 z-50 flex flex-col items-center gap-2 px-4">
                <AnimatePresence>
                  {toasts.map((t) => {
                    const { icone: Icone, classe } = TONS[t.ton];
                    return (
                      <motion.div
                        key={t.id}
                        initial={{ opacity: 0, y: -12, scale: 0.97 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: -8, scale: 0.98 }}
                        transition={{ duration: 0.22, ease: [0.23, 1, 0.32, 1] }}
                        className={`flex w-full items-start gap-2 rounded-xl border px-3 py-2.5 text-[13px] font-semibold shadow-lg backdrop-blur ${classe}`}>
                        
                        <Icone size={16} className="mt-0.5 shrink-0" />
                        <span>{t.message}</span>
                      </motion.div>);

                  })}
                </AnimatePresence>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>);

}