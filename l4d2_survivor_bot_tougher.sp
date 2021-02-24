#include <sourcemod> 
#include <sdkhooks> 
#include <sdktools> 

float sbDamageMult = 0.0;
float sbDamageCommonMult = 0.0;
float sbDamageSpecialMult = 0.0;
bool commonhited[MAXPLAYERS + 1] = false;

public Plugin:myinfo =  
{ 
    name = "Tougher Survivor Bots", 
    author = "xQd, TBK Duy", 
    description = "Makes the survivor bots deal more damage against SIs and commons and be more resistant to damage", 
    version = "1.4", 
    url = "None" 
}; 

ConVar g_hDifficulty;
ConVar g_cvTsbEnable;
ConVar g_cvBwsEnable;

public OnPluginStart()
{ 
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("weapon_reload", Event_BotReload);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("weapon_fire", Event_FireStart);
	HookEvent("jockey_ride", JockeyDeathStop);
	
	g_hDifficulty = FindConVar("z_difficulty");
	if (g_hDifficulty != null)
	{
		g_hDifficulty.AddChangeHook(OnDifficultyCvarChange);
	}
	g_cvTsbEnable = CreateConVar("l4d_tsb_enable", "1", "1 = Enable Tougher Survivor Bots plugin effects, 0 = Disable the plugin's effects", _, true, 0.0, true, 1.0);
	g_cvBwsEnable = CreateConVar("l4d_bws_enable", "1", "1 = Enable Bots Slayer Witch plugin effects, 0 = Disable the plugin's effects", _, true, 0.0, true, 1.0);
	
	SetMultipliersBasedOnDifficulty();	
} 

public OnMapStart()
{
	SetMultipliersBasedOnDifficulty();
}

public OnClientPutInServer(client)
{ 
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
	SDKHook(client, SDKHook_StartTouchPost, OnEntityTouch);
} 

public OnEntityTouch(Touched_ent, client)
{
	if (1 <= client <= MaxClients && IsFakeClient(client))
	{
		if (1 <= Touched_ent <= MaxClients && GetEntProp(Touched_ent, Prop_Send, "m_zombieClass") == 3 && IsFakeClient(client))
		{
			commonhited[client] = true;
			new Float:vPos[3] = 0.0;
			GetClientAbsOrigin(client, vPos);
			StaggerClient(GetClientUserId(Touched_ent), vPos);
			PushCommonInfected(client, Touched_ent, vPos, "true", "silvershot");
		}
		if (1 <= Touched_ent <= MaxClients && GetEntProp(Touched_ent, Prop_Send, "m_zombieClass") == 6 && IsFakeClient(client))
		{
			commonhited[client] = true;
		}
	}
	return false;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (g_cvTsbEnable.IntValue > 0)
	{
		if(attacker > 0 && attacker <= MaxClients && IsClientConnected(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsFakeClient(attacker))
		{
			damage *= sbDamageSpecialMult; 
			return Plugin_Changed; 
		}
		if (victim > 0 && victim <= MaxClients && IsClientConnected(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsFakeClient(victim) && !IsClientIncapacitated(victim) && !(damagetype & DMG_BULLET)) 
		{
			if (damagetype & DMG_BURN)
				damage /= 1.5;
			
			damage *= sbDamageMult;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue; 
}  

public Action Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cvBwsEnable.IntValue > 0)
	{
		int attackerId = event.GetInt("attacker");
		int attacker = GetClientOfUserId(attackerId);
		if(attacker > 0 && attacker <= MaxClients && IsClientConnected(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsFakeClient(attacker))
		{
			int amount = event.GetInt("amount");
			int client = event.GetInt("entityid");
			int cur_health = GetEntProp(client, Prop_Data, "m_iHealth");
			int dmg_health = RoundToNearest(cur_health - amount*sbDamageCommonMult);	
			if(cur_health > 0)
			{
				SetEntProp(client, Prop_Data, "m_iHealth", dmg_health);
				if(IsValidWitch(client) && g_cvBwsEnable.IntValue > 0)
				{
					SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(cur_health - ((amount*3.0) + (GetConVarInt(FindConVar("z_witch_health"))*0.25))));
				}
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action JockeyDeathStop(Event event, const char[] name, bool dontBroadcast)
{
	int Jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsFakeClient(victim))
	{
		commonhited[victim] = true;
		if (GetRandomFloat(0.0, 100.0) <= 96.0)
		{
			new Float:vPos[3] = 0.0;
			GetClientAbsOrigin(victim, vPos);
			PushCommonInfected(victim, Jockey, vPos, "true", "silvershot");
			vPos[2] += 15.0;
			TeleportEntity(Jockey, vPos, NULL_VECTOR, NULL_VECTOR);
			new Handle:SuccessEvent = CreateEvent("player_shoved", false);
			SetEventInt(SuccessEvent, "attacker", GetClientUserId(victim));
			SetEventInt(SuccessEvent, "userid", GetClientUserId(Jockey));
			FireEvent(SuccessEvent, false);
			SetEntityMoveType(Jockey, MOVETYPE_WALK);
			StaggerClient(GetClientUserId(Jockey), vPos);
		}
	}
	return Plugin_Handled;
}

public Action Event_FireStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(weapon == -1)
	return;

	static char sWeapon[16];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	
	if(IsFakeClient(client))
	{
		switch(sWeapon[0])
		{
			case 'p':
			{
				if (StrEqual(sWeapon, "pumpshotgun"))
					commonhited[client] = true;
			}
			case 's':
			{
				if (StrEqual(sWeapon, "shotgun_chrome"))
					commonhited[client] = true;
				else if (StrEqual(sWeapon, "sniper_awp"))
					commonhited[client] = true;
				else if (StrEqual(sWeapon, "sniper_scout"))
					commonhited[client] = true;				
			}
		}
	}
}

public Action Event_BotReload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client))
	{
		int giveFlags = GetCommandFlags("give");
		SetCommandFlags("give", giveFlags ^ FCVAR_CHEAT);
		char giveCommand[128];
		Format(giveCommand, sizeof(giveCommand), "give %s", "ammo");
		FakeClientCommand(client, giveCommand);
		new String:sWeapon[64];
		new Weapon = GetPlayerWeaponSlot(client, 0);
		if (Weapon != -1)
		{
			GetEntityClassname(Weapon, sWeapon, 64);
		}
		SetCommandFlags("give", giveFlags | FCVAR_CHEAT);
		new String:classname[64];
		giveFlags = GetCommandFlags("upgrade_add");
		SetCommandFlags("upgrade_add", giveFlags & -16385);
		if (GetPlayerWeaponSlot(client, 3) != -1 && GetPlayerWeaponSlot(client, 0) != -1)
		{
			GetEntityClassname(GetPlayerWeaponSlot(client, 3), classname, 64);
			if (StrEqual(classname, "weapon_upgradepack_explosive", false))
			{
				Format(giveCommand, 128, "upgrade_add %s", "EXPLOSIVE_AMMO");
			}
			else
			{
				if (StrEqual(classname, "weapon_upgradepack_incendiary", false))
				{
					Format(giveCommand, 128, "upgrade_add %s", "INCENDIARY_AMMO");
				}
			}
			FakeClientCommand(client, giveCommand);
		}
		SetCommandFlags("give", giveFlags | FCVAR_CHEAT);
	}
}

public Action OnPlayerRunCmd(client, &buttons)
{
	if (IsFakeClient(client))
	{
		if (commonhited[client] == true && GetEntProp(client, Prop_Send,"m_reviveTarget") < 1) 
		{
			buttons += IN_ATTACK2;
			commonhited[client] = false;
			return Plugin_Changed;
		}
		commonhited[client] = false;
		for(new i = 1; i <= GetEntityCount(); i++)
		{
			if (IsValidCommon(i))
			{					
				new Float:pos1[3] = 0.0;
				new Float:pos2[3] = 0.0;
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos1, false);
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2, false);
				if (GetVectorDistance(pos1, pos2, false) <= 35)
				{
					commonhited[client] = true;	
					PushCommonInfected(client, i, pos1, "true", "silvershot");
				}
			}
		}
	}
	
	return Plugin_Continue;
}	

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	SetMultipliersBasedOnDifficulty();
	
	return Plugin_Continue;
}

