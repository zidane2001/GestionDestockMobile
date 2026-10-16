import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { BriefcaseIcon, ChevronLeftIcon, CrownIcon, ScanFaceIcon, WalletIcon } from 'lucide-react';
import { useApp } from '../contexts/AppContext';
import { Button } from '../components/ui/Button';
import { Field, inputClass } from '../components/ui/Field';
import { Role } from '../types';

const ROLES: {valeur: Role;label: string;icone: typeof CrownIcon;description: string;}[] = [
{ valeur: 'patron', label: 'Patron', icone: CrownIcon, description: 'Accès complet' },
{ valeur: 'manager', label: 'Manager', icone: BriefcaseIcon, description: 'Ventes & dépenses' },
{ valeur: 'caissiere', label: 'Caissière', icone: WalletIcon, description: 'Caisse & ventes' }];


export function Connexion() {
  const navigate = useNavigate();
  const { connexion, session } = useApp();
  const [nom, setNom] = useState('Boutique Kadi');
  const [role, setRole] = useState<Role>('patron');
  const [mdp, setMdp] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);

  const soumettre = (e: React.FormEvent) => {
    e.preventDefault();
    const message = connexion(nom, role, mdp);
    if (message) {
      setErreur(message);
      return;
    }
    navigate('/app', { replace: true });
  };

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.24, ease: [0.23, 1, 0.32, 1] }}
      className="flex h-full flex-col bg-canvas">
      
      <header className="flex items-center gap-3 px-4 py-3">
        <button
          type="button"
          onClick={() => navigate('/')}
          aria-label="Retour"
          className="grid h-9 w-9 place-items-center rounded-full bg-surface2 text-ink transition-colors duration-150 ease-out hover:bg-line/60">
          
          <ChevronLeftIcon size={20} />
        </button>
        <h1 className="text-[16px] font-bold text-ink">Se connecter</h1>
      </header>

      <form onSubmit={soumettre} className="flex-1 space-y-5 overflow-y-auto no-scrollbar px-5 pb-8">
        <Field label="Nom de la boutique" htmlFor="boutique">
          <input
            id="boutique"
            className={inputClass}
            value={nom}
            onChange={(e) => {
              setNom(e.target.value);
              setErreur(null);
            }}
            placeholder="Nom exact de la boutique"
            autoComplete="off" />
          
        </Field>

        <Field label="Je me connecte en tant que">
          <div className="space-y-2">
            {ROLES.map((r) => {
              const Icone = r.icone;
              const actif = role === r.valeur;
              return (
                <button
                  key={r.valeur}
                  type="button"
                  onClick={() => {
                    setRole(r.valeur);
                    setErreur(null);
                  }}
                  aria-pressed={actif}
                  className={[
                  'flex w-full items-center gap-3 rounded-xl border px-3.5 py-3 text-left',
                  'transition-[background-color,border-color] duration-150 ease-out',
                  actif ? 'border-primary bg-primarySoft' : 'border-line bg-surface2 hover:bg-line/50'].
                  join(' ')}>
                  
                  <span
                    className={`grid h-9 w-9 place-items-center rounded-lg ${
                    actif ? 'bg-primary text-onPrimary' : 'bg-surface text-muted'}`
                    }>
                    
                    <Icone size={17} />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className={`block text-[14px] font-semibold ${actif ? 'text-primary' : 'text-ink'}`}>
                      {r.label}
                    </span>
                    <span className="block text-2xs text-muted">{r.description}</span>
                  </span>
                  <span
                    className={`h-4 w-4 rounded-full border-2 ${
                    actif ? 'border-primary bg-primary' : 'border-line'}`
                    } />
                  
                </button>);

            })}
          </div>
        </Field>

        <Field label="Mot de passe" erreur={erreur ?? undefined} htmlFor="mdp-connexion">
          <input
            id="mdp-connexion"
            type="password"
            className={inputClass}
            value={mdp}
            onChange={(e) => {
              setMdp(e.target.value);
              setErreur(null);
            }}
            placeholder="••••••" />
          
        </Field>

        <Button type="submit" taille="lg" pleineLargeur>
          Se connecter
        </Button>

        {session?.biometrie &&
        <button
          type="button"
          className="mx-auto flex items-center gap-2 text-[13px] font-semibold text-primary">
          
            <ScanFaceIcon size={16} /> Utiliser la biométrie
          </button>
        }

        <p className="text-center text-2xs leading-relaxed text-muted">
          Mot de passe oublié ? Le patron peut le réinitialiser depuis les paramètres, ou par email
          pour son propre compte.
        </p>
      </form>
    </motion.div>);

}