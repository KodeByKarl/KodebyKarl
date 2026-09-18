# cfx-keydi-lockscript

Exclusive appearance / clothing permission locks for **cfx-keydi-ui**.

Admins can lock specific ped component values (drawables, props, hair, eye color, tattoos, etc.) so only the owner — or players on the shared list — can equip them. Everyone else sees them as locked in the appearance menu (after a one-line illenium hook) and is blocked server-side on save.

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- ESX Legacy **or** QBCore (auto-detected), or `standalone`

## Command

```
/viplock
```

Opens the VIP Lock side panel (NUI inside `cfx-keydi-ui`).

## ACE permission

Grant staff access via ACE (recommended) and/or staff groups in `shared/config.lua`.

```cfg
# server.cfg
add_ace group.admin command.viplock allow
add_principal identifier.license:YOUR_LICENSE_HERE group.admin
```

`ConfigLockScript.AcePermission` defaults to `command.viplock`.

Staff groups (ESX/QB) also allowed by default: `admin`, `superadmin`, `owner`, `developer`.

## Database

Table `keydi_locks` is **auto-created on resource start** if missing.

Manual SQL (optional):

```sql
CREATE TABLE IF NOT EXISTS `keydi_locks` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `category` VARCHAR(50) NOT NULL,
    `component_id` VARCHAR(64) NOT NULL,
    `drawable` INT NOT NULL DEFAULT 0,
    `texture` INT NOT NULL DEFAULT 0,
    `gender` VARCHAR(10) NOT NULL DEFAULT 'male',
    `owner_identifier` VARCHAR(64) NOT NULL,
    `owner_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `shared_identifiers` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_keydi_locks_lookup` (`category`, `component_id`, `drawable`, `texture`, `gender`),
    KEY `idx_keydi_locks_owner` (`owner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Server exports

Resource name when embedded: **`cfx-keydi-ui`**

```lua
exports['cfx-keydi-ui']:IsLocked(category, componentId, drawable, texture, gender)
-- -> boolean, lockRow|nil

exports['cfx-keydi-ui']:CanUse(identifier, category, componentId, drawable, texture, gender)
-- -> boolean

exports['cfx-keydi-ui']:AddLock(data)           -- -> success, lockId
exports['cfx-keydi-ui']:RemoveLock(lockId)      -- -> success
exports['cfx-keydi-ui']:GrantAccess(lockId, identifier)
exports['cfx-keydi-ui']:RevokeAccess(lockId, identifier)
exports['cfx-keydi-ui']:GetLocksByCategory(category)
exports['cfx-keydi-ui']:GetAllLocks()
exports['cfx-keydi-ui']:ValidateAppearance(source, appearance)
```

## Illenium-appearance visual lock hook (required for bold/disabled UI)

Core logic is **not** hard-coupled to illenium. Visual locking needs a one-line call when the clothing menu opens.

**File:** `illenium-appearance/client/client.lua`  
**Function:** `OpenShop` (and/or wherever `client.startPlayerCustomization` is called)

After you know the ped gender (`"male"` / `"female"`), add:

```lua
local lockedItems = exports['cfx-keydi-ui']:GetLockedListForNUI(gender)
-- Pass lockedItems into your NUI appearance config / SendNUIMessage payload
-- so Vue can mark matching drawable rows as bold + disabled with tooltip:
--   "Exclusive to <owner_name>"
```

Optional pre-save guard (same file, inside the customization callback):

```lua
client.startPlayerCustomization(function(appearance)
    if appearance then
        local allowed = exports['cfx-keydi-ui']:ValidateAppearanceBeforeSave(appearance)
        if not allowed then return end
        TriggerServerEvent("illenium-appearance:server:saveAppearance", appearance)
    end
end, config)
```

Without the optional pre-save patch, the **server still rejects** unauthorized saves and reverts the skin.

## Folder layout

```
Module/cfx-keydi-lockscript/
  shared/config.lua
  server/locks.lua
  server/main.lua
  client/main.lua
  client/adapter_illenium.lua
  README.md

web/src/cfx-keydi-lockscript/
  LockMenu.tsx
```

## Config notes

- `ConfigLockScript.Framework` = `'auto' | 'esx' | 'qbcore' | 'standalone'`
- Categories in `shared/config.lua` mirror illenium components / props / overlays / tattoo zones.
- For **tattoos**, set the tattoo name (e.g. `TAT_AR_000`) in the Add Lock modal override field; `drawable`/`texture` stay `0`.

## Rebuild NUI

After changing `LockMenu.tsx`:

```bash
cd resources/[CFX-SCRIPTS]/cfx-keydi-ui/web
npm install
npm run build
```
