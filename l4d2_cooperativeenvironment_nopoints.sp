#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION						  "1.0.5"
//1.0.0 - Release
//1.0.1 - Added OnTakeDamage timer / stop debugging
//1.0.2 - Bugfixes
//1.0.3 - Bugfixes
//1.0.4 - Optimization
//1.0.5 - Optimization
#define		DEBUG	0

//Handle SetKills;
ConVar g_hCvarCoopEnvEnable;
int g_iCvarCoopEnvEnable;
int game_score_index; 
bool g_bLateLoad;
bool g_bMapStarted; 
bool g_bCvarAllow;

public Plugin:myinfo =
{
	name = "L4D2 Cooperative Environment - No Points",
	author = "Jeremy Villanueva",
	description = "Reset kills, so show scores should always be zero at the round end.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=330390"
};


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	/*
	decl String:game_name[CLASS_STRINGLENGHT];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrContains(game_name, "left4dead", false) < 0)
	{
		SetFailState("Plugin supports L4D2 only.");
	}
*/
	CreateConVar("l4d2_cooperativeenvironment_nopoints_version", PLUGIN_VERSION, "L4D2 Cooperative Environment", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hCvarCoopEnvEnable = CreateConVar("l4d2_cooperativeenvironment_nopoints_enable", "1", " Does L4D2 Cooperative Environment will activate? ", FCVAR_NOTIFY);
		AutoExecConfig(true,					"l4d2_cooperativeenvironment_nopoints");

	g_hCvarCoopEnvEnable.AddChangeHook(ConVarChanged_Cvars);
	
	game_score_index=-1;
	
	IsAllowed();
	
}


public void OnMapStart()
{
	g_bMapStarted = true;
	#if DEBUG
	PrintToServer("\x03[COOPENV]\x04 OnMapStart");
	#endif
	if (!findGameScore()) createGameScore(); 
	#if DEBUG
	PrintToServer("\x03[COOPENV]\x04 game_score_index %d",game_score_index);
	#endif
}

bool findGameScore()
{
	#if DEBUG
	PrintToServer("\x03[COOPENV]\x04 findGameScore");
	#endif
	#if DEBUG
	PrintToServer("\x03[COOPENV]\x04 game_score_index %d",game_score_index);
	#endif
	int find=FindEntityByClassname(-1, "game_score");
	#if DEBUG
	PrintToServer("\x03[COOPENV]\x04 find %d",find);
	#endif
	if (find != INVALID_ENT_REFERENCE) return true;
	return false;
}

void createGameScore()
{
	#if DEBUG
	PrintToServer("\x03[COOPENV]\x04 createGameScore %d",game_score_index);
	#endif
	game_score_index = CreateEntityByName("game_score");
	DispatchSpawn(game_score_index);
}


public void OnMapEnd()
{
	g_bMapStarted = false;
}

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
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			UnHookClient(i);
			HookClient(i);
		}
	}
}

void GetCvars()
{
	g_iCvarCoopEnvEnable = g_hCvarCoopEnvEnable.IntValue;
}


void IsAllowed()
{	
	bool bCvarAllow = g_hCvarCoopEnvEnable.BoolValue;
	GetCvars();
	if( g_bCvarAllow == false && bCvarAllow == true  )
	{		
		if( g_bLateLoad )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					HookClient(i);
				}
			}
		}		
		HookEvents(true);
		g_bCvarAllow = true;
	}		
	else if( g_bCvarAllow == true && (bCvarAllow == false) )
	{
		g_bLateLoad = true; // To-rehook active SI if plugin re-enabled.
		HookEvents(false);
		g_bCvarAllow = false;		
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				UnHookClient(i);
			}
		}
	}
}

void UnHookClient(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);	
}

// ====================================================================================================
//					EVENTS
// ====================================================================================================

