import React, { useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ChevronLeftIcon, ImagePlusIcon } from 'lucide-react';
import { useApp } from '../contexts/AppContext';
import { Button } from '../components/ui/Button';
import { Field, inputClass } from '../components/ui/Field';
import { LogoBoutique } from '../components/LogoBoutique';
import { Boutique } from '../types';

const MONNAIES: {valeur: Boutique['monnaie'];label: string;}[] = [
{ valeur: 'FCFA', label: 'Franc CFA' },
{ valeur: 'EUR', label: 'Euro' },
{ valeur: 'USD', label: 'Dollar US' }];


export function CreerBoutique() {
  const navigate = useNavigate();
  const { creerBoutique, boutique } = useApp();
  const [nom, setNom] = useState('');
  const [style, setStyle] = useState('');
  const [monnaie, setMonnaie] = useState<Boutique['monnaie']>('FCFA');
  const [email, setEmail] = useState('');
  const [mdp, setMdp] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [logo, setLogo] = useState<string | null>(null);
  const [erreurs, setErreurs] = useState<Record<string, string>>({});
  const champFichier = useRef<HTMLInputElement>(null);

  const choisirLogo = (fichier: File | undefined) => {
    if (!fichier) return;
    if (!fichier.type.startsWith('image/')) {
      setErreurs((e) => ({ ...e, logo: 'Choisissez une image (PNG ou JPG).' }));
      return;
    }
    if (fichier.size > 2_000_000) {
      setErreurs((e) => ({ ...e, logo: 'Image trop lourde (2 Mo maximum).' }));
      return;
    }
    const lecteur = new FileReader();
    lecteur.onload = () => {
      setLogo(String(lecteur.result));
      setErreurs((e) => ({ ...e, logo: '' }));
    };
    lecteur.readAsDataURL(fichier);
  };

  const valider = (e: React.FormEvent) => {
    e.preventDefault();
    const err: Record<string, string> = {};
    if (nom.trim().length < 3 || nom.trim().length > 40)
    err.nom = 'Le nom doit contenir entre 3 et 40 caractères.';
    if (boutique && boutique.nom.toLowerCase() === nom.trim().toLowerCase())
    err.nom = 'Ce nom de boutique existe déjà.';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) err.email = 'Adresse email invalide.';
    if (mdp.length < 6) err.mdp = 'Minimum 6 caractères.';
    if (mdp !== confirmation) err.confirmation = 'Les mots de passe ne correspondent pas.';
    setErreurs(err);
    if (Object.keys(err).length > 0) return;
    creerBoutique({
      nom: nom.trim(),
      styleCommerce: style.trim(),
      monnaie,
      emailPatron: email.trim(),
      motDePasse: mdp,
      logoUrl: logo
    });
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
        <h1 className="text-[16px] font-bold text-ink">Créer ma boutique</h1>
      </header>

      <form onSubmit={valider} className="flex-1 space-y-4 overflow-y-auto no-scrollbar px-5 pb-8">
        <p className="text-[13px] leading-relaxed text-muted">
          Le nom de la boutique servira d'identifiant de connexion à toute l'équipe. Votre compte
          patron est créé automatiquement.
        </p>

        <Field label="Nom de la boutique" erreur={erreurs.nom} aide="3 à 40 caractères, unique" htmlFor="nom">
          <input
            id="nom"
            className={inputClass}
            value={nom}
            onChange={(e) => setNom(e.target.value)}
            placeholder="Ex. Boutique Kadi"
            autoComplete="off" />
          
        </Field>

        <Field label="Style de commerce (facultatif)" htmlFor="style">
          <input
            id="style"
            className={inputClass}
            value={style}
            onChange={(e) => setStyle(e.target.value)}
            placeholder="Vêtements, électronique, alimentation…" />
          
        </Field>

        <Field
          label="Logo de la boutique (facultatif)"
          erreur={erreurs.logo || undefined}
          aide="Affiché en haut de l'application sur tous les téléphones">
          
          <div className="flex items-center gap-3 rounded-xl border border-line bg-surface2 p-3">
            <LogoBoutique logoUrl={logo} nom={nom} taille={56} />
            <div className="min-w-0 flex-1">
              <input
                ref={champFichier}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => choisirLogo(e.target.files?.[0])} />
              
              <div className="flex flex-wrap gap-2">
                <Button
                  type="button"
                  taille="sm"
                  variante="secondaire"
                  onClick={() => champFichier.current?.click()}>
                  
                  <ImagePlusIcon size={15} /> {logo ? 'Changer' : 'Choisir une image'}
                </Button>
                {logo &&
                <Button type="button" taille="sm" variante="fantome" onClick={() => setLogo(null)}>
                    Retirer
                  </Button>
                }
              </div>
              <p className="mt-1.5 text-2xs text-muted">PNG ou JPG carré, 2 Mo maximum.</p>
            </div>
          </div>
        </Field>

        <Field label="Monnaie">
          <div className="grid grid-cols-3 gap-2">
            {MONNAIES.map((m) =>
            <button
              key={m.valeur}
              type="button"
              onClick={() => setMonnaie(m.valeur)}
              aria-pressed={monnaie === m.valeur}
              className={[
              'h-12 rounded-xl border text-[13px] font-semibold',
              'transition-[background-color,border-color,color] duration-150 ease-out',
              monnaie === m.valeur ?
              'border-primary bg-primarySoft text-primary' :
              'border-line bg-surface2 text-muted hover:text-ink'].
              join(' ')}>
              
                {m.label}
              </button>
            )}
          </div>
        </Field>

        <Field
          label="Email du patron"
          erreur={erreurs.email}
          aide="Utilisé pour récupérer un compte ou un code PIN"
          htmlFor="email">
          
          <input
            id="email"
            type="email"
            className={inputClass}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="vous@exemple.com" />
          
        </Field>

        <Field label="Mot de passe" erreur={erreurs.mdp} aide="Minimum 6 caractères" htmlFor="mdp">
          <input
            id="mdp"
            type="password"
            className={inputClass}
            value={mdp}
            onChange={(e) => setMdp(e.target.value)}
            placeholder="••••••" />
          
        </Field>

        <Field label="Confirmer le mot de passe" erreur={erreurs.confirmation} htmlFor="confirmation">
          <input
            id="confirmation"
            type="password"
            className={inputClass}
            value={confirmation}
            onChange={(e) => setConfirmation(e.target.value)}
            placeholder="••••••" />
          
        </Field>

        <Button type="submit" taille="lg" pleineLargeur className="mt-2">
          Créer la boutique
        </Button>
      </form>
    </motion.div>);

}