#if defined _smrespawn_included_
  #endinput
#endif
#define _smrespawn_included_

/**
 * Respawns the player.
 *
 * @param iTarget		Target who you want to respawn.
 * @param iClient		(optional) Specify it if you want to respawn target on this client's crosshair.
 * @param vOrigin[3]	(optional) Position where you want target to be spawned.
  *
 * @error				Wrong number of arguments.
 * @return				true, if target is successfully respawned.
 * @note				If both optional arguments are omitted target is respawned at spawn point (saferoom).
 */
native int SM_Respawn(int iTarget, int iClient = 0, float vOrigin[3] = {99999.0, 99999.0, 99999.0});

public SharedPlugin __pl_smrespawn =
{
	name = "[L4D & L4D2] SM Respawn",
	file = "l4d_sm_respawn.smx",
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_smrespawn_SetNTVOptional()
{
	MarkNativeAsOptional("SM_Respawn");
}
#endif