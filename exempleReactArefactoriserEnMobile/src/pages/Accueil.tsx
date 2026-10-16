import React from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowRightIcon, StoreIcon } from 'lucide-react';
import { Button } from '../components/ui/Button';

const IMAGE = "/0ccfb021-4545-451f-9d6a-cc6c29a96b08.jpg";


export function Accueil() {
  const navigate = useNavigate();

  return (
    <div className="relative h-full w-full overflow-hidden bg-canvas">
      <img
        src={IMAGE}
        alt="Intérieur d'une boutique de vêtements"
        className="absolute inset-x-0 top-0 h-[58%] w-full object-cover" />
      
      <div className="absolute inset-x-0 top-0 h-[58%] bg-black/35" />

      <div className="absolute left-6 top-8 flex items-center gap-2.5 text-white">
        <span className="grid h-9 w-9 place-items-center rounded-xl bg-white/15 backdrop-blur">
          <StoreIcon size={18} />
        </span>
        <span className="text-[15px] font-bold">Ma Boutique</span>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 18 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3, ease: [0.23, 1, 0.32, 1] }}
        className="absolute inset-x-0 bottom-0 rounded-t-3xl bg-surface px-6 pb-8 pt-7">
        
        <h1 className="text-[26px] font-extrabold leading-[1.15] tracking-tight text-ink">
          Votre stock et votre caisse,
          <br />
          <span className="text-primary">partagés avec l'équipe.</span>
        </h1>
        <p className="mt-3 text-[14px] leading-relaxed text-muted">
          Ventes, dépenses, retours et pointages sur un seul écran — même sans réseau. Chacun voit
          ce qui le concerne, selon son rôle.
        </p>

        <div className="mt-7 space-y-2.5">
          <Button taille="lg" pleineLargeur onClick={() => navigate('/creer')}>
            Créer une boutique <ArrowRightIcon size={17} />
          </Button>
          <Button variante="secondaire" taille="lg" pleineLargeur onClick={() => navigate('/connexion')}>
            Se connecter à ma boutique
          </Button>
        </div>

        <p className="mt-5 text-center text-2xs text-muted">
          Données synchronisées automatiquement dès le retour du réseau.
        </p>
      </motion.div>
    </div>);

}