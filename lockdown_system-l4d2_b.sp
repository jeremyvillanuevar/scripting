/*	The Last Stand Gamedate signature fix
*	(Thanks to Shadowysn's work, [L4D1/2] Direct Infected Spawn (Limit-Bypass), https://forums.alliedmods.net/showthread.php?t=320849)
*	(TLS team, pushing unuseful updates no one really cares or asks for. Come on! Value)
*/

#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <glow>
#include <left4dhooks>
#define PLUGIN_VERSION "3.8"

#define UNLOCK 0
#define LOCK 1
#define MODEL_TANK "models/infected/hulk.mdl"
#define MODEL_SAFEROOM_DOOR_1 "models/props_doors/checkpoint_door_02.mdl"
#define MODEL_SAFEROOM_DOOR_2 "models/props_doors/checkpoint_door_-02.mdl"
#define MODEL_SAFEROOM_DOOR_3 "models/lighthouse/checkpoint_door_lighthouse02.mdl"
#define NAME_CreateTank "NextBotCreatePlayerBot<Tank>"

ConVar lsAnnounce, lsAntiFarmDuration, lsDuration, lsMobs, lsTankDemolitionBefore, lsTankDemolitionAfter,
	lsType, lsNearByAllSurvivor, lsHint, lsGetInLimit, lsDoorOpeningTeleport, lsDoorOpeningTankInterval,
	lsDoorBotDisable, lsMapOff, lsPreventDoorSpamDuration, lsDoorLockColor, lsDoorUnlockColor, lsDoorGlowRange;

int iAntiFarmDuration, iDuration, iMobs, iType, iDoorStatus, iCheckpointDoor, iSystemTime, iGetInLimit, 
	iDoorOpeningTankInterval, iDoorGlowRange;
int _iDoorOpeningTankInterval, g_iRoundStart, g_iPlayerSpawn, g_iDoorLockColors[3], g_iDoorUnlockColors[3];
float fDoorSpeed, fFirstUserOrigin[3], fPreventDoorSpamDuration;
bool bAntiFarmInit, bLockdownInit, bLDFinished, bAnnounce, 
	bNearByAllSurvivor,bDoorOpeningTeleport, bTankDemolitionBefore, bTankDemolitionAfter,
	bSurvivorsAssembleAlready,blsHint, bDoorBotDisable;
bool bSpawnTank, bRoundEnd;
char sKeyMan[128], sLastName[2048][128];
Handle hAntiFarmTime = null, hLockdownTime = null;
static Handle hCreateTank = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evRetVal = GetEngineVersion();
	if (evRetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[TS] Plugin Supports L4D2 Only");
		return APLRes_SilentFailure;
	}

	CreateNative("Is_End_SafeRoom_Door_Open", Native_Is_End_SafeRoom_Door_Open);
	return APLRes_Success;
}

public int Native_Is_End_SafeRoom_Door_Open(Handle plugin, int numParams)
{
	return bLDFinished;
}


public Plugin myinfo = 
{
	name = "[L4D2] Lockdown System",
	author = "cravenge, Harry",
	description = "Locks Saferoom Door Until Someone Opens It.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/forumdisplay.php?f=108"
};

