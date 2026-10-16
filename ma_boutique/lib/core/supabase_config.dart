/// Configuration Supabase.
///
/// Renseigner l'URL du projet et la clé « anon public » :
/// Supabase Dashboard -> Settings -> API.
/// Il est aussi possible de passer ces valeurs via :
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://kxgluwdhlgzmgdcszeln.supabase.co',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4Z2x1d2RobGd6bWdkY3N6ZWxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxMjkwNTMsImV4cCI6MjEwMjcwNTA1M30.Y99XBlEdPZ5SV3vnlFHYY6JdE2KxT_258UHbS5kkYng',
);

/// Clé « service_role » : contourne la RLS pour la console superadmin.
/// ⚠️ En production, remplacer par une API administrateur sécurisée côté serveur.
const String supabaseServiceKey = String.fromEnvironment(
  'SUPABASE_SERVICE_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4Z2x1d2RobGd6bWdkY3N6ZWxuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NzEyOTA1MywiZXhwIjoyMTAyNzA1MDUzfQ.K3368bW_8MBcELoxXmCj1cP79i03Riqii-3Qd44vYXQ',
);

/// Credentials superadmin : nom de boutique spécial + mot de passe dédié.
/// Modifiable, à garder secret.
const String superadminNomBoutique = 'superadmin';
const String superadminMotDePasse = String.fromEnvironment(
  'SUPERADMIN_MOT_DE_PASSE',
  defaultValue: 'NashShop@1234',
);

bool get supabaseConfigure =>
    !supabaseUrl.startsWith('REMPLACEZ-MOI') &&
    !supabaseAnonKey.startsWith('REMPLACEZ-MOI');