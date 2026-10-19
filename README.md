# DnD Cue Cards

A Flutter desktop app for creating and managing cue cards, with optional
Supabase sharing for players. The DM's SQLite database remains the source of
truth; publishing a card sends a snapshot to Supabase.

## Supabase setup

1. Create a Supabase project and keep the project URL and **anon/publishable
   key** available to the apps. Never put a service-role key in a client app or
   commit credentials.
2. In **Authentication → Providers**, enable **Email** for DMs and **Anonymous
   Sign-Ins** for players. Configure email confirmation as appropriate for the
   DM accounts.
3. Apply every SQL migration, in filename order, from `supabase/migrations/`.
   For example, with the Supabase CLI:

   ```powershell
   supabase login
   supabase link --project-ref <project-ref>
   supabase db push
   ```

   The migration creates the sharing tables and RLS policies, enforces a
   100,000-byte shared-payload limit, and publishes ID-only card-revocation
   events. Player queries still cannot read revoked card payloads.
4. Review the policies and Auth rate limits in the Supabase dashboard before
   inviting players. Supabase Auth's anonymous sign-in limits apply; configure
   CAPTCHA/rate limits for the project's expected traffic.

The project can be restored if a free Supabase project has paused: open the
project in the Supabase dashboard and resume/restore it there. The apps keep
local DM card editing available offline and show an error when a sharing
request cannot reach Supabase.

## Run the DM desktop app

Install Flutter dependencies with `flutter pub get`, then either configure the
Supabase URL and anon key in **Campaigns → Settings** in the app, or provide
them at launch:

```powershell
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-or-publishable-key>
```

The URL and public anon key are stored in local preferences when entered in
the app. A DM must register/sign in with an email account before creating
campaigns. Players receive the displayed join code or player link from the DM.

## Run the player web app

The web player has its own entry point (`lib/player/main.dart`). It imports no
SQLite or `dart:io` code from the desktop app.

```powershell
flutter run -d chrome -t lib/player/main.dart `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-or-publishable-key>
```

Player auth sessions and the last-viewed card versions are stored in the
browser, so a refresh keeps a joined player's session and campaign. Build a
release bundle with:

```powershell
flutter build web --release -t lib/player/main.dart `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-or-publishable-key>
```

The generated static site is in `build/web`. Deploy its contents to any static
host that serves `index.html` for the site root. For a subdirectory deployment,
set the matching base path, for example `--base-href /cards/`, when building.
The player link uses a hash route, so normal refreshes remain at the site root.
Pass the same player URL to the DM app as `PLAYER_WEB_URL`, or set it in the DM
app's sharing settings.

## Tests and RLS verification

Run the automated suite and static analysis with:

```powershell
flutter test
flutter analyze
```

The SQL RLS check in `supabase/tests/sharing_rls_test.sql` uses simulated
authenticated JWT subjects and rolls back its fixtures. Run it only against a
disposable Supabase test project/database after applying all migrations.

For checks against actual authenticated client sessions, provision two
dedicated test DM accounts with email/password sign-in enabled and set the
following environment variables in PowerShell. The live test creates and
deletes temporary campaigns; do not point it at production data.

```powershell
$env:SUPABASE_TEST_URL = 'https://<project-ref>.supabase.co'
$env:SUPABASE_TEST_ANON_KEY = '<anon-or-publishable-key>'
$env:SUPABASE_TEST_DM_EMAIL = '<first-test-dm-email>'
$env:SUPABASE_TEST_DM_PASSWORD = '<first-test-dm-password>'
$env:SUPABASE_TEST_OTHER_DM_EMAIL = '<second-test-dm-email>'
$env:SUPABASE_TEST_OTHER_DM_PASSWORD = '<second-test-dm-password>'
flutter test test/sharing_rls_live_test.dart
```

The live test also needs anonymous sign-in enabled. Without all six
environment variables, it is skipped. It verifies campaign-owner isolation,
member/non-member reads, player write denial, DM member removal, revoke
visibility/events, and rejection of oversized payloads. Run it after every
policy or migration change and before inviting players.
