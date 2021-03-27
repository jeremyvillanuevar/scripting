#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Float:LastUserPos[MAXPLAYERS+1][3];
new JumpCount[MAXPLAYERS+1];
new bool:IsCharged[MAXPLAYERS+1];

#define PRINT_PREFIX "[DEBUG] "
#define POINT "models/w_models/weapons/w_eq_medkit.mdl"

public Plugin:myinfo = 
{
	name = "Block Suicide jumps",
	author = "spirit",
	description = "prevents players griefing by suicide",
	version = "1.0",
	url = ""
}
public OnPluginStart()
{	
	HookEvent("player_jump", player_jump);	
	HookEvent("player_spawn", player_spawn);
	
	HookEvent("charger_impact", charger_impact);
	HookEvent("lunge_pounce", charger_carry_start);
	HookEvent("pounce_end", charger_carry_end);
	HookEvent("charger_carry_start", charger_carry_start);
	HookEvent("charger_carry_end", charger_carry_end);
	HookEvent("charger_pummel_start", charger_carry_start);
	HookEvent("charger_pummel_end", charger_carry_end);
	HookEvent("jockey_ride", charger_carry_start);
	HookEvent("jockey_ride_end", charger_carry_end);
	HookEvent("tongue_grab", charger_carry_start);
	HookEvent("tongue_release", charger_carry_end);	
}
public Action:player_jump(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	//PrintToChat( client,"%s  jump event " , PRINT_PREFIX   );
	GetClientAbsOrigin(client,LastUserPos[client]);
}
public Action:charger_carry_start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));	
	IsCharged[victim] = true;	
}
public Action:charger_carry_end(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));	
	CreateTimer(1.0, reset, victim,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	//PrintToChatAll("%s %N released by infected",PRINT_PREFIX,victim);	
}

public Action:charger_impact(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));	
	if(IsCharged[victim] == false)
	{
		IsCharged[victim] = true;	
		CreateTimer(3.0, reset, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		//PrintToChatAll( "%s  %N dmg imune active " , PRINT_PREFIX , victim );
	}
}

public Action:reset(Handle:hTimer, any:client)
{
	if(!IsValidClient(client))
		return Plugin_Stop;
		
	new flags = GetEntityFlags(client);	
	
	if((flags & FL_ONGROUND) || IsIncapacitated(client) || !IsPlayerAlive(client) || client == 0 )
	{
		//PrintToChatAll("%s %N no longer imune from dmg",PRINT_PREFIX,client);
		IsCharged[client] = false;
		return Plugin_Stop;
	}	
	return Plugin_Continue;
}

public Action:player_spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client)!=2)
		return;
		
	//PrintToChat( client,"%s  spawn event " , PRINT_PREFIX   );
	GetClientAbsOrigin(client,LastUserPos[client]);
}

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		IsCharged[i] = false;
	}
}
public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
	IsCharged[client] = false;
	JumpCount[client] = 0;
	GetClientAbsOrigin(client,LastUserPos[client]);	
}
bool:IsTriggerHurt(attacker)
{
	char cname[64];
	GetEdictClassname(attacker, cname, sizeof(cname));
	if(StrContains(cname, "trigger_hurt", false) != -1)
	{
		return true;
	}
	return false;
}
PrintEntClass(ent)
{
	if(!IsValidEntity(ent))
	{PrintToChatAll("error");return;}
	char cname[64];
	GetEdictClassname(ent, cname, sizeof(cname));

	PrintToChatAll("class = %s",cname);

}
//[DEBUG]  dmg = 5000.000000 dmgtyp = 32 inf = 1048
public Action:OnTakeDamagePre(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{	
	//PrintToChat(victim,"%s dmg = %f dmgtyp = %d inf = %d",PRINT_PREFIX,damage,damagetype, inflictor);
	//PrintEntClass(attacker);
	if(IsTankHitable(inflictor) || IsCharged[victim] || GetClientTeam(victim ) != 2 )
	{
		// if is a tank hitable or player is charged or player not a survivour
		//do nothing
		return Plugin_Continue;
	}

	new health = GetClientHealth(victim) + GetClientTempHealth(victim);

	if(IsTriggerHurt(attacker) || (damagetype == 32 && damage > health))
	{
		RequestFrame( BlockSuicide, victim);
		damage = 0.0;
		return Plugin_Changed;	
	}
	
	if(IsTank(attacker) && (GetClientTeam(attacker)== 3 ))
	{
		//PrintToChatAll("%s %N hit by tank",PRINT_PREFIX, victim);
		IsCharged[victim] = true;	
		CreateTimer(2.0, reset, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		//return Plugin_Continue;
	}

	return Plugin_Continue;
}

public void BlockSuicide(int victim)
{	
	if(IsCharged[victim])
	{
		return;
	}
	// this stops the moving preventing them acidentally faling in after they are teleported
	new Float:vec[3];
	GetEntPropVector(victim, Prop_Data, "m_vecBaseVelocity", vec);
	NegateVector(vec);

	TeleportEntity(victim, LastUserPos[victim], NULL_VECTOR, vec);

	JumpCount[victim] += 1;	
	PrintToChat(victim,"Please Dont Try Killing Yourself, if you Dont Wanna Play Just Leave");
	if(JumpCount[victim] > 10)
	{
		//KickClientEx(client,"Have A Nice Day!");
		JumpCount[victim] = 0;
	}
}
stock GetClientTempHealth(int client)
{
    static Handle:painPillsDecayCvar = INVALID_HANDLE;
    if (painPillsDecayCvar == INVALID_HANDLE)
    {
        painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
        if (painPillsDecayCvar == INVALID_HANDLE)
        {
            return -1;
        }
    }

    new tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
    return tempHealth < 0 ? 0 : tempHealth;
}
// THIS IS NEEDED TO STOP THE DEATH CAMERA BUGGING OUT.
public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity > 0 && IsValidEntity(entity))
    {
        decl String:strClassName[64];
        GetEntityClassname(entity, strClassName, sizeof(strClassName));
        if(StrContains(strClassName, "point_deathfall_camera") != -1)
		{
			RequestFrame( DeleteCamera, entity);
		}
    }
}
public void DeleteCamera(int entity)
{
	AcceptEntityInput(entity, "Kill"); 
}

stock bool:IsValidClient(client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || GetClientTeam(client) != 3 )
    {
        return false; 
    }
    return IsClientInGame(client); 
} 
bool:IsIncapacitated(client)
{
	if(!IsValidClient(client))
		return false;
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}
bool:IsTank(client)
{
    if(IsValidClient(client))
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8  && GetClientTeam(client) == 3)
		return true;
	}
	return false;
}
public bool:IsTankHitable(entity)
{
	char className[64]; 
	GetEntityClassname(entity, className, 64);
	if ( StrEqual(className, "prop_physics") ) 
	{
		if (HasEntProp(entity, Prop_Send, "m_hasTankGlow") && GetEntProp(entity, Prop_Send, "m_hasTankGlow", 1)) 
		{
			return true;
		}
		
		else if ( StrEqual(className, "prop_car_alarm") ) 
		{
			return true;
		}	
	}
	return false;
}