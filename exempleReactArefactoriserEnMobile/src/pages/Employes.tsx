import React, { useState } from 'react';
import {
  CheckIcon,
  PauseIcon,
  PlayIcon,
  RotateCcwIcon,
  ShieldCheckIcon,
  SlidersHorizontalIcon,
  Trash2Icon,
  UserPlusIcon } from
'lucide-react';
import { useApp } from '../contexts/AppContext';
import { SubScreen } from '../components/SubScreen';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Field, inputClass } from '../components/ui/Field';
import { SegmentedControl } from '../components/ui/SegmentedControl';
import { Sheet } from '../components/ui/Sheet';
import { Employe, Permission, Role } from '../types';
import { ROLE_LABEL } from '../utils/format';
import { GROUPES_PERMISSIONS, permissionsParDefaut } from '../utils/permissions';

export function Employes() {
  const {
    employes,
    creerEmploye,
    modifierEmploye,
    basculerStatutEmploye,
    supprimerEmploye,
    reinitialiserMotDePasse
  } = useApp();

  const [ouvert, setOuvert] = useState(false);
  const [edition, setEdition] = useState<Employe | null>(null);
  const [nom, setNom] = useState('');
  const [role, setRole] = useState<Role>('manager');
  const [mdp, setMdp] = useState('');
  const [droits, setDroits] = useState<Permission[]>(permissionsParDefaut('manager'));
  const [erreur, setErreur] = useState<string | null>(null);
  const [reinit, setReinit] = useState<string | null>(null);
  const [nouveauMdp, setNouveauMdp] = useState('');

  const ouvrirCreation = () => {
    setEdition(null);
    setNom('');
    setRole('manager');
    setMdp('');
    setDroits(permissionsParDefaut('manager'));
    setErreur(null);
    setOuvert(true);
  };

  const ouvrirEdition = (e: Employe) => {
    setEdition(e);
    setNom(e.nom);
    setRole(e.role);
    setMdp('');
    setDroits(e.permissions);
    setErreur(null);
    setOuvert(true);
  };

  const changerRole = (r: Role) => {
    setRole(r);
    setDroits(permissionsParDefaut(r));
  };

  const basculerDroit = (p: Permission) =>
  setDroits((ds) => ds.includes(p) ? ds.filter((d) => d !== p) : [...ds, p]);

  const valider = () => {
    if (nom.trim().length < 2) return setErreur('Indiquez le nom de l’employé.');
    if (!edition && mdp.length < 6)
    return setErreur('Le mot de passe doit contenir au moins 6 caractères.');
    if (droits.length === 0) return setErreur('Attribuez au moins un droit à cet employé.');
    if (edition) modifierEmploye(edition.id, { nom: nom.trim(), role, permissions: droits });else
    creerEmploye(nom.trim(), role, mdp, droits);
    setOuvert(false);
  };

  return (
    <>
      <SubScreen
        titre="Comptes employés"
        sousTitre={`${employes.length} compte${employes.length > 1 ? 's' : ''}`}
        action={
        <Button taille="sm" onClick={ouvrirCreation}>
            <UserPlusIcon size={15} /> Créer
          </Button>
        }>
        
        <ul className="space-y-2 px-4 py-4">
          {employes.map((e) => {
            const defaut = permissionsParDefaut(e.role);
            const personnalise =
            e.permissions.length !== defaut.length ||
            e.permissions.some((p) => !defaut.includes(p));
            return (
              <li key={e.id} className="rounded-2xl border border-line bg-surface px-4 py-3.5">
                <div className="flex items-start gap-3">
                  <div className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-primarySoft text-[14px] font-bold text-primary">
                    {e.nom.slice(0, 1)}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[14px] font-semibold text-ink">{e.nom}</p>
                    <p className="text-2xs text-muted">
                      {ROLE_LABEL[e.role]} · {e.permissions.length} droits
                      {personnalise ? ' (personnalisés)' : ''}
                    </p>
                  </div>
                  {e.statut === 'actif' ?
                  <Badge ton="succes">Actif</Badge> :

                  <Badge ton="danger">Suspendu</Badge>
                  }
                </div>

                {e.role !== 'patron' &&
                <>
                    <div className="mt-3 flex flex-wrap items-center gap-2">
                      <Button taille="sm" onClick={() => ouvrirEdition(e)}>
                        <SlidersHorizontalIcon size={14} /> Rôle & droits
                      </Button>
                      <Button
                      taille="sm"
                      variante="secondaire"
                      onClick={() => setReinit(reinit === e.id ? null : e.id)}>
                      
                        <RotateCcwIcon size={14} /> Mot de passe
                      </Button>
                      <Button
                      taille="sm"
                      variante="secondaire"
                      onClick={() => basculerStatutEmploye(e.id)}>
                      
                        {e.statut === 'actif' ?
                      <>
                            <PauseIcon size={14} /> Suspendre
                          </> :

                      <>
                            <PlayIcon size={14} /> Réactiver
                          </>
                      }
                      </Button>
                      <button
                      type="button"
                      onClick={() => supprimerEmploye(e.id)}
                      aria-label={`Supprimer le compte de ${e.nom}`}
                      className="grid h-9 w-9 place-items-center rounded-xl bg-surface2 text-muted transition-colors duration-150 ease-out hover:text-danger">
                      
                        <Trash2Icon size={15} />
                      </button>
                    </div>

                    {reinit === e.id &&
                  <div className="mt-3 space-y-2 rounded-xl bg-surface2 p-3">
                        <input
                      className={inputClass}
                      value={nouveauMdp}
                      onChange={(ev) => setNouveauMdp(ev.target.value)}
                      placeholder="Nouveau mot de passe (min. 6)"
                      aria-label="Nouveau mot de passe" />
                    
                        <Button
                      taille="sm"
                      onClick={() => {
                        if (nouveauMdp.length < 6) return;
                        reinitialiserMotDePasse(e.id, nouveauMdp);
                        setNouveauMdp('');
                        setReinit(null);
                      }}>
                      
                          Attribuer
                        </Button>
                      </div>
                  }
                  </>
                }

                {e.role === 'patron' &&
                <p className="mt-3 flex items-center gap-1.5 text-2xs text-muted">
                    <ShieldCheckIcon size={13} className="text-primary" /> Accès complet, non
                    modifiable
                  </p>
                }
              </li>);

          })}
        </ul>
      </SubScreen>

      <Sheet
        ouvert={ouvert}
        onFermer={() => setOuvert(false)}
        titre={edition ? `Droits de ${edition.nom}` : 'Créer un compte'}
        sousTitre={
        edition ?
        'Les droits s’appliquent dès la prochaine ouverture de son application' :
        'L’employé se connecte avec le nom de la boutique et ce mot de passe'
        }>
        
        <div className="space-y-4 pb-2">
          <Field label="Nom de l’employé">
            <input
              className={inputClass}
              value={nom}
              onChange={(e) => setNom(e.target.value)}
              placeholder="Ex. Ibrahim Sow" />
            
          </Field>

          <Field label="Rôle" aide="Change les droits attribués par défaut">
            <SegmentedControl
              ariaLabel="Rôle"
              valeur={role}
              onChange={changerRole}
              options={[
              { valeur: 'manager', label: 'Manager' },
              { valeur: 'caissiere', label: 'Caissière' }]
              } />
            
          </Field>

          {!edition &&
          <Field label="Mot de passe" aide="Minimum 6 caractères">
              <input
              className={inputClass}
              value={mdp}
              onChange={(e) => {
                setMdp(e.target.value);
                setErreur(null);
              }}
              placeholder="••••••" />
            
            </Field>
          }

          <section>
            <div className="flex items-end justify-between gap-3">
              <div>
                <h3 className="text-[13px] font-semibold text-ink">Permissions</h3>
                <p className="text-2xs text-muted">
                  {droits.length} droit{droits.length > 1 ? 's' : ''} attribué
                  {droits.length > 1 ? 's' : ''}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setDroits(permissionsParDefaut(role))}
                className="text-2xs font-semibold text-primary">
                
                Droits par défaut du rôle
              </button>
            </div>

            <div className="mt-3 space-y-4">
              {GROUPES_PERMISSIONS.map((g) =>
              <div key={g.titre}>
                  <p className="mb-1.5 text-2xs font-bold uppercase tracking-wide text-muted">
                    {g.titre}
                  </p>
                  <ul className="overflow-hidden rounded-xl border border-line">
                    {g.items.map((item, i) => {
                    const actif = droits.includes(item.cle);
                    return (
                      <li key={item.cle}>
                          <button
                          type="button"
                          role="checkbox"
                          aria-checked={actif}
                          onClick={() => {
                            basculerDroit(item.cle);
                            setErreur(null);
                          }}
                          className={`flex w-full items-center gap-3 px-3.5 py-3 text-left transition-colors duration-150 ease-out ${
                          i > 0 ? 'border-t border-line' : ''} ${
                          actif ? 'bg-primarySoft' : 'bg-surface2 hover:bg-line/40'}`}>
                          
                            <span
                            className={`grid h-5 w-5 shrink-0 place-items-center rounded-md border transition-colors duration-150 ease-out ${
                            actif ?
                            'border-primary bg-primary text-onPrimary' :
                            'border-line bg-surface'}`
                            }>
                            
                              {actif && <CheckIcon size={13} strokeWidth={3} />}
                            </span>
                            <span className="min-w-0 flex-1">
                              <span
                              className={`block text-[13px] font-semibold ${
                              actif ? 'text-primary' : 'text-ink'}`
                              }>
                              
                                {item.label}
                              </span>
                              <span className="block text-2xs text-muted">{item.description}</span>
                            </span>
                          </button>
                        </li>);

                  })}
                  </ul>
                </div>
              )}
            </div>
          </section>

          {erreur && <p className="text-[13px] font-medium text-danger">{erreur}</p>}

          <Button taille="lg" pleineLargeur onClick={valider}>
            {edition ? 'Enregistrer les droits' : 'Créer le compte'}
          </Button>
          <p className="pb-1 text-center text-2xs leading-relaxed text-muted">
            La gestion des comptes, des appareils et le traitement des retours restent réservés au
            patron.
          </p>
        </div>
      </Sheet>
    </>);

}