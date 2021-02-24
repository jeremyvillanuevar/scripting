#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Survivor Speed
#define PLUGIN_VERSION "1.0"

ConVar g_hcvarSurvivorSpeed,g_hCvarSurvivorSpeedEnable;
static laggedMovementOffset = 0;
float g_fcvarSurvivorSpeed;
bool g_bCvarSurvivorSpeedEnable;
bool g_bLateLoad;
bool g_bCvarAllow;

public Plugin:myinfo = 
{
    name = "[L4D2] Survivor Speed",
    author = "Mortiegama",
    description = "Allows custom set Survivor Speed.",
    version = PLUGIN_VERSION,
    url = ""
}

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
	CreateConVar("sm_survivorspeed_version", PLUGIN_VERSION, "Survivor Speed Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hcvarSurvivorSpeed = CreateConVar("sm_ss_survivorspeed", "1.25", "Speed (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 2.0 );
	g_hCvarSurvivorSpeedEnable = CreateConVar("sm_ss_survivorspeed_enable", "1", "Enables the  plugin (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	AutoExecConfig(true,					"L4D2 Survivor Speed");

	g_hcvarSurvivorSpeed.AddChangeHook(ConVarChanged_Cvars);
	
	g_hCvarSurvivorSpeedEnable.AddChangeHook(ConVarChanged_Cvars);
	
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");

	IsAllowed();
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
}

void GetCvars()
{
	g_fcvarSurvivorSpeed = g_hcvarSurvivorSpeed.FloatValue;
	g_bCvarSurvivorSpeedEnable= g_hCvarSurvivorSpeedEnable.BoolValue;
}


void IsAllowed()
{	
	bool bCvarAllow = g_hCvarSurvivorSpeedEnable.BoolValue;
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true  )
	{
		/*
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
		*/
		HookEvents(true);
		g_bCvarAllow = true;
	}

		
	else if( g_bCvarAllow == true && (bCvarAllow == false) )
	{
		g_bLateLoad = true; // To-rehook active SI if plugin re-enabled.
		HookEvents(false);
		g_bCvarAllow = false;
		/*
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		*/
	}
}

void HookEvents(bool hook)
{
	static bool hooked;

	if( !hooked && hook )
	{
		HookEvent("player_spawn", event_PlayerSpawn);
		HookEvent("player_first_spawn", event_PlayerFirstSpawn);
			
	}
	else if( hooked && !hook )
	{
		UnhookEvent("player_spawn", event_PlayerSpawn);
		UnhookEvent("player_first_spawn", event_PlayerFirstSpawn);
	}
}



public event_PlayerFirstSpawn(Handle event,const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && !IsFakeClient(client))
	{
		SetEntDataFloat(client, laggedMovementOffset, 1.0*g_fcvarSurvivorSpeed, true);
		RequestFrame(putSurvivorSpeed,client);
		SDKHook(client, SDKHook_PostThink, OnThink);
	}
}

public event_PlayerSpawn(Handle event, const char[] name, bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && !IsFakeClient(client))
	{
		SetEntDataFloat(client, laggedMovementOffset, 1.0*g_fcvarSurvivorSpeed, true);
		RequestFrame(putSurvivorSpeed,client);
		SDKHook(client, SDKHook_PostThink, OnThink);
	}
}

public Action Event_SurvivorSpeed(Handle timer, int client) 
{
	if (IsValidClient(client)&& GetClientTeam(client) == 2 && !IsFakeClient(client))
	{
		PrintHintText(client, "Your speed has been increased!");
		SetEntDataFloat(client, laggedMovementOffset, 1.0*g_fcvarSurvivorSpeed, true);
		SDKHook(client, SDKHook_PostThink, OnThink);
	}
}

public void putSurvivorSpeed(client)
{
	SetEntDataFloat(client, laggedMovementOffset, 1.0*g_fcvarSurvivorSpeed, true);
}


public bool IsValidClient(client)
{
	if (client <= 0)
		return false;
	
	if (client > MaxClients)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}

public void OnThink(int client)
{
	SDKUnhook(client, SDKHook_PostThink, OnThink);

	if (IsValidClient(client))
	{
		SetEntDataFloat(client, laggedMovementOffset, 1.0*g_fcvarSurvivorSpeed, true);
		RequestFrame(putSurvivorSpeed,client);
	}
}

