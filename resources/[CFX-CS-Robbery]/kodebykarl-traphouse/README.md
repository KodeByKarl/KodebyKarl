# kodebykarl-traphouse

Ultra-Secured Unli TrapHouse & RedZone System for GrimCity Roleplay (ESX / ox_lib / ox_inventory).

## Key Improvements & Anti-Cheat Features
- **100% Server-Side Kill Validation**: Eliminates client-side reward trigger exploits. Rewards are computed strictly when `esx:onPlayerDeath` / `baseevents:onPlayerKilled` fires on the server.
- **Anti-Farm Cooldown**: Prevents repeated farming between two players within a configurable time window (`Config.AntiFarmCooldown`).
- **Server-Side Distance Check**: Verifies killer entity coordinates directly on the server inside `Config.TrapZones`.
- **Weighted Loot Tables**: Item drops (`ox_inventory:AddItem`) are dynamically generated on the server using chance-based tables.
- **Discord Webhook Logging**: Logs all kills, killer/victim names, server IDs, gang affiliations, and items rewarded.
