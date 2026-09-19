/// Supabase project connection details.
///
/// The anon key is safe to ship inside the compiled app — it identifies
/// the project, not a privileged credential. Every table it can touch is
/// still governed by Row Level Security (see supabase/schema.sql); the
/// anon key on its own grants no access to anything.
///
/// The service-role key (which DOES bypass RLS) must NEVER appear here or
/// anywhere else in this Flutter app — it lives only in Supabase Edge
/// Function secrets (see supabase/functions/).
///
/// Replace these two placeholders with your project's real values from
/// Supabase Dashboard → Project Settings → API, or better, inject them at
/// build time with --dart-define (see README.md "Setup").
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_REF.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
}
