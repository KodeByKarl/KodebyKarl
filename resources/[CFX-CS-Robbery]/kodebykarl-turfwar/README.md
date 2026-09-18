# kodebykarl-turfwar

Modern Sequence Turf War System for GrimCity Roleplay (ESX / ox_lib / ox_inventory / ox_target).

## Features
- **Sequence War Countdown**: Initiates a server-managed war sequence timer per turf location.
- **Trigger Spot Reward Claim**: Upon timer reaching 00:00, a loot bag prop spawns right at the trigger location. Winning gang claims rewards right where the turf war was started!
- **Strict Server-Side Validation**: Distance checks, gang eligibility, member count validation, item distribution, and cooldown enforcement are handled 100% server-side.
- **Dynamic Turf Zone Boundaries & Penalty**: Outside boundary detection drains player HP if they leave the zone during an active war.
- **Scoreboard & HUD Integration**: Automatically updates active events and robberies in `cfx-keydi-ui`.
- **Discord Webhooks**: Full logging for turf initiation and reward claims.

## Installation
Add `ensure kodebykarl-turfwar` to your `server.cfg` under `[GRIM-ROBBERY]`.
