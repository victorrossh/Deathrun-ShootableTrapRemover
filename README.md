# Shoot Breakable Traps Deathrun  
### AMX Mod X Plugin

**Version:** 1.0  
**Author:** ftl~  

This plugin automatically removes **shootable** `func_breakable` entities from maps during map load.

---

## Features

- Scans all `func_breakable` entities shortly after map load
- Removes only **shootable** breakables
- Preserves **trigger-only** breakables (`spawnflag 1 = Only Trigger`)
- One-time removal per map load (no per-round processing)
- Debug mode with detailed logs and chat messages
- Uses **CromChat2** for clean, prefixed, and colored chat output

---

## How It Works

1. On map load (`plugin_cfg()`), the plugin waits **5 seconds** to ensure all entities are fully spawned
2. Iterates through every entity with classname `func_breakable`
3. Reads the entity spawnflags:
   - `flags & 1` → **Only Trigger** → entity is preserved
   - `!(flags & 1)` → **Shootable** → entity is collected and removed
4. Displays scan statistics **only when debug mode is enabled**

---

## Important Behavior

> Entity removal is **permanent for the entire map duration**

The plugin uses `remove_entity()`, which **completely deletes** the entity from the GoldSrc engine entity list.

- The map BSP is **not reloaded** on round restart
- Removed entities **will not reappear** in future rounds

This plugin is intentionally designed for **one-time execution per map load**.

---

## Debug Mode

To enable debug mode, add `debug` next to the plugin name in `plugins.ini`:

`shoot_breakable.amxx debug`

### Debug output includes:

- Per-entity logs in the server console  
  (`[DEBUG TRAPS] ...`)
- Summary messages in chat after the scan

**Example chat output:**

```
[FWO] Scan finished: 7 total breakables, 6 shootable, 6 removed.
[FWO] 6 shootable breakables removed successfully!
```

---

## Notes & Limitations

- Removal is **permanent per map**
- Removed entities cannot be restored during round restarts
- No admin commands included — removal is fully automatic
- The default 5-second delay can be adjusted in `set_task()` if needed

---

## Possible Improvements (TODO)

- Add a CVAR to enable or disable automatic removal  
  Example: `amx_remove_shootable 1/0`

- If automatic removal is disabled, add a manual admin command to trigger the removal logic.

- Replace `remove_entity()` with a **non-destructive approach** when round-based restoration is desired.  
Instead of permanently deleting entities, hide them by changing properties such as:
- `pev_solid = SOLID_NOT`
- `pev_renderamt = 0.0`

This method does **not remove** the entity from memory, allowing it to be restored when the round restarts.

- When using a CVAR-based system with the hiding approach:
  - Hook `EventNewRound`
  - On each new round, check if the automatic removal CVAR is enabled
  - If enabled, re-apply the hiding logic (`pev_solid`, `pev_renderamt`, etc.)

Without handling `EventNewRound`, the engine will reset these properties and the entity will become visible and solid again, even if the CVAR remains enabled.

- Support restoring shootable breakables per round.

  This requires changing the removal method.
  Entities removed with `remove_entity()` cannot be restored, since they are permanently deleted from memory and the map is not reloaded on round restart.