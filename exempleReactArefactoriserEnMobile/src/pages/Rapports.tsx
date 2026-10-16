import React, { useMemo, useState } from 'react';
import { CalendarDaysIcon, DownloadIcon, FileTextIcon, Share2Icon } from 'lucide-react';
import { useApp } from '../contexts/AppContext';
import { SubScreen } from '../components/SubScreen';
import { SalesChart } from '../components/SalesChart';
import { SegmentedControl } from '../components/ui/SegmentedControl';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { peut } from '../utils/permissions';
import { dateHeure, formatMontant } from '../utils/format';
import {
  chiffreAffaires,
  classementProduits,
  exporterCsv,
  margeTotale,
  piecesVendues,
  serieJournaliere,
  tendance,
  ventesRecentes } from
'../utils/stats';

export function Rapports() {
  const { ventes, depenses, session, boutique, notifier } = useApp();
  const monnaie = boutique?.monnaie ?? 'FCFA';
  const complet = peut(session, 'voirPrixAchat');
  const [periode, setPeriode] = useState<'7' | '30'>(complet ? '30' : '7');
  const jours = Number(periode);

  const periodeVentes = useMemo(() => ventesRecentes(ventes, jours), [ventes, jours]);
  const serie = useMemo(() => serieJournaliere(ventes, jours, 'ca'), [ventes, jours]);
  const classement = useMemo(() => classementProduits(periodeVentes), [periodeVentes]);
  const ca = chiffreAffaires(periodeVentes);
  const marge = margeTotale(periodeVentes);
  const depensesPeriode = depenses.filter(
    (d) => new Date(d.date).getTime() >= Date.now() - jours * 86_400_000
  );

  const exporter = () => {
    const date = new Date().toISOString().slice(0, 10);
    const entete = complet ?
    ['Date', 'Produit', 'Quantité', 'Prix de vente', "Prix d'achat", 'Marge', 'Total', 'Vendeur'] :
    ['Date', 'Produit', 'Quantité', 'Prix de vente', 'Total', 'Vendeur'];
    const lignes = periodeVentes.map((v) =>
    complet ?
    [
    dateHeure(v.date),
    v.produitNom,
    v.quantite,
    v.prixUnitaireReel,
    v.prixAchatUnitaire,
    (v.prixUnitaireReel - v.prixAchatUnitaire) * v.quantite,
    v.total,
    v.vendeurNom] :

    [dateHeure(v.date), v.produitNom, v.quantite, v.prixUnitaireReel, v.total, v.vendeurNom]
    );
    exporterCsv(`rapport_ventes_${date}.csv`, [entete, ...lignes]);
    notifier('Rapport CSV généré — prêt à partager.');
  };

  const archives = useMemo(() => {
    const semaines: {debut: string;ca: number;}[] = [];
    for (let s = 1; s <= 3; s++) {
      const fin = Date.now() - (s - 1) * 7 * 86_400_000;
      const debut = fin - 7 * 86_400_000;
      const lot = ventes.filter((v) => {
        const t = new Date(v.date).getTime();
        return t >= debut && t < fin;
      });
      semaines.push({
        debut: new Date(debut).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' }),
        ca: chiffreAffaires(lot)
      });
    }
    return semaines;
  }, [ventes]);

  return (
    <SubScreen
      titre={complet ? 'Rapports & export' : 'Rapport hebdomadaire'}
      sousTitre={complet ? 'Données complètes, marges incluses' : 'Sans données de prix d’achat'}>
      
      <div className="space-y-4 px-4 py-4">
        {complet &&
        <SegmentedControl
          ariaLabel="Période du rapport"
          valeur={periode}
          onChange={setPeriode}
          options={[
          { valeur: '7', label: '7 jours' },
          { valeur: '30', label: '30 jours' }]
          } />

        }

        <section className="rounded-2xl border border-line bg-surface p-4">
          <div className="flex items-baseline justify-between gap-3">
            <div>
              <p className="text-2xs text-muted">Chiffre d'affaires · {jours} j</p>
              <p className="mt-0.5 text-[26px] font-extrabold leading-none text-ink tnum">
                {formatMontant(ca, monnaie)}
              </p>
            </div>
            <Badge ton={tendance(ventes, jours) >= 0 ? 'succes' : 'danger'}>
              {tendance(ventes, jours) >= 0 ? '+' : ''}
              {tendance(ventes, jours)} %
            </Badge>
          </div>
          <div className="mt-3">
            <SalesChart points={serie} monnaie={monnaie} hauteur={116} />
          </div>
          <dl className="mt-3 grid grid-cols-2 gap-3 border-t border-line pt-3 text-[13px]">
            <div>
              <dt className="text-2xs text-muted">Pièces vendues</dt>
              <dd className="font-bold text-ink tnum">{piecesVendues(periodeVentes)}</dd>
            </div>
            <div>
              <dt className="text-2xs text-muted">Nombre de ventes</dt>
              <dd className="font-bold text-ink tnum">{periodeVentes.length}</dd>
            </div>
            {complet &&
            <>
                <div>
                  <dt className="text-2xs text-muted">Marge brute</dt>
                  <dd className="font-bold text-ink tnum">{formatMontant(marge, monnaie)}</dd>
                </div>
                <div>
                  <dt className="text-2xs text-muted">Bénéfice net</dt>
                  <dd className="font-bold text-ink tnum">
                    {formatMontant(
                    marge - depensesPeriode.reduce((s, d) => s + d.montant, 0),
                    monnaie
                  )}
                  </dd>
                </div>
              </>
            }
          </dl>
        </section>

        <section className="overflow-hidden rounded-2xl border border-line bg-surface">
          <h2 className="border-b border-line px-4 py-3 text-[15px] font-bold text-ink">
            Par produit
          </h2>
          <ul className="divide-y divide-line">
            {classement.map((l) =>
            <li key={l.produitId} className="flex items-center gap-3 px-4 py-3">
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[14px] font-semibold text-ink">{l.nom}</p>
                  <p className="text-2xs text-muted tnum">
                    {l.pieces} pièce{l.pieces > 1 ? 's' : ''} · {formatMontant(l.ca, monnaie)}
                  </p>
                </div>
                {complet &&
              <p className="shrink-0 text-[13px] font-bold text-accent tnum">
                    +{formatMontant(l.marge, monnaie)}
                  </p>
              }
              </li>
            )}
            {classement.length === 0 &&
            <li className="px-4 py-6 text-center text-[13px] text-muted">
                Aucune vente sur la période.
              </li>
            }
          </ul>
        </section>

        {complet &&
        <section className="overflow-hidden rounded-2xl border border-line bg-surface">
            <h2 className="flex items-center gap-2 border-b border-line px-4 py-3 text-[15px] font-bold text-ink">
              <CalendarDaysIcon size={16} className="text-primary" /> Archives hebdomadaires
            </h2>
            <ul className="divide-y divide-line">
              {archives.map((a, i) =>
            <li key={a.debut} className="flex items-center gap-3 px-4 py-3">
                  <FileTextIcon size={16} className="shrink-0 text-muted" />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[14px] font-semibold text-ink">
                      Semaine du {a.debut}
                    </p>
                    <p className="text-2xs text-muted tnum">{formatMontant(a.ca, monnaie)}</p>
                  </div>
                  {i === 0 && <Badge ton="primaire">Dernier</Badge>}
                  <button
                type="button"
                onClick={() => notifier('Rapport archivé prêt au partage.', 'info')}
                aria-label={`Partager le rapport de la semaine du ${a.debut}`}
                className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-surface2 text-muted transition-colors duration-150 ease-out hover:text-ink">
                
                    <Share2Icon size={15} />
                  </button>
                </li>
            )}
            </ul>
          </section>
        }

        <Button taille="lg" pleineLargeur onClick={exporter}>
          <DownloadIcon size={17} /> Exporter en CSV
        </Button>
        <p className="pb-4 text-center text-2xs leading-relaxed text-muted">
          Le fichier s'ouvre dans Excel et se partage via WhatsApp, email ou fichiers.
          {!complet && ' Les prix d’achat ne sont jamais inclus.'}
        </p>
      </div>
    </SubScreen>);

}