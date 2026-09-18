# kodebykarl-projectcars

Build a driveable car from a wrecked shell. Players place a `vehicle_shell`, install unique parts (engine, transmission, suspension, body frame, tires, doors, windows), then the finished vehicle is stored in their garage.

**Framework:** ESX Legacy  
**Inventory:** ox_inventory  
**SQL:** oxmysql  

## Features

- Unique per-vehicle parts (`charger_engine`, `civic_tires`, …)
- 3D install points on the wreck (doors / wheels / windows)
- Blueprint cost to start a project
- Parts box + full starter (ayuda) box
- Auto SQL table on first start
- Admin `/giveshell` and `/destroyprojectcar`

## Install

Full steps for another server: **[install/README.md](install/README.md)**

```
install/
  sql/install.sql                      ← import once
  ox_inventory/items.lua               ← merge into ox_inventory/data/items.lua
  ox_inventory/project_car_items.lua   ← drop into ox_inventory/data/
  ox_inventory/shared_snippet.lua      ← paste into ox_inventory items loader
  ox_inventory/images/                 ← optional icons
```

## Dependencies

- es_extended
- ox_lib
- ox_inventory
- oxmysql
- OneSync Infinity
