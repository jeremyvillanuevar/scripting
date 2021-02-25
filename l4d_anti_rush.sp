/*
*	Anti Rush
*	Copyright (C) 2020 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.8"
#define DEBUG_BENCHMARK		0			// 0=Off. 1=Benchmark logic function.

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Anti Rush
*	Author	:	SilverShot
*	Descrp	:	Slowdown or teleport rushers and slackers back to the group. Uses flow distance for accuracy.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=322392
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.8 (09-Oct-2020)
	- Changed cvar "l4d_anti_rush_finale" to allow working in Gauntlet type finales only. Thanks to "Xanaguy" for requesting.
	- Renamed cvar "l4d_anti_rush_inacpped" to "l4d_anti_rush_incapped" fixing spelling mistake.

1.7 (09-Oct-2020)
	- Added cvar "l4d_anti_rush_tanks" to control if the plugins active when any tank is alive.
	- Fixed not resetting slowdown on team change or player death (optimization).

1.6 (15-Jul-2020)
	- Optionally added left4dhooks forwards "L4D_OnGetCrouchTopSpeed" and "L4D_OnGetWalkTopSpeed" to modify speed when walking or crouched.
	- Uncomment the section and recompile if you want to enable. Only required to slowdown players more than default.
	- Thanks to "SilentBr" for reporting.

1.5 (10-May-2020)
	- Added Traditional Chinese and Simplified Chinese translations. Thanks to "fbef0102".
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.4 (10-Apr-2020)
	- Added Hungarian translations. Thanks to "KasperH" for providing.
	- Added Russian translations. Thanks to "Dragokas" for updating with new phrases.
	- Added cvar "l4d_anti_rush_incapped" to ignored incapped players from being used to calculate rushers or slackers distance.
	- Added cvars "l4d_anti_rush_warn_last" and "l4d_anti_rush_warn_lead" to warn players about being teleported or slowed down.
	- Added cvar "l4d_anti_rush_warn_time" to control how often someone is warned.
	- Removed minimum value being set for "l4d_anti_rush_range_lead" cvar which prevented turning off lead feature.
	- The cvars "l4d_anti_rush_range_last" and "l4d_anti_rush_range_lead" minimum values are now set internally (1500.0).
	- Translation files and plugin updated.

1.3 (09-Apr-2020)
	- Added reset slowdown incase players are out-of-bound or have invalid flow distances to calculate the range.
	- Increased minimum value of "l4d_anti_rush_range_lead" cvar from 500.0 to 1000.0.
	- Removed minimum value being set for "l4d_anti_rush_range_last" cvar. Thanks to "Alex101192" for reporting.

1.2 (08-Apr-2020)
	- Added cvar "l4d_anti_rush_finale" to allow or disallow the plugin in finales.

1.1 (07-Apr-2020)
	- Changed how the plugin functions. Now calculates rushers/slackers by their flow distance to the nearest half of Survivors.
	- Fixed not accounting for multiple rushers with "type 2" setting.
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.0 (26-Mar-2020)
	- Added Russian translations to the .zip. Thanks to "KRUTIK" for providing.
	- No other changes.

1.0 (26-Mar-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#if DEBUG_BENCHMARK
#include <profiler>
Handle g_Prof;
float g_fBenchMin;
float g_fBenchMax;
float g_fBenchAvg;
float g_iBenchTicks;
#endif

#define CVAR_FLAGS			FCVAR_NOTIFY
#define MINIMUM_RANGE		1500.0			// Minimum range for last and lead cvars.
#define MINIMUM_WARN		1000.0			// Minimum range for warn cvars.
#define MAX_COMMAND_LENGTH 512

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarFinale, g_hCvarIncap, g_hCvarPlayers, g_hCvarRangeLast, g_hCvarRangeLead, g_hCvarSlow, g_hCvarTank, g_hCvarText, g_hCvarTime, g_hCvarType, g_hCvarWarnLast, g_hCvarWarnLead, g_hCvarWarnTime;
float g_fCvarRangeLast, g_fCvarRangeLead, g_fCvarSlow, g_fCvarTime, g_fCvarWarnLast, g_fCvarWarnLead, g_fCvarWarnTime;
int g_iCvarFinale, g_iCvarIncap, g_iCvarPlayers, g_iCvarTank, g_iCvarText, g_iCvarType;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;

bool g_bInhibit[MAXPLAYERS+1];
float g_fHintLast[MAXPLAYERS+1];
float g_fHintWarn[MAXPLAYERS+1];
float g_fLastFlow[MAXPLAYERS+1];
Handle g_hTimerAntiRushHuman;
//Handle g_hTimerAntiRushBot;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Anti Rush",
	author = "SilverShot",
	description = "Slowdown or teleport rushers and slackers back to the group. Uses flow distance for accuracy.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=322392"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("anti_rush.phrases");

	g_hCvarAllow =		CreateConVar(	"l4d_anti_rush_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_anti_rush_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_anti_rush_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_anti_rush_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarFinale =		CreateConVar(	"l4d_anti_rush_finale",			"2",				"Should the plugin activate in finales. 0=Off. 1=All finales. 2=Gauntlet type finales.", CVAR_FLAGS );
	g_hCvarIncap =		CreateConVar(	"l4d_anti_rush_incapped",		"0",				"0=Off. How many survivors must be incapped before ignoring them in calculating rushers and slackers.", CVAR_FLAGS );
	g_hCvarPlayers =	CreateConVar(	"l4d_anti_rush_players",		"3",				"Minimum number of alive survivors before the function kicks in. Must be 3 or greater otherwise the lead/last and average cannot be detected.", CVAR_FLAGS, true, 3.0 );
	g_hCvarRangeLast =	CreateConVar(	"l4d_anti_rush_range_last",		"3000.0",			"0.0=Off. How far behind someone can travel from the average Survivor distance before being teleported forward.", CVAR_FLAGS );
	g_hCvarRangeLead =	CreateConVar(	"l4d_anti_rush_range_lead",		"3000.0",			"0.0=Off. How far forward someone can travel from the average Survivor distance before being teleported or slowed down.", CVAR_FLAGS );
	g_hCvarSlow =		CreateConVar(	"l4d_anti_rush_slow",			"75.0",				"Maximum speed someone can travel when being slowed down.", CVAR_FLAGS, true, 20.0 );
	g_hCvarTank =		CreateConVar(	"l4d_anti_rush_tanks",			"1",				"0=Off. 1=On. Should Anti-Rush be enabled when there are active Tanks.", CVAR_FLAGS );
	g_hCvarText =		CreateConVar(	"l4d_anti_rush_text",			"1",				"0=Off. 1=Print To Chat. 2=Hint Text. Display a message to someone rushing, or falling behind.", CVAR_FLAGS );
	g_hCvarTime =		CreateConVar(	"l4d_anti_rush_time",			"10",				"How often to print the message to someone if slowdown is enabled and affecting them.", CVAR_FLAGS );
	g_hCvarType =		CreateConVar(	"l4d_anti_rush_type",			"1",				"What to do with rushers. 1=Slowdown player speed when moving forward. 2=Teleport back to group.", CVAR_FLAGS );
	g_hCvarWarnLast =	CreateConVar(	"l4d_anti_rush_warn_last",		"2500.0",			"0.0=Off. How far behind someone can travel from the average Survivor distance before being warned about being teleported.", CVAR_FLAGS );
	g_hCvarWarnLead =	CreateConVar(	"l4d_anti_rush_warn_lead",		"2500.0",			"0.0=Off. How far forward someone can travel from the average Survivor distance before being warned about being teleported or slowed down.", CVAR_FLAGS );
	g_hCvarWarnTime =	CreateConVar(	"l4d_anti_rush_warn_time",		"15.0",				"0.0=Off. How often to print a message to someone warning them they are ahead or behind and will be teleported or slowed down.", CVAR_FLAGS );
	CreateConVar(						"l4d_anti_rush_version",		PLUGIN_VERSION,		"Anti Rush plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_anti_rush");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarFinale.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncap.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPlayers.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRangeLast.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRangeLead.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTank.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarText.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSlow.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWarnLast.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWarnLead.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWarnTime.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("player_bot_replace", player_bot_replace );	
	HookEvent("bot_player_replace", bot_player_replace );	

	#if DEBUG_BENCHMARK
	g_Prof = CreateProfiler();
	#endif
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarFinale = g_hCvarFinale.IntValue;
	g_iCvarIncap = g_hCvarIncap.IntValue;
	g_iCvarPlayers = g_hCvarPlayers.IntValue;
	g_fCvarTime = g_hCvarTime.FloatValue;
	g_iCvarTank = g_hCvarTank.IntValue;
	g_iCvarText = g_hCvarText.IntValue;
	g_fCvarSlow = g_hCvarSlow.FloatValue;
	g_iCvarType = g_hCvarType.IntValue;
	g_fCvarRangeLast = g_hCvarRangeLast.FloatValue;
	g_fCvarRangeLead = g_hCvarRangeLead.FloatValue;
	g_fCvarWarnLast = g_hCvarWarnLast.FloatValue;
	g_fCvarWarnLead = g_hCvarWarnLead.FloatValue;
	g_fCvarWarnTime = g_hCvarWarnTime.FloatValue;

	if( g_fCvarRangeLast && g_fCvarRangeLast < MINIMUM_RANGE ) g_fCvarRangeLast = MINIMUM_RANGE;
	if( g_fCvarRangeLead && g_fCvarRangeLead < MINIMUM_RANGE ) g_fCvarRangeLead = MINIMUM_RANGE;
	if( g_fCvarWarnLast && g_fCvarWarnLast < MINIMUM_RANGE ) g_fCvarWarnLast = MINIMUM_RANGE;
	if( g_fCvarWarnLead && g_fCvarWarnLead < MINIMUM_RANGE ) g_fCvarWarnLead = MINIMUM_RANGE;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookEvent("round_start",	Event_RoundStart);
		HookEvent("round_end",		Event_RoundEnd);
		HookEvent("player_death",	Event_PlayerDeath);
		HookEvent("player_team",	Event_PlayerTeam);

		Event_RoundStart(null, "", false);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("round_start",	Event_RoundStart);
		UnhookEvent("round_end",	Event_RoundEnd);
		UnhookEvent("player_death",	Event_PlayerDeath);
		UnhookEvent("player_team",	Event_PlayerTeam);

		ResetSlowdown();
		ResetPlugin();
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTimerAntiRushHuman;
	//delete g_hTimerAntiRushBot;
	
	bool isGauntlet=false;
	int entity = FindEntityByClassname(-1, "trigger_finale");
	if( entity != -1 )
	{
		//if m_type =4 then scavenge
		if( GetEntProp(entity, Prop_Data, "m_type") != 1 ) isGauntlet=true;
	}
	
	if (L4D_IsMissionFinalMap())
	{
		// Finales allowed
		if( g_iCvarFinale == 1)
		{
			g_hTimerAntiRushHuman = CreateTimer(1.0, TimerAntiRushHuman, _, TIMER_REPEAT);
			//g_hTimerAntiRushBot = CreateTimer(1.0, TimerAntiRushBot, _, TIMER_REPEAT);
		}
		// Finales not allowed
		else
		{
			// Gauntlet finale only
			if ((g_iCvarFinale == 2)&&isGauntlet) 
			{
				g_hTimerAntiRushHuman = CreateTimer(1.0, TimerAntiRushHuman, _, TIMER_REPEAT);
				//g_hTimerAntiRushBot = CreateTimer(1.0, TimerAntiRushBot, _, TIMER_REPEAT);

			}		
		}
	}//or not finale
	else
	{
		g_hTimerAntiRushHuman = CreateTimer(1.0, TimerAntiRushHuman, _, TIMER_REPEAT);
		//g_hTimerAntiRushBot = CreateTimer(1.0, TimerAntiRushBot, _, TIMER_REPEAT);
	}

}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetSlowdown();
	ResetPlugin();
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		ResetClient(client);
	}
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		ResetClient(client);
	}
}


//Fires when a bot is attempting to replace a player.
public void player_bot_replace(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(Spawn_Event.GetInt("player"));
	int bot = GetClientOfUserId(Spawn_Event.GetInt("bot"));
	teleportbotahead(bot);
}
//Fires when a player is attempting to replace a bot.
public void bot_player_replace(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(Spawn_Event.GetInt("player"));
	int bot = GetClientOfUserId(Spawn_Event.GetInt("bot"));
	teleportbotahead(client);
	//PrintToChatAll("bot_player_replace %N  place %N", client, bot);
}


void teleportbotahead(int client)
{
	//check if there are any alive survivor in server
	int iAliveSurvivor = GetAheadClient();//GetRandomClient();
	if(iAliveSurvivor != 0)
	{
		float vPos[3];
		GetClientAbsOrigin(iAliveSurvivor, vPos);		
		TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
	}
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 1; i <= MAXPLAYERS; i++ )
	{
		ResetClient(i);
	}

	delete g_hTimerAntiRushHuman;
	//delete g_hTimerAntiRushBot;
}

void ResetClient(int i)
{
	g_bInhibit[i] = false;
	g_fHintLast[i] = 0.0;
	g_fHintWarn[i] = 0.0;
	g_fLastFlow[i] = 0.0;

	SDKUnhook(i, SDKHook_PreThinkPost, PreThinkPost);
}

void ResetSlowdown()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_bInhibit[i] && IsClientInGame(i) )
		{
			SDKUnhook(i, SDKHook_PreThinkPost, PreThinkPost);
		}

		g_bInhibit[i] = false;
	}
}



// ====================================================================================================
//					LOGIC
// ====================================================================================================
public Action TimerAntiRushHuman(Handle timer)
{
	if( !g_bMapStarted ) return Plugin_Continue;
	#if DEBUG_BENCHMARK
	StartProfiling(g_Prof);
	#endif
	static bool bTanks;
	if( g_iCvarTank == 0 )
	{
		if( L4D2_GetTankCount() > 0 )
		{
			if( !bTanks )
			{
				bTanks = true;
				ResetSlowdown();
			}

			return Plugin_Continue;
		} else {
			bTanks = false;
		}
	}
	float flow;
	int count, countflow, index;
	// Get survivors flow distance
	ArrayList aList = new ArrayList(2);
	// Account for incapped
	int clients[MAXPLAYERS+1];
	int incapped, client;
	// Check valid survivors, count incapped
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			clients[count++] = i;
			if( GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )
				incapped++;
		}
	}

	for( int i = 0; i < count; i++ )
	{
		client = clients[i];

		// Ignore incapped
		if( incapped > g_iCvarIncap && GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) )
			continue;
		
		// Ignore bot
		if(IsFakeClient(client))
			continue;

		flow = L4D2Direct_GetFlowDistance(client);
		if( flow && flow != -9999.0 ) // Invalid flows
		{
			countflow++;
			index = aList.Push(flow);
			aList.Set(index, client, 1);
		}
		// Reset slowdown if players flow is invalid
		else if( g_bInhibit[client] == true )
		{
			g_bInhibit[client] = false;
			SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPost);
		}
	}
	// Incase not enough players or some have invalid flow distance, we still need an average.
	if( countflow >= g_iCvarPlayers )
	{
		aList.Sort(Sort_Descending, Sort_Float);
		int clientflowAvg;
		int clientflowFirst;
		int clientflowNear;
		float lastFlow;
		float distance;		
		bool teleportedahead =false;
		// Detect rushers
		if( g_fCvarRangeLead )
		{
			// Loop through survivors from highest flow
			for( int i = 0; i < countflow; i++ )
			{
				client = aList.Get(i, 1);
				bool flowBack = true;
				// Only check nearest half of survivor pack.
				if( i < countflow / 2 )
				{
					flow = aList.Get(i, 0);
					// Loop through from next survivor to mid-way through the pack.
					for( int x = i + 1; x <= countflow / 2; x++ )
					{
						lastFlow = aList.Get(x, 0);
						distance = flow - lastFlow;
						// Warn ahead hint
						if( g_iCvarText && g_fCvarWarnTime && g_fCvarWarnLead && distance > g_fCvarWarnLead && distance < g_fCvarRangeLead && g_fHintWarn[client] < GetGameTime() )
						{
							g_fHintWarn[client] = GetGameTime() + g_fCvarWarnTime;

							if( g_iCvarType == 1 )
								ClientHintMessage(client, "Warn_Slowdown");
							else
								ClientHintMessage(client, "Warn_Ahead");
						}
						// Compare higher flow with next survivor, they're rushing
						if( distance > g_fCvarRangeLead )
						{
							// PrintToServer("RUSH: %N %f", client, distance);
							flowBack = false;
							// Slowdown enabled?
							if( g_iCvarType == 1 )
							{
								// Inhibit moving forward
								// Only check > or < because when == the same flow distance, they're either already being slowed or running back, so we don't want to change/affect them within the same flow NavMesh.
								if( flow > g_fLastFlow[client] )
								{
									g_fLastFlow[client] = flow;

									if( g_bInhibit[client] == false )
									{
										g_bInhibit[client] = true;
										SDKHook(client, SDKHook_PreThinkPost, PreThinkPost);
									}

									// Hint
									if( g_iCvarText && g_fHintLast[client] < GetGameTime() )
									{
										g_fHintLast[client] = GetGameTime() + g_fCvarTime;

										ClientHintMessage(client, "Rush_Slowdown");
									}
								}
								else if( flow < g_fLastFlow[client] )
								{
									flowBack = true;
									g_fLastFlow[client] = flow;
								}
							}
							// Teleport enabled?
							if( g_iCvarType == 2)// &&  IsClientPinned(client) == false )
							{
								clientflowNear = aList.Get(1, 1);
								//clientflowAvg = aList.Get(x, 1);
								float vPos[3];
								GetClientAbsOrigin(clientflowNear, vPos);
								// Hint
								if( g_iCvarText)
								{
									ClientHintMessage(client, "Rush_Ahead");
								}
								static char PlayerName[100];
								GetClientName(client, PlayerName, sizeof(PlayerName));									
								char rawmsg[MAX_COMMAND_LENGTH];
								Format(rawmsg, sizeof(rawmsg), "%T", "Friend_comeback", client,PlayerName);
								CPrintToChatAll("%s",rawmsg);
								TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
								teleportedahead =true;
							}
							break;
						}
					}
				}
				// Running back, allow full speed
				if( flowBack && g_bInhibit[client] == true )
				{
					g_bInhibit[client] = false;
					SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPost);
				}
			}
		}
		// Teleport slacker
		if( g_fCvarRangeLast )
		{
			// Loop through survivors from lowest flow to mid-way through the pack.
			for( int i = countflow - 1; i > countflow / 2; i-- )
			{
				flow = aList.Get(i, 0);
				client = aList.Get(i, 1);
				// Loop through from next survivor to mid-way through the pack.
				for( int x = i - 1; x < countflow; x++ )
				{
					lastFlow = aList.Get(x, 0);
					distance = lastFlow - flow;
					// Warn behind hint
					if( g_iCvarText && g_fCvarWarnTime && g_fCvarWarnLast && distance > g_fCvarWarnLast && distance < g_fCvarRangeLead && g_fHintWarn[client] < GetGameTime() )
					{
						g_fHintWarn[client] = GetGameTime() + g_fCvarWarnTime;
						ClientHintMessage(client, "Warn_Behind");
					}
					// Compare lower flow with next survivor, they're behind
					if (teleportedahead)
					{						
						float vPos[3];
						GetClientAbsOrigin(clientflowNear, vPos);				
						// Hint
						if( g_iCvarText )
						{
							ClientHintMessage(client, "Rush_Behind");
						}
						TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
						break;		
					}
					else
					if( (distance > g_fCvarRangeLast))// || teleportedahead)// && IsClientPinned(client) == false )
					{
						clientflowFirst = aList.Get(0, 1);
						// PrintToServer("SLOW: %N %f", client, distance);
						clientflowAvg = aList.Get(x, 1);
						float vPos[3];
						GetClientAbsOrigin(clientflowAvg, vPos);
						// Hint
						if( g_iCvarText )
						{
							ClientHintMessage(client, "Rush_Behind");
						}
						TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
						break;
					}
				}
			}
		}
	}
	else
	{
		ResetSlowdown();
	}

	delete aList;

	#if DEBUG_BENCHMARK
	StopProfiling(g_Prof);
	float speed = GetProfilerTime(g_Prof);
	if( speed < g_fBenchMin ) g_fBenchMin = speed;
	if( speed > g_fBenchMax ) g_fBenchMax = speed;
	g_fBenchAvg += speed;
	g_iBenchTicks++;

	PrintToServer("Anti Rush benchmark: %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
	#endif

	return Plugin_Continue;
}

/* Remove this line to enable, if you want to limit speed (slower) than default when walking/crouched.
public Action L4D_OnGetCrouchTopSpeed(int target, float &retVal)
{
	if( g_bInhibit[target] )
	{
		retVal = g_fCvarSlow;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D_OnGetWalkTopSpeed(int target, float &retVal)
{
	if( g_bInhibit[target] )
	{
		retVal = g_fCvarSlow;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
// */

