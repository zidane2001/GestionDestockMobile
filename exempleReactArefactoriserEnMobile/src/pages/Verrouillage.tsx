import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { DeleteIcon, FingerprintIcon } from 'lucide-react';
import { useApp } from '../contexts/AppContext';
import { LogoBoutique } from '../components/LogoBoutique';
import { ROLE_LABEL } from '../utils/format';

const TOUCHES = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'bio', '0', 'suppr'];

export function Verrouillage() {
  const { session, deverrouiller, boutique, notifier, deconnexion } = useApp();
  const [pin, setPin] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);
  const [essais, setEssais] = useState(0);
  const [attente, setAttente] = useState(0);

  useEffect(() => {
    if (attente <= 0) return;
    const t = window.setInterval(() => setAttente((s) => s - 1), 1000);
    return () => window.clearInterval(t);
  }, [attente]);

  useEffect(() => {
    if (pin.length !== 4) return;
    if (deverrouiller(pin)) {
      setErreur(null);
      return;
    }
    const n = essais + 1;
    setEssais(n);
    setPin('');
    if (n >= 5) {
      setAttente(30);
      setEssais(0);
      setErreur('5 essais incorrects. Patientez 30 secondes.');
    } else {
      setErreur(`Code incorrect. ${5 - n} essai${5 - n > 1 ? 's' : ''} restant${5 - n > 1 ? 's' : ''}.`);
    }
  }, [pin, deverrouiller, essais]);

  const appuyer = (t: string) => {
    if (attente > 0) return;
    if (t === 'suppr') {
      setPin((p) => p.slice(0, -1));
      return;
    }
    if (t === 'bio') {
      if (session?.biometrie) {
        if (session.pin) deverrouiller(session.pin);
      } else {
        notifier('Biométrie non activée sur ce compte.', 'info');
      }
      return;
    }
    setPin((p) => p.length < 4 ? p + t : p);
  };

  return (
    <div className="flex h-full flex-col items-center justify-between bg-canvas px-6 pb-8 pt-12">
      <div className="flex flex-col items-center">
        <LogoBoutique logoUrl={boutique?.logoUrl} nom={boutique?.nom} taille={56} />
        <h1 className="mt-4 text-[19px] font-bold text-ink">{boutique?.nom}</h1>
        <p className="mt-1 text-[13px] text-muted">
          {session ? `${ROLE_LABEL[session.role]} · ${session.nom}` : ''}
        </p>

        <div className="mt-8 flex gap-3.5" role="status" aria-label={`${pin.length} chiffres saisis`}>
          {[0, 1, 2, 3].map((i) =>
          <motion.span
            key={i}
            animate={{ scale: pin.length === i + 1 ? 1.15 : 1 }}
            transition={{ duration: 0.14, ease: 'easeOut' }}
            className={`h-3.5 w-3.5 rounded-full border-2 ${
            i < pin.length ? 'border-primary bg-primary' : 'border-line bg-transparent'}`
            } />

          )}
        </div>
        <p className="mt-4 h-8 text-center text-[13px] font-medium text-danger">
          {attente > 0 ? `Nouvelle tentative dans ${attente} s` : erreur}
        </p>
      </div>

      <div className="w-full max-w-[280px]">
        <div className="grid grid-cols-3 gap-3">
          {TOUCHES.map((t) => {
            if (t === 'bio')
            return (
              <button
                key={t}
                type="button"
                onClick={() => appuyer(t)}
                aria-label="Déverrouiller par biométrie"
                className="grid h-16 place-items-center rounded-2xl text-primary transition-colors duration-150 ease-out hover:bg-surface2">
                
                  <FingerprintIcon size={24} />
                </button>);

            if (t === 'suppr')
            return (
              <button
                key={t}
                type="button"
                onClick={() => appuyer(t)}
                aria-label="Effacer"
                className="grid h-16 place-items-center rounded-2xl text-muted transition-colors duration-150 ease-out hover:bg-surface2">
                
                  <DeleteIcon size={22} />
                </button>);

            return (
              <button
                key={t}
                type="button"
                onClick={() => appuyer(t)}
                disabled={attente > 0}
                className="grid h-16 place-items-center rounded-2xl bg-surface text-[22px] font-semibold text-ink shadow-sm transition-[background-color,transform] duration-150 ease-out hover:bg-surface2 active:scale-95 disabled:opacity-40 tnum">
                
                {t}
              </button>);

          })}
        </div>

        <div className="mt-5 flex justify-center gap-5 text-[13px] font-semibold">
          <button
            type="button"
            onClick={() => notifier("Un code de vérification a été envoyé à l'email du patron.", 'info')}
            className="text-primary">
            
            PIN oublié ?
          </button>
          <button type="button" onClick={deconnexion} className="text-muted">
            Changer de compte
          </button>
        </div>
      </div>
    </div>);

}