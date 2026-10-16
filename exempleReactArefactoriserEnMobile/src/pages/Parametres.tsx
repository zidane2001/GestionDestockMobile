import React, { useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ChevronRightIcon,
  FingerprintIcon,
  ImagePlusIcon,
  KeyRoundIcon,
  LogOutIcon,
  MoonIcon,
  SmartphoneIcon,
  SunIcon,
  UsersIcon } from
'lucide-react';
import { useApp } from '../contexts/AppContext';
import { SubScreen } from '../components/SubScreen';
import { LogoBoutique } from '../components/LogoBoutique';
import { Button } from '../components/ui/Button';
import { Field, inputClass } from '../components/ui/Field';
import { peut } from '../utils/permissions';
import { ROLE_LABEL } from '../utils/format';

function Switch({
  actif,
  onChange,
  label




}: {actif: boolean;onChange: () => void;label: string;}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={actif}
      aria-label={label}
      onClick={onChange}
      className={`relative h-6 w-11 shrink-0 rounded-full transition-colors duration-150 ease-out ${
      actif ? 'bg-primary' : 'bg-line'}`
      }>
      
      <span
        className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-[left] duration-150 ease-out ${
        actif ? 'left-[22px]' : 'left-0.5'}`
        } />
      
    </button>);

}

export function Parametres() {
  const navigate = useNavigate();
  const {
    session,
    boutique,
    theme,
    basculerTheme,
    definirPin,
    definirLogo,
    basculerBiometrie,
    deconnexion,
    notifier
  } = useApp();
  const [editionPin, setEditionPin] = useState(false);
  const [pin, setPin] = useState('');
  const [erreur, setErreur] = useState<string | null>(null);
  const champLogo = useRef<HTMLInputElement>(null);

  const changerLogo = (fichier: File | undefined) => {
    if (!fichier) return;
    if (!fichier.type.startsWith('image/') || fichier.size > 2_000_000) {
      notifier('Choisissez une image de 2 Mo maximum.', 'erreur');
      return;
    }
    const lecteur = new FileReader();
    lecteur.onload = () => definirLogo(String(lecteur.result));
    lecteur.readAsDataURL(fichier);
  };

  const enregistrerPin = () => {
    if (!/^\d{4}$/.test(pin)) {
      setErreur('Le code PIN doit contenir exactement 4 chiffres.');
      return;
    }
    definirPin(pin);
    setPin('');
    setEditionPin(false);
    setErreur(null);
    if (!session?.biometrie) notifier('Activez la biométrie pour déverrouiller plus vite.', 'info');
  };

  const liens = [
  {
    cle: 'employes',
    label: 'Gestion des comptes employés',
    description: 'Créer, suspendre, supprimer',
    icone: UsersIcon,
    visible: peut(session, 'gererComptes'),
    onClick: () => navigate('/parametres/employes')
  },
  {
    cle: 'appareils',
    label: 'Appareils connectés',
    description: 'Voir et révoquer les téléphones',
    icone: SmartphoneIcon,
    visible: peut(session, 'appareils'),
    onClick: () => navigate('/parametres/appareils')
  },
  {
    cle: 'mdp',
    label: 'Modifier mon mot de passe',
    description: `Récupération via ${boutique?.emailPatron ?? 'email du patron'}`,
    icone: KeyRoundIcon,
    visible: session?.role === 'patron',
    onClick: () => notifier('Un lien de modification a été envoyé par email.', 'info')
  }].
  filter((l) => l.visible);

  return (
    <SubScreen titre="Paramètres" sousTitre={session ? `${ROLE_LABEL[session.role]} · ${session.nom}` : ''}>
      <div className="space-y-4 px-4 py-4">
        {session?.role === 'patron' &&
        <section className="flex items-center gap-3 rounded-2xl border border-line bg-surface px-4 py-3.5">
            <LogoBoutique logoUrl={boutique?.logoUrl} nom={boutique?.nom} taille={52} />
            <div className="min-w-0 flex-1">
              <p className="truncate text-[14px] font-semibold text-ink">{boutique?.nom}</p>
              <p className="truncate text-2xs text-muted">
                {boutique?.logoUrl ? 'Logo affiché sur tous les téléphones' : 'Aucun logo'}
              </p>
              <input
              ref={champLogo}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => changerLogo(e.target.files?.[0])} />
            
              <div className="mt-2 flex gap-2">
                <Button taille="sm" variante="secondaire" onClick={() => champLogo.current?.click()}>
                  <ImagePlusIcon size={15} /> {boutique?.logoUrl ? 'Changer le logo' : 'Ajouter un logo'}
                </Button>
                {boutique?.logoUrl &&
              <Button taille="sm" variante="fantome" onClick={() => definirLogo(null)}>
                    Retirer
                  </Button>
              }
              </div>
            </div>
          </section>
        }

        <section className="rounded-2xl border border-line bg-surface">
          <div className="flex items-center gap-3 px-4 py-3.5">
            <KeyRoundIcon size={18} className="text-primary" />
            <div className="min-w-0 flex-1">
              <p className="text-[14px] font-semibold text-ink">Code PIN à 4 chiffres</p>
              <p className="text-2xs text-muted">
                {session?.pinActif ? 'Demandé à chaque ouverture' : 'Désactivé'}
              </p>
            </div>
            <Switch
              label="Activer le code PIN"
              actif={!!session?.pinActif}
              onChange={() => {
                if (session?.pinActif) definirPin(null);else
                setEditionPin(true);
              }} />
            
          </div>

          {(editionPin || session?.pinActif) &&
          <div className="border-t border-line px-4 py-3.5">
              {editionPin ?
            <div className="space-y-3">
                  <Field label="Nouveau code PIN" erreur={erreur ?? undefined}>
                    <input
                  className={`${inputClass} text-center text-[20px] font-bold tracking-[0.4em] tnum`}
                  value={pin}
                  inputMode="numeric"
                  maxLength={4}
                  onChange={(e) => {
                    setPin(e.target.value.replace(/\D/g, ''));
                    setErreur(null);
                  }}
                  placeholder="••••" />
                
                  </Field>
                  <div className="flex gap-2">
                    <Button taille="sm" onClick={enregistrerPin}>
                      Enregistrer
                    </Button>
                    <Button taille="sm" variante="fantome" onClick={() => setEditionPin(false)}>
                      Annuler
                    </Button>
                  </div>
                </div> :

            <button
              type="button"
              onClick={() => setEditionPin(true)}
              className="text-[13px] font-semibold text-primary">
              
                  Modifier le code PIN
                </button>
            }
            </div>
          }

          <div className="flex items-center gap-3 border-t border-line px-4 py-3.5">
            <FingerprintIcon size={18} className="text-primary" />
            <div className="min-w-0 flex-1">
              <p className="text-[14px] font-semibold text-ink">Biométrie</p>
              <p className="text-2xs text-muted">
                {session?.pinActif ?
                'Empreinte ou visage pour déverrouiller' :
                'Activez d’abord le code PIN'}
              </p>
            </div>
            <Switch
              label="Activer la biométrie"
              actif={!!session?.biometrie}
              onChange={() =>
              session?.pinActif ?
              basculerBiometrie() :
              notifier('Activez d’abord le code PIN.', 'erreur')
              } />
            
          </div>

          <div className="flex items-center gap-3 border-t border-line px-4 py-3.5">
            {theme === 'clair' ?
            <SunIcon size={18} className="text-primary" /> :

            <MoonIcon size={18} className="text-primary" />
            }
            <div className="min-w-0 flex-1">
              <p className="text-[14px] font-semibold text-ink">Thème sombre</p>
              <p className="text-2xs text-muted">Confort de lecture en boutique</p>
            </div>
            <Switch label="Thème sombre" actif={theme === 'sombre'} onChange={basculerTheme} />
          </div>
        </section>

        {liens.length > 0 &&
        <section className="overflow-hidden rounded-2xl border border-line bg-surface">
            {liens.map((l, i) => {
            const Icone = l.icone;
            return (
              <button
                key={l.cle}
                type="button"
                onClick={l.onClick}
                className={`flex w-full items-center gap-3 px-4 py-3.5 text-left transition-colors duration-150 ease-out hover:bg-surface2 ${
                i > 0 ? 'border-t border-line' : ''}`
                }>
                
                  <Icone size={18} className="text-primary" />
                  <span className="min-w-0 flex-1">
                    <span className="block text-[14px] font-semibold text-ink">{l.label}</span>
                    <span className="block truncate text-2xs text-muted">{l.description}</span>
                  </span>
                  <ChevronRightIcon size={16} className="shrink-0 text-muted" />
                </button>);

          })}
          </section>
        }

        <Button variante="secondaire" taille="lg" pleineLargeur onClick={deconnexion}>
          <LogOutIcon size={17} /> Se déconnecter
        </Button>

        <p className="pb-4 text-center text-2xs text-muted">
          Ma Boutique · v1.0 · {boutique?.nom}
        </p>
      </div>
    </SubScreen>);

}