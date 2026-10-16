import React, { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowDownRightIcon,
  ArrowUpRightIcon,
  ChevronRightIcon,
  CloudOffIcon,
  ClockIcon,
  DownloadIcon,
  HistoryIcon,
  ListChecksIcon,
  ReceiptTextIcon,
  TrendingUpIcon,
  WalletIcon } from
'lucide-react';
import { useApp } from '../contexts/AppContext';
import { SalesChart } from '../components/SalesChart';
import { SegmentedControl } from '../components/ui/SegmentedControl';
import { Badge } from '../components/ui/Badge';
import { EmptyState } from '../components/ui/EmptyState';
import { peut } from '../utils/permissions';
import { dateHeure, formatMontant, ilYA, ROLE_LABEL } from '../utils/format';
import {
  beneficeNet,
  chiffreAffaires,
  classementProduits,
  margeTotale,
  piecesVendues,
  serieJournaliere,
  tendance,
  ventesRecentes } from
'../utils/stats';

export function TableauDeBord({ onOuvrirActions }: {onOuvrirActions: () => void;}) {
  const navigate = useNavigate();
  const { boutique, session, ventes, depenses, retours, enLigne, enAttenteSync } = useApp();
  const [periode, setPeriode] = useState<'7' | '30'>('7');
  const monnaie = boutique?.monnaie ?? 'FCFA';
  /** Les droits sont portés par le compte, pas seulement par le rôle. */
  const acteur = session;
  const historiqueComplet = peut(acteur, 'historiqueComplet');
  const jours = Number(periode);

  const mesVentes = useMemo(
    () => historiqueComplet ? ventes : ventes.filter((v) => v.vendeurId === session?.id),
    [ventes, historiqueComplet, session]
  );
  const periodeVentes = useMemo(() => ventesRecentes(mesVentes, jours), [mesVentes, jours]);
  const serieCA = useMemo(() => serieJournaliere(mesVentes, jours, 'ca'), [mesVentes, jours]);
  const serieMarge = useMemo(() => serieJournaliere(ventes, jours, 'marge'), [ventes, jours]);
  const aujourdhui = useMemo(() => ventesRecentes(mesVentes, 1), [mesVentes]);
  const top = useMemo(() => classementProduits(periodeVentes).slice(0, 4), [periodeVentes]);
  const variation = useMemo(() => tendance(mesVentes, jours), [mesVentes, jours]);
  const marge = margeTotale(ventesRecentes(ventes, jours));
  const ca = chiffreAffaires(periodeVentes);
  const tauxMarge = ca > 0 ? Math.round(marge / ca * 100) : 0;
  const retoursEnAttente = retours.filter((r) => r.statut === 'en_attente').length;

  return (
    <div className="space-y-4 px-4 pb-16 pt-4">
      {!enLigne &&
      <div className="flex items-start gap-2.5 rounded-xl border border-accent/30 bg-accent/10 px-3.5 py-3">
          <CloudOffIcon size={16} className="mt-0.5 shrink-0 text-accent" />
          <p className="text-[13px] font-medium leading-snug text-ink">
            Hors-ligne — {enAttenteSync} opération{enAttenteSync > 1 ? 's' : ''} en attente. Tout sera
            envoyé à l'équipe dès le retour du réseau.
          </p>
        </div>
      }

      {/* Solde de caisse — élément principal de l'écran */}
      <section className="rounded-3xl bg-primary px-5 py-6 text-onPrimary">
        <div className="flex items-center gap-2 text-[13px] font-semibold opacity-80">
          <WalletIcon size={15} /> Solde de la caisse
        </div>
        <p className="mt-2 text-[34px] font-extrabold leading-none tracking-tight tnum">
          {formatMontant(boutique?.soldeCaisse ?? 0, monnaie)}
        </p>
        <div className="mt-5 grid grid-cols-2 gap-3 border-t border-white/20 pt-4 text-[13px]">
          <div>
            <p className="opacity-75">Ventes du jour</p>
            <p className="mt-0.5 text-[17px] font-bold tnum">
              {formatMontant(chiffreAffaires(aujourdhui), monnaie)}
            </p>
          </div>
          <div>
            <p className="opacity-75">Pièces vendues</p>
            <p className="mt-0.5 text-[17px] font-bold tnum">{piecesVendues(aujourdhui)}</p>
          </div>
        </div>
      </section>

      {/* Courbe des ventes — patron et manager */}
      {peut(acteur, 'voirCourbeVentes') ?
      <section className="rounded-2xl border border-line bg-surface p-4">
          <div className="flex items-center justify-between gap-3">
            <div>
              <h2 className="text-[15px] font-bold text-ink">Évolution des ventes</h2>
              <p className="mt-0.5 flex items-center gap-1.5 text-2xs text-muted">
                <span className="font-semibold text-ink tnum">{formatMontant(ca, monnaie)}</span>
                sur {jours} jours
                <span
                className={`inline-flex items-center gap-0.5 font-semibold ${
                variation >= 0 ? 'text-success' : 'text-danger'}`
                }>
                
                  {variation >= 0 ? <ArrowUpRightIcon size={11} /> : <ArrowDownRightIcon size={11} />}
                  {Math.abs(variation)} %
                </span>
              </p>
            </div>
            <SegmentedControl
            ariaLabel="Période"
            valeur={periode}
            onChange={setPeriode}
            options={[
            { valeur: '7', label: '7 j' },
            { valeur: '30', label: '30 j' }]
            } />
          
          </div>
          <div className="mt-3">
            <SalesChart points={serieCA} monnaie={monnaie} />
          </div>
        </section> :

      <section className="rounded-2xl border border-line bg-surface p-4">
          <h2 className="text-[15px] font-bold text-ink">Mes ventes</h2>
          <div className="mt-3 grid grid-cols-2 gap-3">
            <div className="rounded-xl bg-surface2 px-3.5 py-3">
              <p className="text-2xs text-muted">Aujourd'hui</p>
              <p className="mt-0.5 text-[17px] font-bold text-ink tnum">
                {formatMontant(chiffreAffaires(aujourdhui), monnaie)}
              </p>
            </div>
            <div className="rounded-xl bg-surface2 px-3.5 py-3">
              <p className="text-2xs text-muted">7 derniers jours</p>
              <p className="mt-0.5 text-[17px] font-bold text-ink tnum">
                {formatMontant(chiffreAffaires(ventesRecentes(mesVentes, 7)), monnaie)}
              </p>
            </div>
          </div>
        </section>
      }

      {/* Bénéfices — patron uniquement */}
      {peut(acteur, 'voirBenefices') &&
      <section className="rounded-2xl border border-line bg-surface p-4">
          <div className="flex items-start justify-between gap-3">
            <div>
              <h2 className="text-[15px] font-bold text-ink">Bénéfices</h2>
              <p className="mt-0.5 text-2xs text-muted">Marges des produits vendus − dépenses</p>
            </div>
            <Badge ton="accent">
              <TrendingUpIcon size={11} /> marge {tauxMarge} %
            </Badge>
          </div>
          <div className="mt-3 grid grid-cols-2 gap-3">
            <div className="rounded-xl bg-surface2 px-3.5 py-3">
              <p className="text-2xs text-muted">Marge sur {jours} j</p>
              <p className="mt-0.5 text-[17px] font-bold text-ink tnum">
                {formatMontant(marge, monnaie)}
              </p>
            </div>
            <div className="rounded-xl bg-surface2 px-3.5 py-3">
              <p className="text-2xs text-muted">Bénéfice net</p>
              <p className="mt-0.5 text-[17px] font-bold text-ink tnum">
                {formatMontant(
                beneficeNet(ventesRecentes(ventes, jours), depenses.filter((d) => new Date(d.date).getTime() >= Date.now() - jours * 86_400_000)),
                monnaie
              )}
              </p>
            </div>
          </div>
          <div className="mt-3">
            <SalesChart points={serieMarge} couleur="accent" monnaie={monnaie} hauteur={104} />
          </div>
        </section>
      }

      {/* Top produits */}
      {peut(acteur, 'voirCourbeVentes') &&
      <section className="rounded-2xl border border-line bg-surface p-4">
          <h2 className="text-[15px] font-bold text-ink">Produits les plus vendus</h2>
          <ul className="mt-3 space-y-2.5">
            {top.length === 0 && <li className="text-[13px] text-muted">Aucune vente sur la période.</li>}
            {top.map((l, i) => {
            const maxPieces = top[0].pieces || 1;
            return (
              <li key={l.produitId}>
                  <div className="flex items-baseline justify-between gap-3">
                    <p className="truncate text-[13px] font-semibold text-ink">
                      {i + 1}. {l.nom}
                    </p>
                    <p className="shrink-0 text-[13px] text-muted tnum">
                      {l.pieces} pc · {formatMontant(l.ca, monnaie)}
                    </p>
                  </div>
                  <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-surface2">
                    <div
                    className="h-full rounded-full bg-primary"
                    style={{ width: `${l.pieces / maxPieces * 100}%` }} />
                  
                  </div>
                </li>);

          })}
          </ul>
        </section>
      }

      {/* Raccourcis patron / manager */}
      <section className="grid grid-cols-2 gap-2.5">
        {peut(acteur, 'exporter') &&
        <button
          type="button"
          onClick={() => navigate('/rapports')}
          className="flex items-center gap-2.5 rounded-2xl border border-line bg-surface px-3.5 py-3 text-left transition-colors duration-150 ease-out hover:bg-surface2">
          
            <DownloadIcon size={17} className="text-primary" />
            <span className="text-[13px] font-semibold text-ink">
              {peut(acteur, 'voirPrixAchat') ? 'Rapports & export' : 'Rapport hebdo'}
            </span>
          </button>
        }
        {peut(acteur, 'journal') &&
        <button
          type="button"
          onClick={() => navigate('/journal')}
          className="flex items-center gap-2.5 rounded-2xl border border-line bg-surface px-3.5 py-3 text-left transition-colors duration-150 ease-out hover:bg-surface2">
          
            <HistoryIcon size={17} className="text-primary" />
            <span className="text-[13px] font-semibold text-ink">Journal d'activité</span>
          </button>
        }
        {peut(acteur, 'pointages') &&
        <button
          type="button"
          onClick={() => navigate('/pointages')}
          className="flex items-center gap-2.5 rounded-2xl border border-line bg-surface px-3.5 py-3 text-left transition-colors duration-150 ease-out hover:bg-surface2">
          
            <ClockIcon size={17} className="text-primary" />
            <span className="text-[13px] font-semibold text-ink">Pointages</span>
          </button>
        }
        {peut(acteur, 'traiterRetours') &&
        <button
          type="button"
          onClick={() => navigate('/retours')}
          className="flex items-center justify-between gap-2 rounded-2xl border border-line bg-surface px-3.5 py-3 text-left transition-colors duration-150 ease-out hover:bg-surface2">
          
            <span className="flex items-center gap-2.5">
              <ListChecksIcon size={17} className="text-primary" />
              <span className="text-[13px] font-semibold text-ink">Retours</span>
            </span>
            {retoursEnAttente > 0 && <Badge ton="danger">{retoursEnAttente}</Badge>}
          </button>
        }
      </section>

      {/* Historique des ventes */}
      <section className="rounded-2xl border border-line bg-surface">
        <div className="flex items-center justify-between border-b border-line px-4 py-3">
          <h2 className="text-[15px] font-bold text-ink">
            {historiqueComplet ? 'Historique des ventes' : 'Mes ventes'}
          </h2>
          <button
            type="button"
            onClick={onOuvrirActions}
            className="flex items-center gap-0.5 text-2xs font-semibold text-primary">
            
            Enregistrer une vente <ChevronRightIcon size={13} />
          </button>
        </div>
        {mesVentes.length === 0 ?
        <EmptyState
          icone={<ReceiptTextIcon size={20} />}
          titre="Aucune vente pour l'instant"
          texte="Les ventes enregistrées par l'équipe apparaîtront ici, avec le nom du vendeur." /> :


        <ul className="divide-y divide-line">
            {mesVentes.slice(0, 12).map((v) =>
          <li key={v.id} className="flex items-center gap-3 px-4 py-3">
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[14px] font-semibold text-ink">{v.produitNom}</p>
                  <p className="mt-0.5 truncate text-2xs text-muted">
                    {v.quantite} × {formatMontant(v.prixUnitaireReel, monnaie)} ·{' '}
                    {historiqueComplet ? `${v.vendeurNom} (${ROLE_LABEL[v.vendeurRole]})` : ilYA(v.date)}
                  </p>
                </div>
                <div className="shrink-0 text-right">
                  <p className="text-[14px] font-bold text-ink tnum">{formatMontant(v.total, monnaie)}</p>
                  <p className="text-2xs text-muted tnum">{dateHeure(v.date)}</p>
                </div>
              </li>
          )}
          </ul>
        }
      </section>
    </div>);

}