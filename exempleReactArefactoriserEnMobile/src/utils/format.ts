const SYMBOLES: Record<string, string> = {
  FCFA: 'FCFA',
  EUR: '€',
  USD: '$'
};

export function formatMontant(valeur: number, monnaie = 'FCFA'): string {
  const n = new Intl.NumberFormat('fr-FR', {
    maximumFractionDigits: monnaie === 'FCFA' ? 0 : 2,
    minimumFractionDigits: 0
  }).format(Math.round(valeur * 100) / 100);
  return monnaie === 'FCFA' ? `${n} FCFA` : `${SYMBOLES[monnaie] ?? ''}${n}`;
}

export function formatCompact(valeur: number): string {
  if (Math.abs(valeur) >= 1_000_000) return `${(valeur / 1_000_000).toFixed(1)} M`;
  if (Math.abs(valeur) >= 1_000) return `${Math.round(valeur / 1_000)} k`;
  return String(Math.round(valeur));
}

export function jourCourt(iso: string): string {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' });
}

export function heure(iso: string): string {
  return new Date(iso).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
}

export function dateHeure(iso: string): string {
  return `${jourCourt(iso)} · ${heure(iso)}`;
}

export function ilYA(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const min = Math.round(diff / 60000);
  if (min < 1) return "à l'instant";
  if (min < 60) return `il y a ${min} min`;
  const h = Math.round(min / 60);
  if (h < 24) return `il y a ${h} h`;
  const j = Math.round(h / 24);
  return j === 1 ? 'hier' : `il y a ${j} j`;
}

export function cleJour(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export const ROLE_LABEL: Record<string, string> = {
  patron: 'Patron',
  manager: 'Manager',
  caissiere: 'Caissière'
};