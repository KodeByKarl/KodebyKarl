# NameChecker (cfx-keydi-utils)

Verifies a player's **FiveM display name** matches their **Discord nickname** (or username) and enforces **Gang & Job Tags** before they can join. Framework-agnostic; runs on `playerConnecting` with deferrals.

Config: `configs/namechecker.lua`  
Logic: `modules/namechecker/server.lua`

---

## Features

1. **Exact Discord Nickname Matching**:
   - Ensures the player's FiveM name matches their Discord server nickname.
2. **Gang & Job Tag Enforcement**:
   - Detects tags formatted as `[TAG] Name`, `(TAG) Name`, `{TAG} Name`, `TAG | Name`, etc.
   - Validates that the tag belongs to the server's registered whitelist (e.g. `[PCPD]`, `[PCMD]`, `[PCMECH]`, `[ACES]`, `[KTG]`, `[CIV]`).
3. **Role-Based Tag Verification**:
   - Optional: Map Discord Role IDs to required tags. If a player has the Discord Police role, their name MUST have `[PCPD]`. If they have the Smokin Aces role, their name MUST have `[ACES]`.

---

## Discord Bot Setup

1. Open the [Discord Developer Portal](https://discord.com/developers/applications) → **New Application** → **Bot**.
2. Copy the bot token into `BotToken`.
3. Under **Privileged Gateway Intents**, enable **Server Members Intent** (required for guild member and role lookups).
4. Invite the bot to your Discord (OAuth2 URL Generator → scopes: `bot`).
5. Put the bot in the same guild as your players.

---

## Config Options (`configs/namechecker.lua`)

| Option | Purpose |
|--------|---------|
| `Enabled` | Master switch for the module |
| `BotToken` / `GuildID` | Discord API auth + server ID |
| `TagVerification.Enabled` | Enable Gang & Job Tag validation |
| `TagVerification.RequireTag` | If `true`, all players (including civilians) must have a tag (e.g. `[CIV]`) |
| `TagVerification.AllowedTags` | Table of valid gang and job tags |
| `TagVerification.RoleTags` | Map Discord Role IDs to specific required tags |
| `CaseInsensitive` | Case-insensitive name and tag comparison |
| `TrimSpaces` | Ignore leading/trailing spaces |
| `RequireGuildMembership` | Reject players who are not in your Discord server |
| `Messages.*` | Player-facing connection deferral messages |

---

## Examples

- **Valid Police**: Discord `[PCPD] Keydi yamaguchi` ➔ FiveM `[PCPD] Keydi yamaguchi` ➔ **Connected**
- **Valid Gang**: Discord `[ACES] John Doe` ➔ FiveM `[ACES] John Doe` ➔ **Connected**
- **Invalid Tag**: Discord `[UNKNOWN] Keydi` ➔ **Rejected** (*Tag [UNKNOWN] is not registered*)
- **Role Mismatch**: Player has Police Discord Role but nickname is `[CIV] Keydi` ➔ **Rejected** (*You have the Police role; must use [PCPD]*)
- **Name Mismatch**: Discord `[PCPD] Keydi` ➔ FiveM `Keydi` ➔ **Rejected** (*Set FiveM name to match Discord*)
