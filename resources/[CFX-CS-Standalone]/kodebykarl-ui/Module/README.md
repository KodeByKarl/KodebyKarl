# cfx-keydi-ui

A premium, modern FiveM character identity registration resource integrated with **ESX Legacy**, featuring a highly responsive, custom-built React and Tailwind CSS v4 UI.

## Project Structure
- **`cfx-keydi-identity/`**: Contains the client, server, and shared core ESX script logic.
- **`web/`**: Contains the frontend React SPA, which builds into `web/dist/`.
- **`fxmanifest.lua`**: The root manifest file that registers both the CEF UI page and the scripts inside the `cfx-keydi-identity/` subdirectory.

## Features
- **Modern UI/UX**: Custom dark mode, elegant blur gradients, micro-animations, custom dropdown lists, and fully responsive layout.
- **ESX Legacy Integration**: Connects seamlessly with standard ESX identity server callbacks and events.
- **Form Validations**: Built-in validation checks (character length, age boundaries, height constraints) implemented both frontend and backend for enhanced security.
- **Test Commands**: Handy in-game debugging commands `/register` and `/closereg` (toggleable via `cfx-keydi-identity/shared/config.lua`).

## Installation

1. Copy the `cfx-keydi-ui` folder into your server's `resources/[CFX-SCRIPTS]/` directory.
2. Disable/remove standard `esx_identity` to avoid conflicting callback and event registrations.
3. Add the resource to your `server.cfg`:
   ```cfg
   ensure cfx-keydi-ui
   ```
4. If you modify any frontend code, rebuild the UI:
   ```bash
   cd web
   npm install
   npm run build
   ```

## Configuration

Customize settings in `cfx-keydi-identity/shared/config.lua`:
- `Config.Debug`: Toggles debug logs and testing commands.
- `Config.MinHeight` / `Config.MaxHeight`: Sets valid character height range in cm.
- `Config.LowestYear` / `Config.HighestYear`: Restricts birth years.