public void OnDifficultyCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{	
	SetMultipliersBasedOnDifficulty();
}	

public void SetMultipliersBasedOnDifficulty()
{
	char sDifficulty[128];
 
	g_hDifficulty.GetString(sDifficulty, 128);
 
	if (strcmp(sDifficulty, "easy", false) == 0)
	{
		sbDamageMult = 1.0
		sbDamageSpecialMult = 1.0
		sbDamageCommonMult = 1.25
	}
	else if (strcmp(sDifficulty, "normal", false) == 0)
	{
		sbDamageMult = 0.75
		sbDamageSpecialMult = 1.10
		sbDamageCommonMult = 1.50
	}
	else if (strcmp(sDifficulty, "hard", false) == 0)
	{
		sbDamageMult = 0.50
		sbDamageSpecialMult = 1.20
		sbDamageCommonMult = 1.75
	}
	else if (strcmp(sDifficulty, "impossible", false) == 0)
	{
		sbDamageMult = 0.25
		sbDamageSpecialMult = 1.30
		sbDamageCommonMult = 2.0
	}
	else
	{
		sbDamageMult = 0.75
		sbDamageSpecialMult = 1.10
		sbDamageCommonMult = 1.50
	}
}

public bool:IsClientIncapacitated(client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}

stock IsValidWitch(common)
{
	if(common > MaxClients && IsValidEdict(common) && IsValidEntity(common))
	{
		char classname[32];
		GetEdictClassname(common, classname, sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			return true;
		}
	}	
	return false;
}

stock IsValidCommon(common)
{
	if(common > MaxClients && IsValidEdict(common) && IsValidEntity(common))
	{
		char classname[32];
		GetEdictClassname(common, classname, sizeof(classname));
		if(StrEqual(classname, "infected"))
		{
			return true;
		}
	}	
	return false;
}

stock PushCommonInfected(client, target, Float:vPos[3], String:dam[128], String:damtype[128])
{
	int entity = CreateEntityByName("point_hurt", -1);
	DispatchKeyValue(target, "targetname", "silvershot");
	DispatchKeyValue(entity, "DamageTarget", "silvershot");
	DispatchKeyValue(entity, "Damage", dam);
	DispatchKeyValue(entity, "DamageType", damtype);
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "Hurt", client);
	RemoveEdict(entity);
}

StaggerClient(iUserID, const Float:fPos[3])
{
	static iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			LogError("Could not create 'logic_script");
		
		DispatchSpawn(iScriptLogic);
	}
	
	static String:sBuffer[96];
	Format(sBuffer, sizeof(sBuffer), "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", iUserID, RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
	SetVariantString(sBuffer); 	
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
	AcceptEntityInput(iScriptLogic, "Kill");
}