public void PreThinkPost(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fCvarSlow);
}

void ClientHintMessage(int client, const char[] translation)
{
	static char sMessage[256];
	Format(sMessage, sizeof(sMessage), "%T", translation, client);

	if( g_iCvarText == 1 )
	{
		ReplaceColors(sMessage, sizeof(sMessage), false);
		PrintToChat(client, sMessage);
	} else {
		ReplaceColors(sMessage, sizeof(sMessage), true);
		PrintHintText(client, sMessage);
	}
}

void ReplaceColors(char[] translation, int size, bool hint)
{
	ReplaceString(translation, size, "{white}",		hint ? "" : "\x01");
	ReplaceString(translation, size, "{cyan}",		hint ? "" : "\x03");
	ReplaceString(translation, size, "{orange}",	hint ? "" : "\x04");
	ReplaceString(translation, size, "{green}",		hint ? "" : "\x05");
}

bool IsClientPinned(int client)
{
	if( GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0
	) return true;

	if( g_bLeft4Dead2 &&
	(
		GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0
	)) return true;

	return false;
}

bool IsClientBehind(int client)
{
	if( GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) ||
		GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)		
	) return true;

	return false;
}


stock void CPrintToChat(int client, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(client, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void CPrintToChatAllExclude(int iExcludeClient, const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( i != iExcludeClient && IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 3);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}


int GetAheadClient()
{	
	float flow;
	int count, countflow, index;
	// Get survivors flow distance
	ArrayList aList = new ArrayList(2);
	// Account for incapped
	int clients[MAXPLAYERS+1];
	int client=0;
	countflow=0;
	// Check valid survivors, count incapped
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			clients[count++] = i;
		}
	}

	for( int i = 0; i < count; i++ )
	{
		client = clients[i];
		// Ignore bot
		if(IsFakeClient(client))
			continue;
		flow = L4D2Direct_GetFlowDistance(client);
		if( flow && flow != -9999.0 ) // Invalid flows
		{
			countflow++;
			index = aList.Push(flow);
			aList.Set(index, client, 1);
		}
	}
	// Incase not enough players or some have invalid flow distance, we still need an average.
	if( countflow >= 1 )
	{
		aList.Sort(Sort_Descending, Sort_Float);
		client = aList.Get(0, 1);
	}
	delete aList;
	return client;
}