void HookEvents(bool hook)
{
	static bool hooked;

	if( !hooked && hook )
	{
		HookEvent("infected_hurt", Event_InfectedHurt,EventHookMode_Post);	
		HookEvent("round_start", Event_RoundStart,EventHookMode_Pre);//Using OnMapStart
		HookEvent("round_end", Event_RoundEnd,EventHookMode_Pre);
		HookEvent("map_transition", Event_RoundEnd,EventHookMode_Pre);
		HookEvent("mission_lost", Event_RoundEnd,EventHookMode_Pre);
		HookEvent("finale_vehicle_leaving", Event_RoundEnd,EventHookMode_Pre);
		HookEvent("finale_win", Event_RoundEnd,EventHookMode_Pre);
		HookEvent("scavenge_match_finished", Event_RoundEnd,EventHookMode_Pre);
		HookEvent("player_death",	Event_PlayerDeath);
		HookEvent("player_spawn",	Event_PlayerSpawn);
			
	}
	else if( hooked && !hook )
	{
		UnhookEvent("infected_hurt", Event_InfectedHurt,EventHookMode_Post);	
		UnhookEvent("round_start", Event_RoundStart,EventHookMode_Pre);//Using OnMapStart
		UnhookEvent("round_end", Event_RoundEnd,EventHookMode_Pre);
		UnhookEvent("map_transition", Event_RoundEnd,EventHookMode_Pre);
		UnhookEvent("mission_lost", Event_RoundEnd,EventHookMode_Pre);
		UnhookEvent("finale_vehicle_leaving", Event_RoundEnd,EventHookMode_Pre);
		UnhookEvent("finale_win", Event_RoundEnd,EventHookMode_Pre);
		UnhookEvent("scavenge_match_finished", Event_RoundEnd,EventHookMode_Pre);
		UnhookEvent("player_death",	Event_PlayerDeath);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
	}
}


public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) )
			UnHookClient(i);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client ) HookClient(client);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client ) SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void HookClient(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}



//Event fired when the Round Ends
public Action Event_RoundEnd(Handle hEvent, const char[] strName, bool bDontBroadcast) {
	#if DEBUG
	PrintToServer("\x03[COOPENV]\x04 Event_RoundEnd");
	#endif	
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) )
			UnHookClient(i);		
}

public void OnThink(int client)
{
	SDKUnhook(client, SDKHook_PostThink, OnThink);
	if (IsValidClient(client))
	{
		SetFullScore(client);
		RequestFrame(SetFullScore,client);
	}
}




public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{	
	#if DEBUG
	PrintToServer("\x03[COOPENV]\x04 OnTakeDamage.");
	#endif
	if(IsValidClient(attacker) && GetClientTeam(attacker) == 2)
	{		
		RequestFrame(SetFullScore,attacker);
		SetFullScore(attacker);
		SDKHook(attacker, SDKHook_PostThink, OnThink);
	}	
}  


public Action Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
	PrintToServer("\x03[COOPENV]\x04 Event_InfectedHurt.");
	#endif
	int attackerId = event.GetInt("attacker");
	int attackerev = GetClientOfUserId(attackerId);		
	if(IsValidClient(attackerev) && GetClientTeam(attackerev) == 2)
	{
		SetFullScore(attackerev);
		RequestFrame(SetFullScore,attackerev);
	}
}
/*
public Action Timer_SetKills(Handle Timer,int attacker)
{	
	SetKills(attacker);
}
	
public Action Timer_SetFullScore(Handle Timer,int attacker)
{	
	SetFullScore(attacker);
}
*/


public void SetKills(int attacker)
{	
	SetEntProp(attacker, Prop_Send, "m_checkpointZombieKills", 0);
	SetEntProp(attacker, Prop_Send, "m_missionZombieKills", 0);
	SetEntProp(attacker, Prop_Send, "m_checkpointMeleeKills", 0);
	SetEntProp(attacker, Prop_Send, "m_missionMeleeKills", 0);		
	SetEntProp(attacker, Prop_Send, "m_checkpointIncaps", 0);
	SetEntProp(attacker, Prop_Send, "m_missionIncaps", 0);
	SetEntProp(attacker, Prop_Data, "m_iFrags", 0);
	if (!findGameScore()) createGameScore(); 
	AcceptEntityInput(game_score_index, "ApplyScore", attacker, 0); 
}
	
public void SetDamage(int attacker)
{	
	SetEntProp(attacker, Prop_Send, "m_checkpointDamageToTank", 0);
	SetEntProp(attacker, Prop_Send, "m_checkpointDamageToWitch", 0);
}
	
public void SetFullScore(int attacker)
{
	SetKills(attacker);
	SetDamage(attacker);
}
	

public bool IsValidClient(client)
{
	if (client <= 0)
		return false;
	
	if (client > MaxClients)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}