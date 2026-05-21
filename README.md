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
- The runtime now generates a blockout battlefield with placeholder lanes, gates, core, starter defenses, enemy blocks, and build slots so the wave loop is watchable in-world.
- The client bootstrap under [`src/client`](./src/client) stays lightweight: it auto-submits the default loadout and exposes a compact debug overlay plus hotkeys for lane focus, skills, ultimates, and build placement.
- If `Matter` has not been installed yet, the server falls back to a heartbeat scheduler and emits a system notice in Studio.

## Main Gameplay Defaults

- 1 map: `Praesidium Outskirts`
- 1 mode: `Standard`
- 15 waves
- 4 classes: `Gunner`, `Mage`, `Priest`, `Thief`
- 3 equipped skills plus 1 fixed ultimate
- Universal build menu: `Turret`, `Barricade`, `UtilityNode`

## Next Good Steps

- Replace the blockout parts with stronger environment art, placeholder rigs, and clearer lane silhouettes without changing the simulation hooks.
- Expand the combat sandbox with pickups, projectiles, lane-specific world telegraphs, and more visible build/skill feedback.
- Upgrade the debug overlay into a production-quality loadout, reward, and build flow once the core MVP feel is locked in.
