-- Schéma du site Ma Boutique (Postgres, compatible Neon et Render).
-- Exécuté au démarrage : toutes les instructions sont idempotentes.

CREATE TABLE IF NOT EXISTS versions (
  id            BIGSERIAL PRIMARY KEY,
  version       TEXT        NOT NULL,
  titre         TEXT        NOT NULL,
  notes         TEXT        NOT NULL DEFAULT '',
  lien_apk      TEXT        NOT NULL DEFAULT '',
  publiee_le    DATE        NOT NULL DEFAULT CURRENT_DATE,
  creee_le      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS versions_version_unique ON versions (version);

CREATE TABLE IF NOT EXISTS abonnements (
  id            BIGSERIAL PRIMARY KEY,
  nom           TEXT        NOT NULL,
  email         TEXT        NOT NULL,
  boutique      TEXT        NOT NULL DEFAULT '',
  telephone     TEXT        NOT NULL DEFAULT '',
  formule       TEXT        NOT NULL DEFAULT 'mensuel',
  message       TEXT        NOT NULL DEFAULT '',
  statut        TEXT        NOT NULL DEFAULT 'nouveau',
  cree_le       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Un email ne peut s'inscrire qu'une fois ; la casse n'a pas d'importance.
CREATE UNIQUE INDEX IF NOT EXISTS abonnements_email_unique
  ON abonnements (LOWER(email));

CREATE INDEX IF NOT EXISTS abonnements_cree_le_idx ON abonnements (cree_le DESC);
