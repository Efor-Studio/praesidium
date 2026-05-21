# praesidium

`Zombie Siege: Praesidium` is a server-authoritative Roblox wave-defense prototype for a 3-player co-op loop built around three lanes, a shared core, and a Matter-first ECS structure.

## Tooling

This project now expects:

```bash
rokit install
wally install
rojo serve
```

`Matter` is managed through `Wally`, and `Rojo` syncs both `src/` and the generated `Packages/` folder into Studio.

## Current V1 Scaffold

- Shared content is fully data-driven under [`src/shared/Config`](./src/shared/Config).
- Shared API contracts and validators live under [`src/shared/Networking`](./src/shared/Networking) and [`src/shared/Validation`](./src/shared/Validation).
- The server owns match flow, loadouts, rewards, build validation, and replication under [`src/server`](./src/server).
- The client bootstrap under [`src/client`](./src/client) now renders a placeholder HUD for lanes, squad state, rewards, build actions, and concept cards while still auto-submitting the default bootstrap loadout.
- If `Matter` has not been installed yet, the server falls back to a heartbeat scheduler and emits a system notice in Studio.

## Main Gameplay Defaults

- 1 map: `Praesidium Outskirts`
- 1 mode: `Standard`
- 15 waves
- 4 classes: `Gunner`, `Mage`, `Priest`, `Thief`
- 3 equipped skills plus 1 fixed ultimate
- Universal build menu: `Turret`, `Barricade`, `UtilityNode`

## Next Good Steps

- Upgrade the placeholder HUD into a production-quality loadout, reward, and build flow with polished art, feedback, and input handling.
- Turn simulated wave/lane pressure into live enemies, pickups, projectiles, and health systems.
- Add map geometry, lane sockets, and actual authoritative build placement on world anchors.
