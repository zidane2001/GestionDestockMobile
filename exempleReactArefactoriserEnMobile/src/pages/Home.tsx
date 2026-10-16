import React, { useState } from 'react';
import { motion, useAnimationControls } from 'framer-motion';
import { AppHeader } from '../components/AppHeader';
import { BottomTabs, Onglet } from '../components/BottomTabs';
import { TableauDeBord } from './TableauDeBord';
import { ActionsStock } from './ActionsStock';
import { VenteSheet } from '../components/sheets/VenteSheet';
import { DefectueuxSheet } from '../components/sheets/DefectueuxSheet';
import { RetourSheet } from '../components/sheets/RetourSheet';
import { DepenseSheet } from '../components/sheets/DepenseSheet';
import { ProduitSheet } from '../components/sheets/ProduitSheet';
import { Produit } from '../types';

export type TypeSheet = 'vente' | 'defectueux' | 'retour' | 'depense' | 'sortie' | 'produit' | null;

const EASE = [0.23, 1, 0.32, 1] as const;

export function Home() {
  const [onglet, setOnglet] = useState<Onglet>('tableau');
  const [sheet, setSheet] = useState<TypeSheet>(null);
  const [produitActif, setProduitActif] = useState<Produit | null>(null);
  const controls = useAnimationControls();

  const allerA = (o: Onglet) => {
    setOnglet(o);
    controls.start({ x: o === 'tableau' ? '0%' : '-50%', transition: { duration: 0.28, ease: EASE } });
  };

  const ouvrir = (type: TypeSheet, produit: Produit | null = null) => {
    setProduitActif(produit);
    setSheet(type);
  };

  const fermer = () => {
    setSheet(null);
    setProduitActif(null);
  };

  return (
    <div className="flex h-full flex-col bg-canvas">
      <AppHeader />

      <div className="relative flex-1 overflow-hidden">
        <motion.div
          className="flex h-full w-[200%]"
          animate={controls}
          initial={{ x: '0%' }}
          drag="x"
          dragDirectionLock
          dragElastic={0.08}
          dragMomentum={false}
          onDragEnd={(_, info) => {
            if (info.offset.x < -60 && onglet === 'tableau') allerA('actions');else
            if (info.offset.x > 60 && onglet === 'actions') allerA('tableau');else
            allerA(onglet);
          }}>
          
          <div className="h-full w-1/2 overflow-y-auto no-scrollbar">
            <TableauDeBord onOuvrirActions={() => allerA('actions')} />
          </div>
          <div className="h-full w-1/2 overflow-y-auto no-scrollbar">
            <ActionsStock onOuvrirSheet={ouvrir} />
          </div>
        </motion.div>

        <div className="pointer-events-none absolute bottom-2 left-1/2 flex -translate-x-1/2 gap-1.5">
          {(['tableau', 'actions'] as Onglet[]).map((o) =>
          <span
            key={o}
            className={`h-1.5 rounded-full transition-[width,background-color] duration-200 ease-out ${
            onglet === o ? 'w-5 bg-primary' : 'w-1.5 bg-line'}`
            } />

          )}
        </div>
      </div>

      <BottomTabs actif={onglet} onChange={allerA} />

      <VenteSheet ouvert={sheet === 'vente'} onFermer={fermer} produitInitial={produitActif} />
      <DefectueuxSheet ouvert={sheet === 'defectueux'} onFermer={fermer} produitInitial={produitActif} />
      <RetourSheet ouvert={sheet === 'retour'} onFermer={fermer} produitInitial={produitActif} />
      <DepenseSheet
        ouvert={sheet === 'depense' || sheet === 'sortie'}
        onFermer={fermer}
        type={sheet === 'sortie' ? 'sortie_justifiee' : 'depense'} />
      
      <ProduitSheet ouvert={sheet === 'produit'} onFermer={fermer} produitInitial={produitActif} />
    </div>);

}