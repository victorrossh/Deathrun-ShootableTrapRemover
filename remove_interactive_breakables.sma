// NOTE:
// This code can be further improved depending on the project needs.
// For example, a CVAR could be added to control whether the entity should be removed automatically or not.
// If automatic removal is disabled, a manual removal command could be implemented instead.
//
// However, to support restoring the entity when a new round starts, the removal system would need to be changed.
// In that case, this approach of permanently removing the entity from memory should not be used.
// A different method must be implemented—one that allows the entity to be recreated/restored when a new round start.
// 
// This is only necessary if the desired behavior is to have the entity restored at the beginning of each round.

#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cromchat2>

#define PLUGIN   "Remove Interactive Breakables"
#define VERSION  "1.0"
#define AUTHOR   "ftl~ & MrShark45"

#define DESTROY_TIME 5.0

#pragma semicolon 1

// Debug
new g_bDebugMode;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	//register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");

	g_bDebugMode = bool:(plugin_flags() & AMX_FLAG_DEBUG);

	CC_SetPrefix("&x04[FWO]");
}

public plugin_cfg() {
	set_task(DESTROY_TIME, "RemoveBreakables");
}

// There is no need to check on the EventNewRound event.
// According to the documentation, when remove_entity(ent) is called, the GoldSrc engine
// permanently removes the entity from the map for the entire duration of the current map.
//
// This happens because:
// - func_breakable is a static entity created when the map is loaded
// - remove_entity() does not just kill the entity; it completely deletes it from the map entity list
// - When a new round starts, the server does not reload the map from scratch;
//
// Since the entity is removed from memory, it will not be restored in the next round.

/*public EventNewRound() {	
	set_task(1.0, "RemoveBreakables");
}*/

public RemoveBreakables() {
	new total_break = 0;
	new Array:to_remove = ArrayCreate(); // Collects all entities that need to be removed.
	new ent = -1;

	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_breakable")) > 0) {
		total_break++;
		
		new flags = pev(ent, pev_spawnflags);
		
		if(g_bDebugMode) {
			new Float:health; pev(ent, pev_health, health);
			new targetname[32]; pev(ent, pev_targetname, targetname, charsmax(targetname));
			server_print("[DEBUG TRAPS] Entity %d | flags=%d (OnlyTrigger=%s) | health=%.0f | targetname=%s",
				ent, flags, (flags & 1) ? "YES" : "NO", health, targetname[0] ? targetname : "<none>");
		}
		
		// Breakables that can be destroyed by player interaction are removed.
		// This includes breakables that can be broken by touch, pressure, or crowbar
		// (SF_BREAK_TOUCH / SF_BREAK_PRESSURE / SF_BREAK_CROWBAR).
		// Trigger-only breakables (SF_BREAK_TRIGGER_ONLY) are excluded, as they
		// ignore player damage and can only be broken via triggers.
		if (flags & (SF_BREAK_TOUCH | SF_BREAK_PRESSURE | SF_BREAK_CROWBAR)) {
			ArrayPushCell(to_remove, ent);
		}

	}

	// Removes everything that was collected.
	new size = ArraySize(to_remove);
	for(new i = 0; i < size; i++) {
		ent = ArrayGetCell(to_remove, i);
		if(pev_valid(ent)) {
			remove_entity(ent);
		}
	}

	ArrayDestroy(to_remove);
	
	// Debug messages
	if (g_bDebugMode) {
		CC_SendMessage(0, "Scan finished: &x04%d &x01total breakables, &x04%d &x01interactive.", total_break, size);

		if (total_break == 0)
			CC_SendMessage(0, "No &x04func_breakable &x01entities found on the map.");
		else if (size == 0)
			CC_SendMessage(0, "All breakables are non-interactive (trigger-only or indestructible), nothing removed.");
	}
}