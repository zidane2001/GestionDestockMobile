import React, { useState } from 'react';
import { PointSerie } from '../utils/stats';
import { formatCompact, formatMontant } from '../utils/format';

interface Props {
  points: PointSerie[];
  couleur?: 'primary' | 'accent';
  monnaie: string;
  hauteur?: number;
}

const L = 8;
const R = 8;

export function SalesChart({ points, couleur = 'primary', monnaie, hauteur = 132 }: Props) {
  const [actif, setActif] = useState<number | null>(null);
  const largeur = 320;
  const max = Math.max(...points.map((p) => p.valeur), 1);
  const pasX = (largeur - L - R) / Math.max(points.length - 1, 1);
  const y = (v: number) => hauteur - 18 - v / max * (hauteur - 34);
  const coords = points.map((p, i) => ({ x: L + i * pasX, y: y(p.valeur), p, i }));

  const ligne = coords.map((c) => `${c.x},${c.y}`).join(' ');
  const aire = `${L},${hauteur - 18} ${ligne} ${L + (points.length - 1) * pasX},${hauteur - 18}`;
  const trait = couleur === 'primary' ? 'rgb(var(--primary))' : 'rgb(var(--accent))';
  const point = actif !== null ? coords[actif] : null;

  return (
    <div className="relative">
      <svg
        viewBox={`0 0 ${largeur} ${hauteur}`}
        className="w-full"
        style={{ height: hauteur }}
        role="img"
        aria-label={`Évolution sur ${points.length} jours`}>
        
        {[0, 0.5, 1].map((f) =>
        <line
          key={f}
          x1={L}
          x2={largeur - R}
          y1={y(max * f)}
          y2={y(max * f)}
          stroke="rgb(var(--line))"
          strokeWidth="1"
          strokeDasharray={f === 0 ? undefined : '3 4'} />

        )}
        <polygon points={aire} fill={trait} opacity="0.12" />
        <polyline points={ligne} fill="none" stroke={trait} strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
        {point &&
        <>
            <line x1={point.x} x2={point.x} y1={12} y2={hauteur - 18} stroke={trait} strokeWidth="1" opacity="0.5" />
            <circle cx={point.x} cy={point.y} r="4.5" fill="rgb(var(--surface))" stroke={trait} strokeWidth="2.5" />
          </>
        }
        {!point && coords.length > 0 &&
        <circle
          cx={coords[coords.length - 1].x}
          cy={coords[coords.length - 1].y}
          r="4"
          fill={trait} />

        }
        {coords.map((c) =>
        <rect
          key={c.i}
          x={c.x - pasX / 2}
          y={0}
          width={pasX}
          height={hauteur}
          fill="transparent"
          onMouseEnter={() => setActif(c.i)}
          onMouseLeave={() => setActif(null)}
          onTouchStart={() => setActif(c.i)}
          className="cursor-pointer" />

        )}
      </svg>
      <div className="mt-1 flex justify-between px-1 text-2xs text-muted tnum">
        <span>{points[0]?.label}</span>
        <span>{points[Math.floor(points.length / 2)]?.label}</span>
        <span>{points[points.length - 1]?.label}</span>
      </div>
      <div className="pointer-events-none absolute right-1 top-0 text-2xs font-semibold text-muted tnum">
        max {formatCompact(max)}
      </div>
      {point &&
      <div className="pointer-events-none absolute left-0 top-0 rounded-lg border border-line bg-surface px-2 py-1 text-2xs font-semibold text-ink shadow-sm tnum">
          {point.p.label} · {formatMontant(point.p.valeur, monnaie)}
        </div>
      }
    </div>);

}