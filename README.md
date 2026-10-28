# DnD Cue Cards

A Flutter desktop app for creating and managing cue cards, with optional
Supabase sharing for players. The DM's SQLite database remains the source of
truth; publishing a card sends a snapshot to Supabase.

## Supabase setup

1. Create a Supabase project and keep the project URL and **anon/publishable
   key** available to the apps. Never put a service-role key in a client app or
   commit credentials.
2. In **Authentication → Providers**, enable **Email** and **Google**. Disable
   anonymous sign-ins. Configure email confirmation as appropriate for all
   accounts.
3. Apply the fresh-project schema once from
   [`supabase/migrations/0001_sharing.sql`](./supabase/migrations/0001_sharing.sql).
   Either paste its contents into **SQL Editor** and run it, or use the
   Supabase CLI (do not use both methods on the same project):

   ```powershell
   supabase login
   supabase link --project-ref <project-ref>
   supabase db push
   ```

   This single baseline creates the sharing tables and RLS policies, enables
   individual card access per player, a private `shared-card-icons` bucket with
   a 5 MiB per-image limit, enforces a 100,000-byte shared-payload limit, and
   publishes ID-only card-access/revocation events. Player queries cannot read
   cards or icons unless the DM has granted access or after access is revoked.
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
the app. A DM must register/sign in with an email account or Google before
creating campaigns. Players receive the displayed join code or player link from the DM.
Use the people icon beside a campaign to choose which connected players can
see each card shared to that campaign. When sharing a card for the first time,
the app asks which players should receive it. New players do not automatically
receive previously shared cards; grant access from the campaign or card screen.

Select an active campaign before opening **Initiative Tracker**. Tracker
changes are published to that campaign in real time. New combatants default to
**Limited** visibility; use the visibility icon on each row to choose Hidden,
Limited, or Full. Hidden combatants are omitted entirely. Limited shares name,
initiative, current-turn marker, and a health label. Full additionally shares
exact HP, exhaustion, concentration, reaction state, capacity, and cooldowns.
The shared encounter stays available to players until the DM uses **End
combat**. The tracker's full DM state remains in memory only and is not restored
after restarting the desktop app.

## Run the player web app

The web player has its own entry point (`lib/player/main.dart`). It imports no
SQLite or `dart:io` code from the desktop app.

```powershell
flutter run -d chrome -t lib/player/main.dart `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_KEY=<anon-or-publishable-key>
```

Player auth sessions and the last-viewed card versions are stored in the
browser, so a refresh keeps a joined player's session and campaign. Build a
release bundle with:

```powershell
flutter build web --release -t lib/player/main.dart `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_KEY=<anon-or-publishable-key>
```

The generated static site is in `build/web`. Deploy its contents to any static
host that serves `index.html` for the site root. For a subdirectory deployment,
set the matching base path, for example `--base-href /cards/`, when building.
The player link uses a hash route, so normal refreshes remain at the site root.
Pass the same player URL to the DM app as `PLAYER_WEB_URL`, or set it in the DM
app's sharing settings.

## Deploy the player app to Cloudflare Workers

The root `wrangler.jsonc` configures the Worker named `dnd-cuecard-app` to
serve the Flutter build in `build/web`. Build the web app with the Supabase
project URL and publishable key, then deploy from the repository root with
Wrangler:

```powershell
flutter build web --release -t lib/player/main.dart `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_KEY=<anon-or-publishable-key>
npx wrangler deploy
```

The GitHub Actions workflow at `.github/workflows/deploy.yml` builds the player
entry point and deploys it whenever code is pushed to `main`; you can also run
it manually with **Actions → Deploy to Cloudflare Workers → Run workflow**.
Configure these values in the repository's **Settings → Secrets and variables
→ Actions**:

- Repository variables: `SUPABASE_URL` and `SUPABASE_KEY` (the public
  publishable/anon key).
- Repository secrets: `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.

The Cloudflare API token needs permission to deploy Workers for the target
account. The publishable key is public client configuration; never put a
Supabase service-role key in a GitHub variable, secret, or web build.

### Google OAuth redirect setup

Add the player site's origin (for example, `https://cards.example.com`) to
Supabase **Authentication → URL Configuration → Redirect URLs**. Configure
the Google OAuth client's authorized redirect URI as
`https://<project-ref>.supabase.co/auth/v1/callback`. For the packaged Windows
DM app, build/install the MSIX package so the `dndcuecard://login-callback`
protocol is registered; allow that URI in Supabase's redirect URL list.
Google OAuth is opened in the system browser, and the callback is forwarded to
the running desktop app if one is already open.

## Tests and RLS verification

Run the automated suite and static analysis with:

```powershell
flutter test
flutter analyze
```

The SQL RLS check in `supabase/tests/sharing_rls_test.sql` uses simulated
authenticated JWT subjects and rolls back its fixtures. Run it only against a
disposable Supabase test project/database after applying
`supabase/migrations/0001_sharing.sql`.

For checks against actual authenticated client sessions, provision two
dedicated test DM accounts and two registered player accounts with
email/password sign-in enabled, and set the following environment variables
in PowerShell. The live test creates and
deletes temporary campaigns; do not point it at production data.

```powershell
$env:SUPABASE_TEST_URL = 'https://<project-ref>.supabase.co'
$env:SUPABASE_TEST_ANON_KEY = '<anon-or-publishable-key>'
$env:SUPABASE_TEST_DM_EMAIL = '<first-test-dm-email>'
$env:SUPABASE_TEST_DM_PASSWORD = '<first-test-dm-password>'
$env:SUPABASE_TEST_OTHER_DM_EMAIL = '<second-test-dm-email>'
$env:SUPABASE_TEST_OTHER_DM_PASSWORD = '<second-test-dm-password>'
$env:SUPABASE_TEST_PLAYER_EMAIL = '<first-test-player-email>'
$env:SUPABASE_TEST_PLAYER_PASSWORD = '<first-test-player-password>'
$env:SUPABASE_TEST_OTHER_PLAYER_EMAIL = '<second-test-player-email>'
$env:SUPABASE_TEST_OTHER_PLAYER_PASSWORD = '<second-test-player-password>'
flutter test test/sharing_rls_live_test.dart
```

Without all ten environment variables, it is skipped. It verifies
campaign-owner isolation, member/non-member reads, player write denial, DM
member removal, initiative read-only access, revoke visibility/events, and
rejection of oversized payloads. Run it after every policy or migration change
and before inviting players.