public void OnPluginStart()
{
	lsAnnounce = CreateConVar("lockdown_system-l4d2_announce", "1", "If 1, Enable saferoom door status Announcements", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	lsAntiFarmDuration = CreateConVar("lockdown_system-l4d2_anti-farm_duration", "50", "Duration Of Anti-Farm", FCVAR_DONTRECORD, true, 0.0);
	lsDuration = CreateConVar("lockdown_system-l4d2_duration", "100", "Duration Of Lockdown", FCVAR_DONTRECORD, true, 0.0);
	lsMobs = CreateConVar("lockdown_system-l4d2_mobs", "5", "Number Of Mobs To Spawn", FCVAR_DONTRECORD, true, 0.0, true, 10.0);
	lsTankDemolitionBefore = CreateConVar("lockdown_system-l4d2_tank_demolition_before", "1", "If 1, Enable Tank Demolition, server will spawn tank before door open ", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	lsTankDemolitionAfter = CreateConVar("lockdown_system-l4d2_tank_demolition_after", "1", "If 1, Enable Tank Demolition, server will spawn tank after door open ", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	lsType = CreateConVar("lockdown_system-l4d2_type", "0", "Lockdown Type: 0=Random, 1=Improved (opening slowly), 2=Default", FCVAR_DONTRECORD, true, 0.0, true, 2.0);
	lsNearByAllSurvivor = CreateConVar("lockdown_system-l4d2_all_survivors_near_saferoom", "1", "If 1, all survivors must assemble near the saferoom door before open.", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	lsHint = CreateConVar(	"lockdown_system-l4d2_spam_hint", "1", "0=Off. 1=Display a message showing who opened or closed the saferoom door.", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	lsGetInLimit = CreateConVar( "lockdown_system-l4d2_outside_slay_duration", "60", "After saferoom door is opened, slay players who are not inside saferoom in seconds. (0=off)", FCVAR_DONTRECORD, true, 0.0);
	lsDoorOpeningTeleport = CreateConVar( "lockdown_system-l4d2_teleport", "1", "0=Off. 1=Teleport common, special infected, and witch if they touch the door inside saferoom when door is opening. (prevent spawning and be stuck inside the saferoom, only works if Lockdown Type is 1)", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	lsDoorOpeningTankInterval = CreateConVar( "lockdown_system-l4d2_opening_tank_interval", "50", "Time Interval to spawn a tank when door is opening (0=off)", FCVAR_DONTRECORD, true, 0.0);
	lsDoorBotDisable = CreateConVar( "lockdown_system-l4d2_spam_bot_disable", "1", "If 1, prevent AI survivor from opening and closing the door.", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	lsMapOff = CreateConVar("lockdown_system-l4d2_map_off",	"c10m3_ranchhouse,l4d_reverse_hos03_sewers,l4d2_stadium4_city2,l4d_fairview10_church,l4d2_wanli01",	"Turn off the plugin in these maps, separate by commas (no spaces). (0=All maps, Empty = none).", FCVAR_DONTRECORD );
	lsPreventDoorSpamDuration = CreateConVar("lockdown_system-l4d2_prevent_spam_duration", "3.0", "How many seconds to lock after opening and closing the saferoom door.", FCVAR_DONTRECORD, true, 0.0);
	lsDoorLockColor = CreateConVar(	"lockdown_system-l4d2_lock_glow_color",	"255 0 0",	"The default glow color for saferoom door when lock. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_DONTRECORD );
	lsDoorUnlockColor = CreateConVar( "lockdown_system-l4d2_unlock_glow_color",	"200 200 200",	"The default glow color for saferoom door when unlock. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_DONTRECORD );
	lsDoorGlowRange = CreateConVar( "lockdown_system-l4d2_glow_range", "550", "The default value for saferoom door glow range.", FCVAR_DONTRECORD, true, 0.0);

	GetCvars();
	lsAnnounce.AddChangeHook(OnLSCVarsChanged);
	lsAntiFarmDuration.AddChangeHook(OnLSCVarsChanged);
	lsDuration.AddChangeHook(OnLSCVarsChanged_lsDuration);
	lsMobs.AddChangeHook(OnLSCVarsChanged);
	lsTankDemolitionBefore.AddChangeHook(OnLSCVarsChanged);
	lsTankDemolitionAfter.AddChangeHook(OnLSCVarsChanged);
	lsNearByAllSurvivor.AddChangeHook(OnLSCVarsChanged);
	lsHint.AddChangeHook(OnLSCVarsChanged);
	lsGetInLimit.AddChangeHook(OnLSCVarsChanged);
	lsDoorOpeningTeleport.AddChangeHook(OnLSCVarsChanged);
	lsDoorOpeningTankInterval.AddChangeHook(OnLSCVarsChanged);
	lsDoorBotDisable.AddChangeHook(OnLSCVarsChanged);
	lsPreventDoorSpamDuration.AddChangeHook(OnLSCVarsChanged);
	lsDoorLockColor.AddChangeHook(OnLSCVarsChanged);
	lsDoorUnlockColor.AddChangeHook(OnLSCVarsChanged);
	lsDoorGlowRange.AddChangeHook(OnLSCVarsChanged);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd); //wipe out
	HookEvent("map_transition", Event_RoundEnd); //mission complete
	HookEvent("player_use", OnPlayerUsePre, EventHookMode_Pre);
	HookEvent("entity_killed", TC_ev_EntityKilled);
	HookEvent("door_open",			Event_DoorOpen);
	HookEvent("door_close",			Event_DoorClose);

	GetGameData();

	AutoExecConfig(true, "lockdown_system-l4d2");
}

public void OnLSCVarsChanged_lsDuration(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();
	
	if (IsValidEnt(iCheckpointDoor))
	{
		if (iType != 1)
		{
			return;
		}
		
		SetEntPropFloat(iCheckpointDoor, Prop_Data, "m_flSpeed", 89.0 / float(iDuration));
	}
}

public void OnLSCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();
}

public void OnPluginEnd()
{
	SetCheckpointDoor_Default();
	ResetPlugin();
}

bool g_bValidMap = true, g_bTwoSafeRoomDoorBug;
public void OnMapStart()
{
	g_bValidMap = true;
	g_bTwoSafeRoomDoorBug = false;

	char sCvar[512];
	lsMapOff.GetString(sCvar, sizeof(sCvar));

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (strcmp(sMap, "c10m2_drainage", false) == 0)
	{
		g_bTwoSafeRoomDoorBug = true;
	}

	if( sCvar[0] != '\0' )
	{
		if( strcmp(sCvar, "0") == 0 )
		{
			g_bValidMap = false;
		} else {
			Format(sMap, sizeof(sMap), ",%s,", sMap);
			Format(sCvar, sizeof(sCvar), ",%s,", sCvar);

			if( StrContains(sCvar, sMap, false) != -1 )
			{
				g_bValidMap = false;
			}
		}
	}

	if(L4D_IsMissionFinalMap())
	{
		g_bValidMap = false;
	}


	if (g_bValidMap)
	{
		PrecacheSound("doors/latchlocked2.wav", true);
		PrecacheSound("doors/door_squeek1.wav", true);	
		PrecacheSound("ambient/alarms/klaxon1.wav", true);
		PrecacheSound("level/highscore.wav", true);

		if (!IsModelPrecached(MODEL_TANK))
		{
			PrecacheModel(MODEL_TANK, true);
		}

	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(0.5, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(0.5, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action tmrStart(Handle timer)
{
	if (g_bValidMap == false)
	{
		return;
	}

	iType = (lsType.IntValue == 0) ? GetRandomInt(1, 2) : lsType.IntValue;
	
	bAntiFarmInit = false;
	bLockdownInit = false;
	bLDFinished = false;
	bSurvivorsAssembleAlready = false;
	bRoundEnd = false;
	bSpawnTank = false;
	_iDoorOpeningTankInterval = 0;

	InitDoor();

	ResetPlugin();
}


public Action TC_ev_EntityKilled(Event event, const char[] name, bool dontBroadcast) 
{
	if (g_bValidMap == false || !bTankDemolitionAfter || !bLDFinished)
	{
		return;
	}

	if (IsPlayerTank(event.GetInt("entindex_killed")))
	{
		CreateTimer(1.5, Timer_SpawnTank, _,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_SpawnTank(Handle timer)
{
	if(RealFreePlayersOnInfected())
		CheatCommand(GetRandomClient(), "z_spawn_old", "tank auto");
	else
		ExecuteSpawn(true, 1);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	bRoundEnd = true;

	if (g_bValidMap == false)
	{
		return;
	}
	
	if (hAntiFarmTime != null)
	{
		bLockdownInit = true;
		delete hAntiFarmTime;
		
		CreateTimer(1.75, ForceEndLockdown,_, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		CreateTimer(1.5, ForceEndLockdown,_, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	CreateTimer(2.0, OrderShutDown,_,TIMER_FLAG_NO_MAPCHANGE);

	ResetPlugin();
}

public Action ForceEndLockdown(Handle timer)
{
	delete hLockdownTime;
	bLDFinished = true;
}

public Action OrderShutDown(Handle timer)
{
	SetCheckpointDoor_Default();
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bValidMap && bLDFinished && IsClientInGame(client) && GetClientTeam(client) == 2 && buttons & IN_USE)
	{
		if(IsFakeClient(client) && bDoorBotDisable) return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnPlayerUsePre(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bValidMap == false)
	{
		return Plugin_Continue;
	}
	
	int user = GetClientOfUserId(event.GetInt("userid"));
	if (IsSurvivor(user))
	{
		if (!IsPlayerAlive(user))
		{
			return Plugin_Continue;
		}
		if(bDoorBotDisable && IsFakeClient(user))
		{
			return Plugin_Continue;
		}
		
		int used = event.GetInt("targetid");
		if (IsValidEnt(used))
		{
			char sEntityClass[64];
			GetEdictClassname(used, sEntityClass, sizeof(sEntityClass));
			if (strcmp(sEntityClass, "prop_door_rotating_checkpoint") != 0 || used != iCheckpointDoor)
			{
				return Plugin_Continue;
			}
			
			if (iDoorStatus != UNLOCK)
			{
				if(bNearByAllSurvivor && !bSurvivorsAssembleAlready)
				{
					float clientOrigin[3];
					float doorOrigin[3];
					GetEntPropVector(used, Prop_Send, "m_vecOrigin", doorOrigin);
					for (int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
						{
							GetClientAbsOrigin(i, clientOrigin);
							if (GetVectorDistance(clientOrigin, doorOrigin, true) > 850 * 850)
							{
								PrintHintText(user, "[TS] Todos los supervivientes deben reunirse para abrir la puerta de seguridad！");
								PrintCenterTextAll("[TS] Todos los supervivientes deben reunirse para abrir la puerta de seguridad！");
								return Plugin_Continue;
							}
						}
					}
					bSurvivorsAssembleAlready = true;
				}

				if(bTankDemolitionBefore && !bSpawnTank) 
				{
					ExecuteSpawn(true , 1);
					bSpawnTank = true;
				}
				
				if (GetTankCount() > 0)
				{
					if (bLDFinished || bLockdownInit)
					{
						bAntiFarmInit = true;
						return Plugin_Continue;
					}
					
					
					if (!bAntiFarmInit)
					{
						bAntiFarmInit = true;
						iSystemTime = iAntiFarmDuration;
						
						PrintHintText(user, "[TS] TANK APARECE!");
						EmitSoundToAll("doors/latchlocked2.wav", used, SNDCHAN_AUTO);

						GetClientAbsOrigin(user, fFirstUserOrigin);
						GetClientName(user, sKeyMan, sizeof(sKeyMan));
						
						ExecuteSpawn(false, iMobs);
						
						if (hAntiFarmTime == null)
						{
							hAntiFarmTime = CreateTimer(float(iAntiFarmDuration) + 1.0, EndAntiFarm);
						}
						CreateTimer(1.0, CheckAntiFarm, used, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
						SDKHook(used, SDKHook_Touch, OnTouch);
					}
				}
				else
				{
					if (bAntiFarmInit)
					{
						return Plugin_Continue;
					}
					
					if (!bLockdownInit)
					{
						bLockdownInit = true;
						iSystemTime = iDuration;

						GetClientAbsOrigin(user, fFirstUserOrigin);
						GetClientName(user, sKeyMan, sizeof(sKeyMan));
						
						ExecuteSpawn(false, iMobs);
						if (iType == 1)
						{
							ControlDoor(iCheckpointDoor, UNLOCK);
						}
						
						if (hLockdownTime == null)
						{
							hLockdownTime = CreateTimer(float(iDuration) + 1.0, EndLockdown);
						}

						CreateTimer(1.0, LockdownOpening, used, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
						SDKHook(used, SDKHook_Touch, OnTouch);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action CheckAntiFarm(Handle timer, any entity)
{
	if (GetTankCount() < 1 || hAntiFarmTime == null)
	{
		delete hAntiFarmTime;
		
		if (!bLockdownInit)
		{
			bLockdownInit = true;
			ExecuteSpawn(false, iMobs);
			
			if (iType == 1)
			{
				ControlDoor(iCheckpointDoor, UNLOCK);
			}
			
			if (hLockdownTime == null)
			{
				hLockdownTime = CreateTimer(float(iDuration) + 1.0, EndLockdown);
			}
			iSystemTime = iDuration;
			CreateTimer(1.0, LockdownOpening, entity, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Stop;
	}
	
	PrintCenterTextAll("[ANTI-FARM] Espere %d segundos!", iSystemTime);
	iSystemTime -= 1;
	
	return Plugin_Continue;
}

public Action EndAntiFarm(Handle timer)
{
	hAntiFarmTime = null;
}

public Action LockdownOpening(Handle timer, any entity)
{
	if (hLockdownTime == null)
	{
		if (!bLDFinished)
		{
			bLDFinished = true;
			
			EmitSoundToAll("doors/door_squeek1.wav", entity);
			if (iType != 1)
			{
				ControlDoor(entity, UNLOCK);
			}
			else
			{
				SetEntPropFloat(entity, Prop_Data, "m_flSpeed", fDoorSpeed);
				SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
				AcceptEntityInput(entity, "Unlock");
				AcceptEntityInput(entity, "Close");
				AcceptEntityInput(entity, "ForceClosed");
				AcceptEntityInput(entity, "Open");
			}
			
			EmitSoundToAll("level/highscore.wav", entity, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			if(bAnnounce) PrintCenterTextAll("La puerta de seguridad esta abierta!! Entren!!");
			if(blsHint) PrintToChatAll("\x01[\x05TS\x01]\x04 <\x05%s\x04>\x01 abrió la puerta de la habitación segura!", sKeyMan);
			CreateTimer(5.0, LaunchTankDemolition, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(5.0, LaunchSlayTimer, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Stop;
	}
	
	PrintCenterTextAll("[LOCKDOWN] Cuenta regresiva para la apertura de la puerta %d segundos!", iSystemTime);
	EmitSoundToAll("ambient/alarms/klaxon1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);	


	iSystemTime --;

	if(iDoorOpeningTankInterval > 0 && _iDoorOpeningTankInterval >= iDoorOpeningTankInterval)
	{
		CreateTimer(0.1, Timer_SpawnTank, _,TIMER_FLAG_NO_MAPCHANGE);
		_iDoorOpeningTankInterval = 0;
	}
	_iDoorOpeningTankInterval++;

	return Plugin_Continue;
}

public Action EndLockdown(Handle timer)
{
	if (hLockdownTime == null)
	{
		return Plugin_Stop;
	}
	
	KillTimer(hLockdownTime);
	hLockdownTime = null;
	
	return Plugin_Stop;
}

public Action LaunchTankDemolition(Handle timer)
{
	if (bTankDemolitionAfter == false)
	{
		return;
	}
	
	ExecuteSpawn(true, 4);
	if (bAnnounce)
	{
		PrintToChatAll("\x01[\x05TS\x01]\x01 \x04Tank \x01aparecen en horda!!");
	}
}

public Action LaunchSlayTimer(Handle timer, any entity)
{
	iSystemTime = iGetInLimit;
	if(iSystemTime > 0) CreateTimer(1.0, AntiPussy, entity, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action AntiPussy(Handle timer, any entity)
{
	if(bRoundEnd) return Plugin_Stop;
	
	EmitSoundToAll("ambient/alarms/klaxon1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	PrintCenterTextAll("[LOCKDOWN] Cuenta regresiva para el rescate en el refugio en %d segundos!", iSystemTime);
	
	if(iSystemTime <= 0)
	{
		//AcceptEntityInput(entity, "Close");
		//AcceptEntityInput(entity, "ForceClosed");

		if(bAnnounce) PrintToChatAll("\x01[\x05TS\x01]\x05 El rescate llegara para los\x04jugadores en el refugio\x01!");
		
		CreateTimer(2.5, _AntiPussy, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	iSystemTime -= 1;
	return Plugin_Continue;
}

public Action _AntiPussy(Handle timer)
{
	if(bRoundEnd) return Plugin_Stop;
	
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !L4D_IsInLastCheckpoint(i))
		{
			ForcePlayerSuicide(i);
			if(bAnnounce) {
				PrintHintText(i, "[TS] Estás fuera del refugio，te rescataran luego!!");
				//PrintToChatAll("\x01[\x05TS\x01]\x04 <\x05%N\x04>\x01 位於安全室門外，已被處死!", i);
			}
		}
	}
	return Plugin_Continue;
}

public void OnMapEnd()
{
	bAntiFarmInit = false;
	bLockdownInit = false;
	bLDFinished = false;
	
	SetCheckpointDoor_Default();

	ResetPlugin();
}

void InitDoor()
{
	if (IsValidEnt(iCheckpointDoor))
	{
		return;
	}
	
	int iCheckpointEnt = -1;
	while ((iCheckpointEnt = FindEntityByClassname(iCheckpointEnt, "prop_door_rotating_checkpoint")) != -1)
	{
		if (!IsValidEntity(iCheckpointEnt))
		{
			continue;
		}
		
		char sEntityName[128];
		GetEntPropString(iCheckpointEnt, Prop_Data, "m_iName", sEntityName, sizeof(sEntityName));
		if (strcmp(sEntityName, "checkpoint_entrance", false) == 0)
		{
			if (sLastName[iCheckpointEnt][0] != '\0')
			{
				DispatchKeyValue(iCheckpointEnt, "targetname", sLastName[iCheckpointEnt]);
				sLastName[iCheckpointEnt][0] = '\0';
			}
			
			fDoorSpeed = GetEntPropFloat(iCheckpointEnt, Prop_Data, "m_flSpeed");
			
			ControlDoor(iCheckpointEnt, LOCK);
			
			HookSingleEntityOutput(iCheckpointEnt, "OnFullyOpen", OnDoorAntiSpam);
			HookSingleEntityOutput(iCheckpointEnt, "OnFullyClosed", OnDoorAntiSpam);
			
			HookSingleEntityOutput(iCheckpointEnt, "OnBlockedOpening", OnDoorBlocked);
			HookSingleEntityOutput(iCheckpointEnt, "OnBlockedClosing", OnDoorBlocked);
			
			iCheckpointDoor = iCheckpointEnt;

			break;
		}
		else if (g_bTwoSafeRoomDoorBug == false)
		{
			char sEntityModel[128];
			GetEntPropString(iCheckpointEnt, Prop_Data, "m_ModelName", sEntityModel, sizeof(sEntityModel));
			if ( strcmp(sEntityModel, MODEL_SAFEROOM_DOOR_1, false) == 0 || strcmp(sEntityModel, MODEL_SAFEROOM_DOOR_2, false) == 0 || strcmp(sEntityModel, MODEL_SAFEROOM_DOOR_3, false) == 0)
			{
				if (sEntityName[0] != '\0')
				{
					strcopy(sLastName[iCheckpointEnt], 128, sEntityName);
				}
				DispatchKeyValue(iCheckpointEnt, "targetname", "checkpoint_entrance");
				
				InitDoor();
				break;
			}
		}
	}
}

public void OnDoorAntiSpam(const char[] output, int caller, int activator, float delay)
{
	if (strcmp(output, "OnFullyClosed") == 0 && !bLDFinished)
	{
		return;
	}
	
	AcceptEntityInput(caller, "Lock");
	SetEntProp(caller, Prop_Data, "m_hasUnlockSequence", LOCK);
	
	L4D2_SetEntGlow(caller, L4D2Glow_Constant, iDoorGlowRange, 0, g_iDoorLockColors, false);
	
	CreateTimer(fPreventDoorSpamDuration, PreventDoorSpam, EntIndexToEntRef(caller), TIMER_FLAG_NO_MAPCHANGE);
}

public Action PreventDoorSpam(Handle timer, any entity)
{
	if (!entity || (entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	
	L4D2_SetEntGlow(entity, L4D2Glow_Constant, iDoorGlowRange, 0, g_iDoorUnlockColors, false);
	
	SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
	AcceptEntityInput(entity, "Unlock");
	
	return Plugin_Stop;
}

public void OnDoorBlocked(const char[] output, int caller, int activator, float delay)
{
	//PrintToChatAll("OnDoorBlockeding caller:%d, activator: %d, output: %s",caller,activator,output);
	if (!IsCommonInfected(activator))
	{
		return;
	}

	AcceptEntityInput(activator, "BecomeRagdoll");
}

void ControlDoor(int entity, int iOperation)
{
	iDoorStatus = iOperation;
	
	switch (iOperation)
	{
		case LOCK:
		{
			L4D2_SetEntGlow(entity, L4D2Glow_Constant, iDoorGlowRange, 0, g_iDoorLockColors, false);
			
			AcceptEntityInput(entity, "Close");
			if (iType == 1)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flSpeed", 89.0 / float(iDuration));
			}
			AcceptEntityInput(entity, "Lock");
			if (iType != 1)
			{
				AcceptEntityInput(entity, "ForceClosed");
			}
			SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", LOCK);
		}
		case UNLOCK:
		{
			L4D2_SetEntGlow(entity, L4D2Glow_Constant, iDoorGlowRange, 0, g_iDoorUnlockColors, false);
			
			SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
			AcceptEntityInput(entity, "Unlock");
			AcceptEntityInput(entity, "ForceClosed");
			AcceptEntityInput(entity, "Open");
		}
	}
}

int GetRandomClient()
{
	int iClientCount, iClients[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			iClients[iClientCount++] = i;
		}
	}
	return (iClientCount == 0) ? 0 : iClients[GetRandomInt(0, iClientCount - 1)];
}

int GetTankCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(i))
		{
			iCount += 1;
		}
	}
	return iCount;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity));
}

stock bool IsCommonInfected(int entity)
{
	if (IsValidEnt(entity))
	{
		char sEntityClass[64];
		GetEdictClassname(entity, sEntityClass, sizeof(sEntityClass));
		return strcmp(sEntityClass, "infected") == 0;
	}
	
	return false;
}

stock void ExecuteSpawn(bool btank, int iCount)
{
	if (btank)
	{
		CreateTankBot();
		iCount--;
		for (int i = 1; i <= iCount; i++)
		{
			CreateTimer(0.5 * i, Timer_CreateTank, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		int anyclient = GetRandomClient();
		if(anyclient > 0)
		{
			char sCommand[16];
			strcopy(sCommand, sizeof(sCommand), "z_spawn");
			int iFlags = GetCommandFlags(sCommand);
			SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
			for (int i = 0; i < iCount; i++)
			{
				FakeClientCommand(anyclient, "z_spawn mob auto");
			}
			SetCommandFlags(sCommand, iFlags);
		}	
	}
}

public Action Timer_CreateTank(Handle timer)
{
	CreateTankBot();	
}

void CreateTankBot()
{
	float vecPos[3];
	int anyclient = GetRandomClient();
	if(anyclient > 0 && L4D_GetRandomPZSpawnPosition(anyclient,8,5,vecPos) == true)
	{
		int newtankbot = SDKCall(hCreateTank, "Lock Down Tank Bot"); //召喚坦克
		if (newtankbot > 0 && IsValidClient(newtankbot))
		{
			SetEntityModel(newtankbot, MODEL_TANK);
			ChangeClientTeam(newtankbot, 3);
			SetEntProp(newtankbot, Prop_Send, "m_usSolidFlags", 16);
			SetEntProp(newtankbot, Prop_Send, "movetype", 2);
			SetEntProp(newtankbot, Prop_Send, "deadflag", 0);
			SetEntProp(newtankbot, Prop_Send, "m_lifeState", 0);
			SetEntProp(newtankbot, Prop_Send, "m_iObserverMode", 0);
			SetEntProp(newtankbot, Prop_Send, "m_iPlayerState", 0);
			SetEntProp(newtankbot, Prop_Send, "m_zombieState", 0);
			DispatchSpawn(newtankbot);
			ActivateEntity(newtankbot);
			TeleportEntity(newtankbot, vecPos, NULL_VECTOR, NULL_VECTOR); //移動到相同位置

			CreateTimer(3.0, AttackOnTank, GetClientUserId(newtankbot), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action AttackOnTank(Handle timer, int tank)
{
	tank = GetClientOfUserId(tank);
	if(tank && IsClientInGame(tank))
	{
		SetEntProp(tank, Prop_Send, "m_zombieState", 1);
		SetEntProp(tank, Prop_Send, "m_hasVisibleThreats", 1);
		DealDamage(tank, 0,  GetSurvivor(), DMG_BULLET, "weapon_smg");
	}
}

stock bool IsPlayerGhost(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

stock void CheatCommand(int client,  char[] command, char[] arguments = "")
{
	if(client == 0) return;
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

bool RealFreePlayersOnInfected ()
{
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3 && (IsPlayerGhost(i) || !IsPlayerAlive(i)))
			return true;
	}
	return false;
}

bool IsPlayerTank (int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

public void Event_DoorOpen(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetBool("checkpoint") )
		DoorPrint(event, true);
}

public void Event_DoorClose(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetBool("checkpoint") )
		DoorPrint(event, false);
}

void DoorPrint(Event event, bool open)
{
	if( bLDFinished && blsHint)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( client && IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			if(open) PrintToChatAll("\x01[\x05TS\x01]\x04 ---\x05%N\x04---\x01 Abre la puerta de seguridad!", client);
			else PrintToChatAll("\x01[\x05TS\x01]\x04 ---\x05%N\x04---\x01 Cierra la puerta de seguridad!", client);
		}
	}
}

void GetCvars()
{
	iAntiFarmDuration = lsAntiFarmDuration.IntValue;
	iDuration = lsDuration.IntValue;
	iMobs = lsMobs.IntValue;
	
	bAnnounce = lsAnnounce.BoolValue;
	bTankDemolitionBefore = lsTankDemolitionBefore.BoolValue;
	bTankDemolitionAfter = lsTankDemolitionAfter.BoolValue;
	bNearByAllSurvivor = lsNearByAllSurvivor.BoolValue;
	blsHint = lsHint.BoolValue;
	iGetInLimit = lsGetInLimit.IntValue;
	bDoorOpeningTeleport = lsDoorOpeningTeleport.BoolValue;
	iDoorOpeningTankInterval = lsDoorOpeningTankInterval.IntValue;
	bDoorBotDisable = lsDoorBotDisable.BoolValue;
	fPreventDoorSpamDuration = lsPreventDoorSpamDuration.FloatValue;
	iDoorGlowRange = lsDoorGlowRange.IntValue;
	
	char sColor[16];
	lsDoorLockColor.GetString(sColor, sizeof(sColor));
	GetColor(g_iDoorLockColors, sColor);
	lsDoorUnlockColor.GetString(sColor, sizeof(sColor));
	GetColor(g_iDoorUnlockColors, sColor);
}

public void OnTouch(int door, int other)
{
	if(!bDoorOpeningTeleport || iType == 1) return;

	if(bRoundEnd || bLDFinished)
	{
		SDKUnhook(door, SDKHook_Touch, OnTouch);
	}
	//PrintToChatAll("%d touches door %d",other,door);

	if (IsValidClient(other) && IsPlayerAlive(other) && GetClientTeam(other) != 1 && L4D_IsInLastCheckpoint(other))
	{
		TeleportEntity(other, fFirstUserOrigin, NULL_VECTOR, NULL_VECTOR);
		return;
	}

	if (IsCommonInfected(other))
	{
		TeleportEntity(other, fFirstUserOrigin, NULL_VECTOR, NULL_VECTOR);
		return;
	}

	if (IsWitch(other))
	{
		TeleportEntity(other, fFirstUserOrigin, NULL_VECTOR, NULL_VECTOR);
		return;
	}
}

bool IsWitch(int entity)
{
    if (entity > 0 && IsValidEntity(entity))
    {
        char strClassName[64];
        GetEdictClassname(entity, strClassName, sizeof(strClassName));
        return strcmp(strClassName, "witch") == 0;
    }
    return false;
}

void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

void SetCheckpointDoor_Default()
{
	if (iCheckpointDoor != 0)
	{
		if (IsValidEntity(iCheckpointDoor))
		{
			L4D2_SetEntGlow(iCheckpointDoor, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
			
			UnhookSingleEntityOutput(iCheckpointDoor, "OnFullyOpen", OnDoorAntiSpam);
			UnhookSingleEntityOutput(iCheckpointDoor, "OnFullyClosed", OnDoorAntiSpam);
			
			UnhookSingleEntityOutput(iCheckpointDoor, "OnBlockedOpening", OnDoorBlocked);
			UnhookSingleEntityOutput(iCheckpointDoor, "OnBlockedClosing", OnDoorBlocked);

			if (iType == 1)
			{
				SetEntPropFloat(iCheckpointDoor, Prop_Data, "m_flSpeed", fDoorSpeed);
			}
			
			iDoorStatus = UNLOCK;
		}
		
		iCheckpointDoor = 0;
	}
}

void GetColor(int[] array, char[] sTemp)
{
	if( StrEqual(sTemp, "") )
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if( color != 3 )
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}

	array[0] = StringToInt(sColors[0]);
	array[1] = StringToInt(sColors[1]);
	array[2] = StringToInt(sColors[2]);
}

public int GetSurvivor() {
	for( int i = 1; i <= MaxClients; i++ ) {
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) ) {
		    return i;
		}
	}

	return 0;
}

void DealDamage(int victim, int damage, int attacker = 0, int dmg_type = DMG_GENERIC, char[] weapon = "") {
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim)) {
		char dmg_str[16];
		IntToString(damage,dmg_str,16);
		char dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		int pointHurt=CreateEntityByName("point_hurt");
		if (pointHurt) {
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			
			if(!StrEqual(weapon,"")) {
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}

Handle hGameConf;
void GetGameData()
{
	hGameConf = LoadGameConfigFile("lockdown_system-l4d2");
	if( hGameConf != null )
	{
		PrepSDKCall();
	}
	else
	{
		SetFailState("Unable to find lockdown_system-l4d2.txt gamedata file.");
	}
	delete hGameConf;
}

void PrepSDKCall()
{
	//find create bot signature
	Address replaceWithBot = GameConfGetAddress(hGameConf, "NextBotCreatePlayerBot.jumptable");
	if (replaceWithBot != Address_Null && LoadFromAddress(replaceWithBot, NumberType_Int8) == 0x68) {
		// We're on L4D2 and linux
		PrepWindowsCreateBotCalls(replaceWithBot);
	}
	else
	{
		PrepCreateTankBotCalls();
	}
}

void LoadStringFromAdddress(Address addr, char[] buffer, int maxlength) {
	int i = 0;
	while(i < maxlength) {
		char val = LoadFromAddress(addr + view_as<Address>(i), NumberType_Int8);
		if(val == 0) {
			buffer[i] = 0;
			break;
		}
		buffer[i] = val;
		i++;
	}
	buffer[maxlength - 1] = 0;
}

Handle PrepCreateBotCallFromAddress(Handle hSiFuncTrie, const char[] siName) {
	Address addr;
	StartPrepSDKCall(SDKCall_Static);
	if (!GetTrieValue(hSiFuncTrie, siName, addr) || !PrepSDKCall_SetAddress(addr))
	{
		SetFailState("Unable to find NextBotCreatePlayer<%s> address in memory.", siName);
		return null;
	}
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	return EndPrepSDKCall();	
}

void PrepWindowsCreateBotCalls(Address jumpTableAddr) {
	Handle hInfectedFuncs = CreateTrie();
	// We have the address of the jump table, starting at the first PUSH instruction of the
	// PUSH mem32 (5 bytes)
	// CALL rel32 (5 bytes)
	// JUMP rel8 (2 bytes)
	// repeated pattern.
	
	// Each push is pushing the address of a string onto the stack. Let's grab these strings to identify each case.
	// "Hunter" / "Smoker" / etc.
	for(int i = 0; i < 7; i++) {
		// 12 bytes in PUSH32, CALL32, JMP8.
		Address caseBase = jumpTableAddr + view_as<Address>(i * 12);
		Address siStringAddr = view_as<Address>(LoadFromAddress(caseBase + view_as<Address>(1), NumberType_Int32));
		static char siName[32];
		LoadStringFromAdddress(siStringAddr, siName, sizeof(siName));

		Address funcRefAddr = caseBase + view_as<Address>(6); // 2nd byte of call, 5+1 byte offset.
		int funcRelOffset = LoadFromAddress(funcRefAddr, NumberType_Int32);
		Address callOffsetBase = caseBase + view_as<Address>(10); // first byte of next instruction after the CALL instruction
		Address nextBotCreatePlayerBotTAddr = callOffsetBase + view_as<Address>(funcRelOffset);
		//PrintToServer("Found NextBotCreatePlayerBot<%s>() @ %08x", siName, nextBotCreatePlayerBotTAddr);
		SetTrieValue(hInfectedFuncs, siName, nextBotCreatePlayerBotTAddr);
	}

	hCreateTank = PrepCreateBotCallFromAddress(hInfectedFuncs, "Tank");
	if (hCreateTank == null)
	{ SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateTank); return; }
}

void PrepCreateTankBotCalls() {
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, NAME_CreateTank))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_CreateTank); return; }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateTank = EndPrepSDKCall();
	if (hCreateTank == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_CreateTank); return; }
}