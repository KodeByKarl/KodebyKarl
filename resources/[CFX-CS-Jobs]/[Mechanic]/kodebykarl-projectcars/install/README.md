# Installation

Drop `kodebykarl-projectcars` in your resources folder, then run these steps on a **fresh** server.

## 1. Dependencies

Ensure these start **before** this resource:

```
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure ox_inventory
ensure kodebykarl-projectcars
```

## 2. SQL

Import `install/sql/install.sql` (HeidiSQL / phpMyAdmin).

The table is also created automatically on first resource start, so this step is optional if oxmysql is already connected.

## 3. ox_inventory items

### Core items
Open `ox_inventory/data/items.lua` and merge every entry from:

```
install/ox_inventory/items.lua
```

Do **not** replace the whole items file — copy the four keys (`vehicle_shell`, `car_blueprint`, `project_parts_box`, `project_ayuda_box`).

### Unique parts (one item per vehicle + part)
Copy:

```
install/ox_inventory/project_car_items.lua
```

to:

```
ox_inventory/data/project_car_items.lua
```

Then paste the loop from `install/ox_inventory/shared_snippet.lua` into `ox_inventory/modules/items/shared.lua` **after** the existing `data.items` loop.

### Images (optional)
See `install/ox_inventory/images/README.md`. Copy icons into `ox_inventory/web/images/`.

Restart `ox_inventory` after adding items.

## 4. Config

Edit `config.lua`:

- `Config.Vehicles` — spawncodes, labels, inventory prefixes
- `Config.GarageId` — garage the finished car is stored in
- `Config.BlueprintAmount` — blueprints required to place a shell (default 25)

If you add a new vehicle, add a matching prefix in `install/ox_inventory/project_car_items.lua` (or your live `data/project_car_items.lua`) and restart ox_inventory.

## 5. Commands

| Command | Who | What |
|---|---|---|
| `/giveshell [id] [model]` | admin | Give a vehicle shell |
| `/destroyprojectcar` | owner / admin | Delete the nearest project |

## Support

KodeByKarl — GrimCity / kodebykarl-projectcars
