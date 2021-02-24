#define PLUGIN_VERSION		"1.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define LOG_FILENAME 	"logs/entity_limit.log"
#define MODEL_ERROR 	"models/error.mdl"
#define CVAR_FLAGS		FCVAR_NOTIFY
#define ENTITY_SAFE_MAX 1900
#define DEBUG 			0

public Plugin myinfo =
{
	name = "[ANY] Entity Limits Logger",
	author = "Dragokas",
	description = "Logs entity types when the total number of entities on the map exceeds a pre-prefined maximum",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

char g_sPath[PLATFORM_MAX_PATH+1];
bool g_bLogged;

public void OnPluginStart()
{
	CreateConVar("sm_entity_limit_log_version", PLUGIN_VERSION, "Plugin Version", CVAR_FLAGS | FCVAR_DONTRECORD);

	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), LOG_FILENAME);
	
	RegAdminCmd("sm_entlog", CmdEntityLog, ADMFLAG_ROOT);
	
	#if DEBUG
		RegAdminCmd("sm_addent", CmdCreateEntities, ADMFLAG_ROOT);
	#endif
}

Action CmdEntityLog(int client, int args)
{
	ReplyToCommand(client, "Entities log is saved to: %s", g_sPath);
	LogAll();
	return Plugin_Handled;
}

#if DEBUG
Action CmdCreateEntities(int client, int args)
{
	const int COUNT = 100;
	int entity;
	float vOrigin[3];
	
	if( client && GetClientTeam(client) != 1 && IsPlayerAlive(client) )
	{
		GetClientAbsOrigin(client, vOrigin);
	}
	for( int i = 0; i < COUNT; i++ )
	{
		entity = CreateEntityByName("prop_dynamic_override"); // CDynamicProp
		if (entity != -1) {
			DispatchKeyValue(entity, "spawnflags", "0");
			DispatchKeyValue(entity, "solid", "0");
			DispatchKeyValue(entity, "disableshadows", "1");
			DispatchKeyValue(entity, "disablereceiveshadows", "1");
			DispatchKeyValue(entity, "model", MODEL_ERROR);
			TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "TurnOn");
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 0, 0, 0, 0);
		}
	}
	ReplyToCommand(client, "Created %i entities. Total: %i", COUNT, GetEntityCount());
	return Plugin_Handled;
}
#endif

public void OnMapStart()
{
	g_bLogged = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if( GetEntityCount() > ENTITY_SAFE_MAX )
	{
		if( !g_bLogged )
		{
			g_bLogged = true; // log only once per map
			LogAll();
		}
	}
}

public void LogAll()
{
	LogTo("[Entity report]");

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	LogTo("Map: %s", sMap);
	
	ReportEntityTotal();
	GetPrecacheInfo();
	ReportClientWeapon();
}

void ReportEntityTotal()
{
	LogTo("{Total entities}");
	int ent = -1, cnt = 0;
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		cnt++;
	}
	LogTo("All: %i", cnt);
	LogTo("Networked: %i", GetEntityCount());
	
	char sClass[64], sName[128];
	char sModel[PLATFORM_MAX_PATH];
	float pos[3];
	ent = -1;
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		if( IsValidEntity(ent) )
		{
			pos[0] = 0.0;
			pos[1] = 0.0;
			pos[2] = 0.0;
			if( HasEntProp(ent, Prop_Data, "m_vecOrigin"))
			{
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
			}
			sModel[0] = 0;
			if( HasEntProp(ent, Prop_Data, "m_ModelName") )
			{
				GetEntPropString(ent, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			}
			sName[0] = 0;
			if( HasEntProp(ent, Prop_Data, "m_iName") )
			{
				GetEntPropString(ent, Prop_Data, "m_iName", sName, sizeof(sName));
			}
			GetEntityClassname(ent, sClass, sizeof(sClass));
			LogTo("%s. Name: %s. Model: %s. Origin: %.1f %.1f %.1f %s", sClass, sName, sModel, pos[0], pos[1], pos[2], IsInSafeRoom(ent) ? " (IN SAFEROOM)" : "");
		}
	}
}

void ReportClientWeapon()
{
	LogTo("{Weapon Report}");
	LogTo("{Survivors}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			LogTo("%i. %N%s%s", i, i, IsFakeClient(i) ? " (BOT)" : "", IsPlayerAlive(i) ? "" : " (DEAD)");
			if( IsPlayerAlive(i))
			{
				WeaponInfo(i);
			}
		}
	}
	LogTo("{Spectators}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 1 )
		{
			LogTo("%i. %N", i, i);
		}
	}
	LogTo("{Infected}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 )
		{
			LogTo("%i. %N%s%s", i, i, IsFakeClient(i) ? " (BOT)" : "", IsPlayerAlive(i) ? "" : " (DEAD)");
		}
	}
}

void WeaponInfo(int client)
{
	int weapon;
	char sName[32];
	for( int i = 0; i < 5; i++ )
	{
		weapon = GetPlayerWeaponSlot(client, i);
		
		if( weapon == -1 )
		{
			LogTo("Slot #%i: EMPTY", i);
		}
		else {
			GetEntityClassname(weapon, sName, sizeof(sName));
			LogTo("Slot #%i: %s", i, sName);
		}
	}
}

void GetPrecacheInfo()
{
	int iTable = FindStringTable("modelprecache");
	if( iTable != INVALID_STRING_TABLE )
	{
		int iNum = GetStringTableNumStrings(iTable);
		LogTo("{StringTable} 'modelprecache' count: %i", iNum);
	}
}

bool IsInSafeRoom(int entity)
{
	int chl = -1;
	chl = FindEntityByClassname(-1, "info_changelevel");
	if (chl == -1)
	{
		chl = FindEntityByClassname(-1, "trigger_changelevel");
		if (chl == -1)
			return false;
	}
	
	float min[3], max[3], pos[3], me[3], maxme[3];

	GetEntPropVector(chl, Prop_Send, "m_vecMins", min);
	GetEntPropVector(chl, Prop_Send, "m_vecMaxs", max);
	
	// zone expanding by Y-axis
	min[2] -= 15.0;
	max[2] += 40.0;
	
	GetEntPropVector(chl, Prop_Send, "m_vecOrigin", pos);
	
	AddVectors(min, pos, min);
	AddVectors(max, pos, max);
	
	if( HasEntProp(entity, Prop_Send, "m_vecOrigin") )
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", me);
	}
	else {
		return false;
	}
	
	char g_sMap[64];
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	
	if (strcmp(g_sMap, "l4d_smalltown03_ranchhouse") == 0)
	{
		if (me[0] > -2442.0 && (175.0 < me[2] < 200.0) )
			return false;
	}
	else if (strcmp(g_sMap, "l4d_smalltown04_mainstreet") == 0)
	{
		max[2] += 20.0;
	}
	
	if( HasEntProp(entity, Prop_Send, "m_vecMaxs") )
	{
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxme);
	}
	else {
		return false;
	}
	
	AddVectors(maxme, me, maxme);
	
	return IsDotInside(me, min, max) && maxme[2] < max[2];
}

bool IsDotInside(float dot[3], float min[3], float max[3])
{
	if(	min[0] < dot[0] < max[0] &&
		min[1] < dot[1] < max[1] &&
		min[2] < dot[2] < max[2]) {
		return true;
	}
	return false;
}

void LogTo(const char[] format, any ...)
{
	static char buffer[192];
	VFormat(buffer, sizeof(buffer), format, 2);
	LogToFileEx(g_sPath, buffer);
}