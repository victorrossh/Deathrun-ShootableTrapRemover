# Remove Interactive Breakables
#### AMX Mod X Plugin

---

## Credits
- **ftl~** 
- **Mrshark45**

---

#### This plugin automatically removes **interactive** `func_breakable` entities from maps during map load.

---

## Features

- Scans all `func_breakable` entities shortly after map load
- Removes only **interactive** breakables
- Preserves **trigger-only** breakables (`spawnflag SF_BREAK_TRIGGER_ONLY`)
- One-time removal per map load (no per-round processing)
- Debug mode with detailed logs and chat messages
- Uses **CromChat2** for clean, prefixed, and colored chat output

---

## How It Works

1. On map load (`plugin_cfg()`), the plugin waits **5 seconds** to ensure all entities are fully spawned.
2. Iterates through every entity with classname `func_breakable`.
3. Reads the entity spawnflags:  
   https://github.com/ValveSoftware/halflife/blob/b1b5cf5892918535619b2937bb927e46cb097ba1/dlls/util.h#L440C1-L444C66
   ```
   // func breakable
   #define SF_BREAK_TRIGGER_ONLY  1   // may only be broken by trigger
   #define SF_BREAK_TOUCH         2   // can be 'crashed through' by running player (plate glass)
   #define SF_BREAK_PRESSURE      4   // can be broken by a player standing on it
   #define SF_BREAK_CROWBAR       256 // instant break if hit with crowbar
    ```

4. Breakables are classified based on their spawnflags:

   * `flags & (SF_BREAK_TOUCH | SF_BREAK_PRESSURE | SF_BREAK_CROWBAR)`
     → **Player-interactive breakable** (touch / pressure / crowbar)
     → entity is collected and removed
   * No interactive flags set
     → **Non-interactive breakable** (trigger-only or otherwise indestructible by players)
     → entity is preserved
5. Displays scan statistics **only when debug mode is enabled**.

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
[FWO] Scan finished: 7 total breakables, 4 interactive.
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
  Example: `amx_remove_breakables 1/0`

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