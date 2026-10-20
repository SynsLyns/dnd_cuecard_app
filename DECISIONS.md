# Architecture & Implementation Decisions

This document tracks technical decisions and defaults agreed upon during the implementation of Persistent Card Sharing and the Live Player View.

---

## 1. Card Sharing (DM to Players)

- **Backend:** Supabase (Postgres, Auth, Realtime).
- **Source of Truth:** DM's local SQLite database remains the sole source of truth. Publishing is one-way (copy pushed to cloud; no two-way sync).
- **Campaign as Durable Unit:** Sharing is scoped to a `Campaign` (with DM owner, members, and shared cards).
- **Snapshot Sharing:** Updates are explicit snapshots pushed by the DM via a "Push update" button. Players' cards do not silently mutate.
- **Player Auth:** Every DM and player must use a registered email/password or Google account. The player adds a display name when joining with a campaign code. Anonymous authentication is disabled.
- **Card Fields in Shared Payload:**
  - `notes`: **Included** (confirmed by human).
  - `iconFilePath`: Local paths are not shared. The DM uploads the image to the private Supabase Storage bucket; the player downloads it only when granted card access.
  - `relationship`: **Omitted for v1** (confirmed by human).
  - `player edits`: **Read-only** (players cannot modify cards; player notes deferred).
  - `box1` / `box2`: **Included** as free text.
  - `type` & `rarity`: The local database stores dynamic IDs referencing `card_types` and `rarities` tables (with custom names and ARGB32 colors). For v1 sharing, the payload will include resolved names/colors or metadata alongside the ID so player apps can accurately render the styling without local SQLite lookup tables.

---

## 2. Initiative Tracker Sharing (Phase 7 Defaults)

- **Local Persistence:** `InitiativeAppState` is currently 100% in-memory in the desktop app.
- **Combatant Visibility:** Three levels: `hidden` (never shared), `limited` (health status label only: Healthy/Bloodied/Near Death/Down, no exact HP), `full` (exact HP/maxHp, exhaustion, cooldowns). Default for new items: `limited`.
- **Toggles & Cooldowns:**
  - `toggleState`: Labeled as **Concentration** (orange circle). Shown to players for `full` combatants only.
  - `cd1State`: Labeled as **Reaction Used** (blue circle). Shown to players for `full` combatants only.
  - `capacity`, `cooldown`, `cooldownTimers`: Shown to players for `full` combatants only.
  - `exhaustion`: Shown to players for `full` combatants only.
- **Encounter State Duration:** Tracker state stays in Supabase until the DM ends combat or explicitly clears it.
- **Hidden Combatant Turn:** When the current turn belongs to a `hidden` combatant, no highlight is shown to players.
- **Local Persistence:** Confirmed in-memory only in desktop DM app.
