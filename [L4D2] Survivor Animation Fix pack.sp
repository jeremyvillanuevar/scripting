// Thanks to GAMMACASE for solving the post-hook detour crashing!

#define PLUGIN_NAME "[L4D2] Survivor Animation Fix Pack"
#define PLUGIN_AUTHOR "DeathChaos25, Shadowysn"
#define PLUGIN_DESC "A few quality of life animation fixes for the survivors"
#define PLUGIN_VERSION "1.7"
#define PLUGIN_URL ""
// Added AlternateIncap
#define GAMEDATA "l4d2_sequence"

#include <sourcemod>
#include <dhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"
#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"

#define PARAM_ACT_INCAP_IDLE 700
#define PARAM_ACT_INCAP_IDLE_ELITES 701

//static int incapped[MAXPLAYERS + 1] = 0;
//static Handle incapTimer[MAXPLAYERS+1] = null;
static bool pounced[MAXPLAYERS + 1] = false;
static bool charged[MAXPLAYERS + 1] = false;

//ConVar IncapAnims;
ConVar AlternateIncap;
//ConVar CoachEnabled;
//ConVar MeleeEnabled;
//ConVar MilitaryEnabled;
ConVar PistolEnabled;
ConVar PounceEnabled;
//ConVar RifleEnabled;
ConVar IncapChargeEnabled;
//ConVar CrawlEnabled;

Handle hConf = null;

Handle sdkDoAnim;
//Handle sdkGetSeqFromString;
Handle hSequenceSet;

#define NAME_SelectWeightedSequence "CTerrorPlayer::SelectWeightedSequence"
#define SIG_SelectWeightedSequence_LINUX "@_ZN13CTerrorPlayer22SelectWeightedSequenceE8Activity"
#define SIG_SelectWeightedSequence_WINDOWS "\\x55\\x8B\\x2A\\x56\\x57\\x8B\\x2A\\x2A\\x8B\\x2A\\x81\\x2A\\x2A\\x2A\\x2A\\x2A\\x75\\x2A"

#define NAME_DoAnimationEvent "CTerrorPlayer::DoAnimationEvent"
#define SIG_DoAnimationEvent_LINUX "@_ZN13CTerrorPlayer16DoAnimationEventE17PlayerAnimEvent_ti"
#define SIG_DoAnimationEvent_WINDOWS "\\x55\\x8B\\x2A\\x56\\x8B\\x2A\\x2A\\x57\\x8B\\x2A\\x83\\x2A\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A"

/*#define NAME_LookupSequence "CBaseAnimating::LookupSequence"
#define SIG_LookupSequence_LINUX "@_ZN14CBaseAnimating14LookupSequenceEPKc"
#define SIG_LookupSequence_WINDOWS "\\x55\\x8B\\x2A\\x56\\x8B\\x2A\\x83\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x75\\x2A\\xE8\\x7C\\xE0"*/
//#define OFFSET_SelectWeightedSequence_LINUX 207
//#define OFFSET_SelectWeightedSequence_WINDOWS 206
//#define OFFSET_DoAnimationEvent_LINUX 510
//#define OFFSET_DoAnimationEvent_WINDOWS 509

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	HookEvent("weapon_reload", Event_Reload);
	HookEvent("lunge_pounce", Event_Pounced);
	HookEvent("charger_carry_end", Event_CarryEnd);
	GetGamedata();
	PrepSDKCall();
	
	//RegAdminCmd("sm_incapsetanim", Command_SetAnim, ADMFLAG_ROOT, "Set the animation the incap uses.");
	RegAdminCmd("sm_testsetanim", Command_TestSetAnim, ADMFLAG_ROOT, "Set animation of yourself.");
	RegAdminCmd("sm_testgetseq", Command_TestGetSeq, ADMFLAG_ROOT, "Get animation of player's model from a string.");
	
	//IncapAnims = CreateConVar("enable_l4d1_incap_anims_fix", "1", "Fix missing collapse_to_incap animation for Louis/Bill/Francis?", FCVAR_NONE, true, 0.0, true, 1.0);
	AlternateIncap = CreateConVar("enable_alternate_incap_anims", "0", "Use IncapFrom_Charger for incap anims?", FCVAR_NONE, true, 0.0, true, 1.0);
	//CoachEnabled = CreateConVar("enable_coach_anim_fix", "1", "Fix Coach's Single Pistol/Magnum running animation?", FCVAR_NONE, true, 0.0, true, 1.0);
	//MeleeEnabled = CreateConVar("enable_zoey_hurtidlemelee_anim_fix", "1", "Fix broken Zoey idle_injured_frying_pan animations?", FCVAR_NONE, true, 0.0, true, 1.0);
	//MilitaryEnabled = CreateConVar("enable_military_anim_fix", "1", "Replace military sniper anims with more fitting versions?", FCVAR_NONE, true, 0.0, true, 1.0);
	PistolEnabled = CreateConVar("enable_empty_pistol_anim_fix", "1", "Fix missing animation for empty pistol reloads?", FCVAR_NONE, true, 0.0, true, 1.0);
	PounceEnabled = CreateConVar("enable_pounce_anim_fix", "1", "Restore pounced to ground animation from original game?", FCVAR_NONE, true, 0.0, true, 1.0);
	//RifleEnabled = CreateConVar("enable_rifle_anim_fix", "1", "Replace Francis and Louis' broken rifle idle anims?", FCVAR_NONE, true, 0.0, true, 1.0);
	IncapChargeEnabled = CreateConVar("enable_charge_incap_anim_fix", "1", "Restore IncapFrom_Charger animation in the most likely event?", FCVAR_NONE, true, 0.0, true, 1.0);
	//CrawlEnabled = CreateConVar("enable_crawl_anim_fix", "1", "Restore crawling animation for incapped survivors?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "l4d2_animations_fix");
	LoadOffset();
}

/*public void OnPluginEnd()
{
	UnloadOffset();
}*/

Action Command_TestSetAnim(int client, any args)
{
	if (args < 3 || args > 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_testsetanim <player> <number> <set>");
		return Plugin_Handled;
	}
	char player[64];
	char num[64];
	char set[64];
	GetCmdArg(1, player, sizeof(player));
	GetCmdArg(2, num, sizeof(num));
	GetCmdArg(3, set, sizeof(set));
	int int_set = StringToInt(set);
	int player_id = FindTarget(client, player);
	
	SDKCall(sdkDoAnim, player_id, num, int_set);
	return Plugin_Handled;
}

Action Command_TestGetSeq(int client, any args)
{
	if (args < 2 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_testgetseq <player> <string>");
		return Plugin_Handled;
	}
	char player[64];
	char str[64];
	GetCmdArg(1, player, sizeof(player));
	GetCmdArg(2, str, sizeof(str));
	int player_id = FindTarget(client, player);
	
	PrintToChatAll("%s: %i", str, GetAnimation(player_id, str));
	return Plugin_Handled;
}

Action Event_Reload(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(PistolEnabled))
	return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!RealValidEntity(weapon)) return;
	char wepstring[64];
	GetEntityClassname(weapon, wepstring, sizeof(wepstring));
	int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	if (IsSurvivor(client) && !IsPlayerHeld(client) && (clip <= 0 || IsDualWielding(client) && clip <= 1) &&
	(StrEqual(wepstring, "weapon_pistol") || StrEqual(wepstring, "weapon_pistol_magnum")) )
	{
		SDKCall(sdkDoAnim, client, 4, 1);
	}
	//else reloading[client] = false;
}

Action Event_CarryEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(IncapChargeEnabled))
	return;
	
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsSurvivor(victim))
	{
		charged[victim] = true;
		CreateTimer(1.5, SETFALSE_CHARGE, victim);
	}
	else charged[victim] = false;
}
Action SETFALSE_CHARGE(Handle timer, int client)
{
	if (IsSurvivor(client))
	{
		charged[client] = false;
		//SDKCall(sdkDoAnim, client, 92, 0);
	}
}

Action Event_Pounced(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(PounceEnabled))
	return;
	
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsSurvivor(victim))
	{
		pounced[victim] = true;
		CreateTimer(0.9, SETFALSE_POUNCE, victim);
	}
	else pounced[victim] = false;
}
Action SETFALSE_POUNCE(Handle timer, int client)
{
	if (IsSurvivor(client))
	{
		pounced[client] = false;
		//SDKCall(sdkDoAnim, client, 92, 0);
	}
}

/*Action Incap_StopAnimation(Handle timer, int client)
{
	incapTimer[client] = null;
	if (!RealValidEntity(client) || !IsClientInGame(client)) return;
	if (IsSurvivor(client))
	{
		incapped[client] = 1;
		//incapped[client] = 3;
		//CreateTimer(1.0, Incap_StopAnimation2, client);
	}
}*/

public MRESReturn OnSequenceSet_Pre(int client, Handle hReturn, Handle hParams)
{
	/*if (!RealValidEntity(client) || !IsPlayerAlive(client) || !IsSurvivor(client)) return MRES_Ignored;
	int param = DHookGetParam(hParams, 1);
	if (incapped[client])
	{
		if (param == 20)
		{
			if (IsDualWielding(client))
			{ DHookSetParam(hParams, 1, PARAM_ACT_INCAP_IDLE_ELITES); }
			else
			{ DHookSetParam(hParams, 1, PARAM_ACT_INCAP_IDLE); }
			return MRES_ChangedHandled;
		}
	}
	return MRES_Ignored;*/
} // We need this pre hook even though it's empty, or else the post hook will crash the game.

//static int ReceivedAnim[MAXPLAYERS + 1] = -1;
public MRESReturn OnSequenceSet(int client, Handle hReturn, Handle hParams)
{
	if (!RealValidEntity(client) || !IsPlayerAlive(client) || !IsSurvivor(client)) return MRES_Ignored;
	int sequence = DHookGetReturn(hReturn);
	//int param = DHookGetParam(hParams, 1);
	//PrintToChat(client, "%i", param);
	if (IsSurvivor(client) && IsPlayerAlive(client))
	{
		if (GetConVarBool(PounceEnabled) && sequence == GetPounceIdleSequence(client) && pounced[client])
		{
			int pouncer = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
			if (RealValidEntity(pouncer) && IsInfected(pouncer) && IsPlayerAlive(pouncer))
			{
				int pounce = GetPounceSequence(client);
				if (pounce > -1)
				{
					//float angles[3];
					//GetClientAbsAngles(pouncer, angles);
					//float new_ang[3];
					//if (angles[1] > 0)
					//{ new_ang[1] = angles[1]-180; }
					//else if (angles[1] <= 0)
					//{ new_ang[1] = angles[1]+180; }
					//SetEntPropVector(client, Prop_Send, "m_angRotation", new_ang);
					DHookSetReturn(hReturn, pounce);
					return MRES_Override;
				}
			}
		}
		else if (GetConVarBool(IncapChargeEnabled) && (charged[client] || GetConVarBool(AlternateIncap)) && !IsPlayerHeld(client) && 
		IsIncapacitated(client) && IsInIncapSequence(client, sequence))
		{
			int incapfrom = GetAnimation(client, "ACT_TERROR_CHARGER_PUMMELED");
			if (incapfrom > -1)
			{
				DHookSetReturn(hReturn, incapfrom);
				return MRES_Override;
			}
		}
	}
	//PrintToChatAll("%i", incapped[client]);
	if (IsSurvivor(client) && IsPlayerAlive(client) && !IsPlayerHeld(client))
	{
		//if (sequence != ReceivedAnim[client])
		//{ PrintToChat(client, "m_nSequence %i", sequence); }
		//ReceivedAnim[client] = sequence;
//		if (ShouldRemoveIncappedTag(client, sequence))
//		{
//			if (incapped[client])
//			{ incapped[client] = 0; }
//		}
//		if (!IsMaleL4D1Character(client) || !IsIncapacitated(client) || !GetConVarBool(IncapAnims))
//		{
//			if (incapped[client])
//			{ incapped[client] = 0; }
//			if (IsMaleL4D1Character(client) && incapTimer[client] != null)
//			{ KillTimer(incapTimer[client]); incapTimer[client] = null; }
//		}
//		if (IsMaleL4D1Character(client) && IsIncapacitated(client) && GetConVarBool(IncapAnims))
//		{
//			//PrintToChatAll("m_nSequence %i", sequence);
//			if (incapped[client] <= 0 && incapTimer[client] != null)
//			{ KillTimer(incapTimer[client]); incapTimer[client] = null; }
//			/*if (incapped[client] == 1 && sequence == -1)
//			{
//				int incap = -1;
//				if (IsDualWielding(client))
//				{ incap = GetAnimation(client, "ACT_IDLE_INCAP_ELITES"); }
//				else
//				{ incap = GetAnimation(client, "ACT_IDLE_INCAP_PISTOL"); }
//				//int incap = GetAnimation(client, "ACT_DIE_INCAP");
//				if (incap != -1)
//				{
//					DHookSetReturn(hReturn, incap);
//					return MRES_Override;
//				}
//			}
//			else*/
//			if ((incapped[client] != 1 || sequence != -1) && incapTimer[client] == null)
//			{
//				int incap = GetIncapSequence(client);
//				if (incap != -1 && sequence == -1)
//				{
//					DHookSetReturn(hReturn, incap);
//					if (incapped[client] <= 0 && incapTimer[client] == null)
//					{ incapTimer[client] = CreateTimer(2.75, Incap_StopAnimation, client); }
//					incapped[client] = 2;
//					return MRES_Override;
//				}
//			}
//			
//			//int incap = GetIncapSequence(client);
//			//if (incap != -1 && sequence == -1)
//			//{
//			//	DHookSetReturn(hReturn, incap);
//			//	return MRES_Override;
//			//}
//		}
		/*else if (IsIncapacitated(client) && GetConVarBool(CrawlEnabled) && IsCrawling(client))
		{
			int incap0 = GetAnimation(client, "ACT_IDLE_INCAP");
			int incap1 = GetAnimation(client, "ACT_IDLE_INCAP_PISTOL");
			int incap2 = GetAnimation(client, "ACT_IDLE_INCAP_ELITES");
			if ((incap0 > 0 && sequence == incap0) || (incap1 > 0 && sequence == incap1) || 
			(incap2 > 0 && sequence == incap2))
			{
				int crawl = GetAnimation(client, "ACT_TERROR_INCAP_CRAWL");
				if (crawl > 0)
				{
					DHookSetReturn(hReturn, crawl);
					//float eye_ang[3];
					//GetClientEyeAngles(client, eye_ang);
					//eye_ang[0] = 0.0; eye_ang[2] = 0.0;
					//SetEntPropVector(client, Prop_Send, "m_angRotation", eye_ang);
					//float pos[3];
					//GetClientAbsOrigin(client, pos);
					//pos[2] -= 1.0;
					//TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
					return MRES_Override;
				}
			}
		}*/
		/*else if (sequence == GetAnimation(client, "ACT_IDLE_INJURED_FRYINGPAN") && GetConVarBool(MeleeEnabled)) // 581
		{
			char model[64];
			GetClientModel(client, model, sizeof(model));
			if (StrEqual(model, MODEL_ZOEY, false))
			{
				//PrintToChatAll("FRYING");
				DHookSetReturn(hReturn, GetAnimation(client, "ACT_IDLE_FRYINGPAN")); // 571
				//DHookSetReturn(hReturn, 571);
				return MRES_Override;
			}
		}*/
		/*else if (IsMaleL4D1Character(client) && (GetConVarBool(MilitaryEnabled) || GetConVarBool(RifleEnabled)))
		{
			char model[64];
			GetClientModel(client, model, sizeof(model));
			// Military start
			if (GetConVarBool(MilitaryEnabled))
			{
				// Specific models
				if (StrEqual(model, MODEL_BILL, false))
				{
					if (sequence == GetAnimation(client, "ACT_WALK_SNIPER_MILITARY")) // Walk
					{
						DHookSetReturn(hReturn, GetAnimation(client, "ACT_WALK_PUMPSHOTGUN")); // Walk with PumpShotgun
						return MRES_Override;
					}
					else if (sequence == GetAnimation(client, "ACT_RUN_INJURED_SNIPER_MILITARY")) // Limp Run
					{
						DHookSetReturn(hReturn, GetAnimation(client, "ACT_RUN_INJURED_PUMPSHOTGUN")); // Limp Run with PumpShotgun 
						return MRES_Override;
					}
					else if (sequence == GetAnimation(client, "ACT_WALK_INJURED_SNIPER_MILITARY")) // Limp Walk
					{
						DHookSetReturn(hReturn, GetAnimation(client, "ACT_WALK_INJURED_PUMPSHOTGUN")); // Limp Walk with PumpShotgun 
						return MRES_Override;
					}
				}
				else if (StrEqual(model, MODEL_FRANCIS, false))
				{
					if (sequence == GetAnimation(client, "ACT_WALK_SNIPER_MILITARY")) // Walk
					{
						DHookSetReturn(hReturn, GetAnimation(client, "ACT_WALK_SHOTGUN")); // Walk with Shotgun
						return MRES_Override;
					}
					else if (sequence == GetAnimation(client, "ACT_RUN_INJURED_SNIPER_MILITARY")) // Limp Run
					{
						DHookSetReturn(hReturn, GetAnimation(client, "ACT_RUN_INJURED_SNIPER")); // Limp Run with Hunting Rifle
						return MRES_Override;
					}
					else if (sequence == GetAnimation(client, "ACT_WALK_INJURED_SNIPER_MILITARY")) // Limp Walk
					{
					DHookSetReturn(hReturn, GetAnimation(client, "ACT_WALK_INJURED_PUMPSHOTGUN")); // Limp Walk with PumpShotgun
					return MRES_Override;
					}
				}
				else if (StrEqual(model, MODEL_LOUIS, false))
				{
					if (sequence == GetAnimation(client, "ACT_WALK_SNIPER_MILITARY")) // Walk
					{
						DHookSetReturn(hReturn, GetAnimation(client, "ACT_WALK_PUMPSHOTGUN")); // Walk with PumpShotgun
						return MRES_Override;
					}
					else if (sequence == GetAnimation(client, "ACT_RUN_INJURED_SNIPER_MILITARY")) // Limp Run
					{
						DHookSetReturn(hReturn, GetAnimation(client, "ACT_RUN_INJURED_SNIPER")); // Limp Run with Hunting Rifle
						return MRES_Override;
					}
					else if (sequence == GetAnimation(client, "ACT_WALK_INJURED_SNIPER_MILITARY")) // Limp Walk
					{
						DHookSetReturn(hReturn, GetAnimation(client, "ACT_WALK_INJURED_SNIPER")); // Limp Walk with Hunting Rifle
						return MRES_Override;
					}
				}
				// General
				if (sequence == GetAnimation(client, "ACT_IDLE_SNIPER_MILITARY")) // Idle
				{
					DHookSetReturn(hReturn, GetAnimation(client, "ACT_IDLE_SHOTGUN")); // Idle with Shotgun (Hunting Rifle caused clipping issues)
					return MRES_Override;
				}
				else if (sequence == GetAnimation(client, "ACT_IDLE_CALM_SNIPER_MILITARY")) // Idle Calm
				{
					DHookSetReturn(hReturn, GetAnimation(client, "ACT_IDLE_CALM_SNIPER")); // Idle Calm with Hunting Rifle
					return MRES_Override;
				}
				else if (sequence == GetAnimation(client, "ACT_IDLE_INJURED_SNIPER_MILITARY")) // Idle Injured
				{
					DHookSetReturn(hReturn, GetAnimation(client, "ACT_IDLE_INJURED_PUMPSHOTGUN")); // Idle Injured with PumpShotgun (Hunting Rifle caused clipping issues)
					return MRES_Override;
				}
				else if (sequence == GetAnimation(client, "ACT_RUN_SNIPER_MILITARY")) // Run
				{
					DHookSetReturn(hReturn, GetAnimation(client, "ACT_RUN_PUMPSHOTGUN")); // Run with PumpShotgun (Hunting Rifle caused clipping issues)
					return MRES_Override;
				}
				else if (sequence == GetAnimation(client, "ACT_RUN_CALM_SNIPER_MILITARY")) // Calm Run
				{
					DHookSetReturn(hReturn, GetAnimation(client, "ACT_RUN_CALM_PUMPSHOTGUN")); // Calm Run with PumpShotgun
					return MRES_Override;
				}
				else if (sequence == GetAnimation(client, "ACT_WALK_CALM_SNIPER_MILITARY")) // Calm Walk
				{
					DHookSetReturn(hReturn, GetAnimation(client, "ACT_WALK_CALM_PUMPSHOTGUN")); // Calm Walk with PumpShotgun
					return MRES_Override;
				}
			}
			// Military end
			
			// Rifle start
		//	if (GetConVarBool(RifleEnabled) && 
		//	(StrEqual(model, MODEL_FRANCIS, false) || StrEqual(model, MODEL_LOUIS, false)) )
		//	{
		//		if (sequence == GetAnimation(client, "ACT_IDLE_RIFLE"))
		//		{
		//			DHookSetReturn(hReturn, GetAnimation(client, "ACT_IDLE_SHOTGUN"));
		//			return MRES_Override;
		//		}
		//		else if (sequence == GetAnimation(client, "ACT_RUN_RIFLE"))
		//		{
		//			DHookSetReturn(hReturn, GetAnimation(client, "ACT_RUN_PUMPSHOTGUN"));
		//			return MRES_Override;
		//		}
		//		else if (sequence == GetAnimation(client, "ACT_WALK_RIFLE"))
		//		{
		//			DHookSetReturn(hReturn, GetAnimation(client, "ACT_WALK_SHOTGUN"));
		//			return MRES_Override;
		//		}
		//	}
			// Rifle end
		}*/
		/*else if (!IsIncapacitated(client) && GetConVarBool(CoachEnabled))
		{
			char model[64];
			GetClientModel(client, model, sizeof(model));
			if (StrEqual(model, MODEL_COACH, false))
			{
				if (sequence == 202 && GetConVarBool(CoachEnabled))
				{
					DHookSetReturn(hReturn, GetAnimation(client, "ACT_RUN_SMG")); //Run_SMG 227
					//DHookSetReturn(hReturn, 227); //Run_SMG
					return MRES_Override;
				}
			}
		}*/
	}
	return MRES_Ignored;
}

/*bool ShouldRemoveIncappedTag(int client, int sequence)
{
	if (!incapped[client]) return false;
	if (sequence == GetAnimation(client, "ACT_IDLE_INCAP_PISTOL") || sequence == GetAnimation(client, "ACT_IDLE_INCAP_ELITES") || 
	sequence == GetAnimation(client, "ACT_IDLE_INCAP")) return false;
	
	if (
	-1 == sequence || GetAnimation(client, "ACT_PRIMARYATTACK_PISTOL") == sequence ||
	GetAnimation(client, "ACT_TERROR_JUMP_LANDING") == sequence ||
	GetAnimation(client, "ACT_DIESIMPLE") == sequence || GetAnimation(client, "Death") == sequence ||
	GetAnimation(client, "Flinch_01") == sequence || GetAnimation(client, "Flinch_02") == sequence ||
	GetAnimation(client, "Flinch_03") == sequence ||
	
	//GetAnimation(client, "ACT_RELOAD_grenade_launcher") == sequence || GetAnimation(client, "ACT_RELOAD_M4") == sequence ||
	//GetAnimation(client, "ACT_RELOAD_PUMPSHOTGUN_END") == sequence || GetAnimation(client, "Reload_Standing_PumpShotgun_loop1") == sequence ||
	//GetAnimation(client, "Reload_Standing_PumpShotgun_loop2") == sequence || GetAnimation(client, "Reload_Standing_PumpShotgun_loop3") == sequence ||
	//GetAnimation(client, "ACT_RELOAD_PUMPSHOTGUN_START") == sequence || GetAnimation(client, "ACT_RELOAD_RIFLE") == sequence ||
	//GetAnimation(client, "ACT_RELOAD_SHOTGUN_END") == sequence || GetAnimation(client, "Reload_Standing_Shotgun_loop1") == sequence ||
	//GetAnimation(client, "Reload_Standing_Shotgun_loop2") == sequence || GetAnimation(client, "Reload_Standing_Shotgun_loop3") == sequence ||
	//GetAnimation(client, "ACT_RELOAD_SHOTGUN_START") == sequence || GetAnimation(client, "ACT_RELOAD_SMG") == sequence ||
	GetAnimation(client, "ACT_RELOAD_PISTOL") == sequence || GetAnimation(client, "ACT_RELOAD_ELITES") == sequence ||
	
	GetAnimation(client, "ACT_PRIMARYATTACK_ELITES_R") == sequence || GetAnimation(client, "ACT_PRIMARYATTACK_ELITES_L") == sequence ||
	//GetAnimation(client, "ACT_PRIMARYATTACK_GASCAN1_IDLE") == sequence || GetAnimation(client, "ACT_PRIMARYATTACK_GASCAN1_RUN") == sequence ||
	//GetAnimation(client, "ACT_PRIMARYATTACK_GASCAN2_IDLE") == sequence || GetAnimation(client, "ACT_PRIMARYATTACK_GASCAN2_RUN") == sequence ||
	//GetAnimation(client, "ACT_PRIMARYATTACK_GREN1_IDLE") == sequence || GetAnimation(client, "ACT_PRIMARYATTACK_GREN1_RUN") == sequence ||
	//GetAnimation(client, "ACT_PRIMARYATTACK_GREN2_IDLE") == sequence || GetAnimation(client, "ACT_PRIMARYATTACK_GREN2_RUN") == sequence ||
	//GetAnimation(client, "ACT_PRIMARYATTACK_M3S90") == sequence || GetAnimation(client, "ACT_PRIMARYATTACK_MINIGUN") == sequence ||
	
	GetAnimation(client, "ACT_DEPLOY_Pistol") == sequence || GetAnimation(client, "ACT_DEPLOY_Elites") == sequence
	)
	{ return false; }
	
	return true;
}*/

bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 4));
}

bool IsInfected(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && (GetClientTeam(client) == 3));
}

bool IsPlayerHeld(int client)
{
	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	int charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (RealValidEntity(jockey) || RealValidEntity(charger) || RealValidEntity(hunter) || RealValidEntity(smoker))
	{
		return true;
	}
	return false;
}
bool IsIncapacitated(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
		return true;
	return false;
}

/*bool IsMaleL4D1Character(int client)
{
	if (IsSurvivor(client))
	{
		char model[128];
		GetClientModel(client, model, sizeof(model));
		if (StrEqual(model, MODEL_BILL))
		return true;
		else if (StrEqual(model, MODEL_LOUIS))
		return true;
		else if (StrEqual(model, MODEL_FRANCIS))
		return true;
	}
	return false;
}*/

/*static int clienthook[MAXPLAYERS + 1] = -1;
public void OnAllPluginsLoaded() //late loading
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsSurvivor(client))
		{
			clienthook[client] = DHookEntity(hSequenceSet, true, client);
		}
	}
}

public void OnClientPutInServer(int client)
{
	clienthook[client] = DHookEntity(hSequenceSet, true, client);
}*/

int GetAnimation(int entity, const char[] sequence)
{
	//if (!RealValidEntity(entity) || sdkGetSeqFromString == null) return -1;
	if (!RealValidEntity(entity)) return -1;
	
	char model[64];
	GetClientModel(entity, model, sizeof(model));
	
	int temp_ent = CreateEntityByName("prop_dynamic");
	if (!RealValidEntity(temp_ent)) return -1;
	SetEntityModel(temp_ent, model);
	
	SetVariantString(sequence);
	AcceptEntityInput(temp_ent, "SetAnimation");
	int result = GetEntProp(temp_ent, Prop_Send, "m_nSequence");
	RemoveEdict(temp_ent);
	
	return result;
	//return SDKCall(sdkGetSeqFromString, entity, sequence);
}

/*int GetIncapSequence(int client)
{
	int result = -1;
	if (IsSurvivor(client))
	{
	//	char model[64];
	//	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
	//	if (StrEqual(model, MODEL_BILL, false))
	//	{
	//		return 518;
	//	}
	//	else if (StrEqual(model, MODEL_FRANCIS, false))
	//	{
	//		return 521;
	//	}
	//	else if (StrEqual(model, MODEL_LOUIS, false))
	//	{
	//		return 518;
	//	}
		result = GetAnimation(client, "Death");
	}
	return result;
}*/

bool IsInIncapSequence(int client, int sequence)
{
	if (IsSurvivor(client))
	{
		if (sequence == GetAnimation(client, "ACT_DIESIMPLE") || sequence == -1 || sequence == GetAnimation(client, "Death"))
		{
			return true;
		}
	}
	return false;
}

/*int GetIncapIdleSequence(int client)
{
	if (IsSurvivor(client))
	{
		char model[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		bool dual = IsDualWielding(client);
		if (StrEqual(model, MODEL_BILL, false))
		{
			if (!dual)
			{ return 521; }
			else
			{ return 520; }
		}
		else if (StrEqual(model, MODEL_FRANCIS, false))
		{
			if (!dual)
			{ return 524; }
			else
			{ return 523; }
		}
		else if (StrEqual(model, MODEL_LOUIS, false))
		{
			if (!dual)
			{ return 521; }
			else
			{ return 520; }
		}
	}
	return -1;
}*/

int GetPounceSequence(int client)
{
	int result = -1;
	if (IsSurvivor(client))
	{
		/*char model[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_NICK, false))
		{
			return 618;
		}
		else if (StrEqual(model, MODEL_ROCHELLE, false))
		{
			return 627;
		}
		else if (StrEqual(model, MODEL_ELLIS, false))
		{
			return 623;
		}
		else if (StrEqual(model, MODEL_COACH, false))
		{
			return 619;
		}
		else if (StrEqual(model, MODEL_BILL, false))
		{
			return 526;
		}
		else if (StrEqual(model, MODEL_ZOEY, false))
		{
			return 535;
		}
		else if (StrEqual(model, MODEL_FRANCIS, false))
		{
			return 529;
		}
		else if (StrEqual(model, MODEL_LOUIS, false))
		{
			return 526;
		}*/
		result = GetAnimation(client, "ACT_TERROR_INCAP_FROM_POUNCE");
	}
	return result;
}

int GetPounceIdleSequence(int client)
{
	int result = -1;
	if (IsSurvivor(client))
	{
		/*char model[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_NICK, false))
		{
			return 619;
		}
		else if (StrEqual(model, MODEL_ROCHELLE, false))
		{
			return 628;
		}
		else if (StrEqual(model, MODEL_ELLIS, false))
		{
			return 624;
		}
		else if (StrEqual(model, MODEL_COACH, false))
		{
			return 620;
		}
		else if (StrEqual(model, MODEL_BILL, false))
		{
			return 527;
		}
		else if (StrEqual(model, MODEL_ZOEY, false))
		{
			return 536;
		}
		else if (StrEqual(model, MODEL_FRANCIS, false))
		{
			return 530;
		}
		else if (StrEqual(model, MODEL_LOUIS, false))
		{
			return 527;
		}*/
		result = GetAnimation(client, "ACT_IDLE_POUNCED");
	}
	return result;
}

/*int GetIncapChargerSequence(client)
{
	int result = -1;
	if (IsSurvivor(client))
	{
		char model[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_NICK, false))
		{
			return 668;
		}
		else if (StrEqual(model, MODEL_ROCHELLE, false))
		{
			return 675;
		}
		else if (StrEqual(model, MODEL_ELLIS, false))
		{
			return 672;
		}
		else if (StrEqual(model, MODEL_COACH, false))
		{
			return 657;
		}
		else if (StrEqual(model, MODEL_BILL, false))
		{
			return 760;
		}
		else if (StrEqual(model, MODEL_ZOEY, false))
		{
			return 820;
		}
		else if (StrEqual(model, MODEL_FRANCIS, false))
		{
			return 763;
		}
		else if (StrEqual(model, MODEL_LOUIS, false))
		{
			return 760;
		}
	}
	return result;
}*/

/*int GetPistolReloadSequence(int client, int type)
{
	if (IsSurvivor(client))
	{
		char model[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_NICK, false))
		{
			if (type <= 0)
			{ return 513; }
			else if (type > 0)
			{ return 517; }
		}
		else if (StrEqual(model, MODEL_ROCHELLE, false))
		{
			if (type <= 0)
			{ return 528; }
			else if (type > 0)
			{ return 532; }
		}
		else if (StrEqual(model, MODEL_ELLIS, false))
		{
			if (type <= 0)
			{ return 517; }
			else if (type > 0)
			{ return 521; }
		}
		else if (StrEqual(model, MODEL_COACH, false))
		{
			if (type <= 0)
			{ return 514; }
			else if (type > 0)
			{ return 518; }
		}
		else if (StrEqual(model, MODEL_BILL, false))
		{
			if (type <= 0)
			{ return 426; }
			else if (type > 0)
			{ return 430; }
		}
		else if (StrEqual(model, MODEL_ZOEY, false))
		{
			if (type <= 0)
			{ return 453; }
			else if (type > 0)
			{ return 457; }
		}
		else if (StrEqual(model, MODEL_FRANCIS, false))
		{
			if (type <= 0)
			{ return 430; }
			else if (type > 0)
			{ return 434; }
		}
		else if (StrEqual(model, MODEL_LOUIS, false))
		{
			if (type <= 0)
			{ return 427; }
			else if (type > 0)
			{ return 431; }
		}
	}
	return -1;
}*/

bool IsDualWielding(int client)
{
	if (!IsSurvivor(client)) return false;
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!RealValidEntity(weapon)) return false;
	if (!HasEntProp(weapon, Prop_Send, "m_isDualWielding")) return false;
	int dual = GetEntProp(weapon, Prop_Send, "m_isDualWielding");
	if (dual > 0)
	return true;
	
	return false;
}

/*bool IsCrawling(int client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsIncapacitated(client)) return false;
	ConVar crawl_cvar = FindConVar("survivor_allow_crawling");
	if (!crawl_cvar || !GetConVarBool(crawl_cvar)) return false;
	int m_nButtons = GetEntProp(client, Prop_Data, "m_nButtons");
	if (m_nButtons & IN_FORWARD)
	{ return true; }
	return false;
}*/

void PrepSDKCall()
{
	if (hConf == null)
	{
		SetFailState("Error: Why do you not have this extension's gamedata file?!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	//if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, NAME_DoAnimationEvent))
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_DoAnimationEvent))
	{ SetFailState("Cant find %s Signature in gamedata file", NAME_DoAnimationEvent); }
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkDoAnim = EndPrepSDKCall();
	if (sdkDoAnim == null)
	{ SetFailState("Cant initialize %s SDKCall, Signature broken", NAME_DoAnimationEvent); }
	
	/*StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_LookupSequence))
	{ SetFailState("Cant find %s Signature in gamedata file", NAME_LookupSequence); }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	sdkGetSeqFromString = EndPrepSDKCall();
	if (sdkGetSeqFromString == null)
	{ SetFailState("Cant initialize %s SDKCall, Signature broken", NAME_LookupSequence); }*/
}

void LoadOffset()
{
	if (hConf == null)
	{
		SetFailState("Error: Gamedata not found");
	}
	
	hSequenceSet = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	DHookSetFromConf(hSequenceSet, hConf, SDKConf_Signature, NAME_SelectWeightedSequence);
	DHookAddParam(hSequenceSet, HookParamType_Int);
	DHookEnableDetour(hSequenceSet, false, OnSequenceSet_Pre);
	DHookEnableDetour(hSequenceSet, true, OnSequenceSet);
	/*int offset;
	offset = GameConfGetOffset(hConf, NAME_SelectWeightedSequence);
	if (offset == -1)
	{
		LogError("Unable to get offset for %s", NAME_SelectWeightedSequence);
		return;
	}
	hSequenceSet = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, OnSequenceSet);
	DHookAddParam(hSequenceSet, HookParamType_Int);*/
}

/*void UnloadOffset()
{
	if (hSequenceSet == null)
	{ return; }
	
	DHookDisableDetour(hSequenceSet, true, OnSequenceSet);
}*/

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}

void GetGamedata()
{
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(filePath) )
	{
		hConf = LoadGameConfigFile(GAMEDATA); // For some reason this doesn't return null even for invalid files, so check they exist first.
	}
	else
	{
		PrintToServer("[SM] %s unable to get %i.txt gamedata file. Generating...", PLUGIN_NAME, GAMEDATA);
		
		Handle fileHandle = OpenFile(filePath, "a+");
		if (fileHandle == null)
		{ SetFailState("[SM] Couldn't generate gamedata file!"); }
		
		WriteFileLine(fileHandle, "\"Games\"");
		WriteFileLine(fileHandle, "{");
		WriteFileLine(fileHandle, "	\"left4dead2\"");
		WriteFileLine(fileHandle, "	{");
		/*
		WriteFileLine(fileHandle, "		\"Addresses\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			\"SelectWeightedSequenceAddress\"");
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"windows\"");
		WriteFileLine(fileHandle, "				{");
		WriteFileLine(fileHandle, "					\"signature\"	\"%s\"", NAME_SelectWeightedSequence);
		WriteFileLine(fileHandle, "				}");
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "		}");
		*/
		WriteFileLine(fileHandle, "		\"Signatures\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_SelectWeightedSequence);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_SelectWeightedSequence_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_SelectWeightedSequence_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_SelectWeightedSequence_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_DoAnimationEvent);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_DoAnimationEvent_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_DoAnimationEvent_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_DoAnimationEvent_LINUX);
		WriteFileLine(fileHandle, "			}");
		/*
		WriteFileLine(fileHandle, "			\"%s\"", NAME_LookupSequence);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_LookupSequence_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_LookupSequence_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_LookupSequence_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "		}");
		*/
		/*
		WriteFileLine(fileHandle, "		\"Offsets\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_SelectWeightedSequence);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%i\"", OFFSET_SelectWeightedSequence_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%i\"", OFFSET_SelectWeightedSequence_WINDOWS);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_DoAnimationEvent);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%i\"", OFFSET_DoAnimationEvent_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%i\"", OFFSET_DoAnimationEvent_WINDOWS);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "		}");
		*/
		WriteFileLine(fileHandle, "	}");
		WriteFileLine(fileHandle, "}");
		
		CloseHandle(fileHandle);
		hConf = LoadGameConfigFile(GAMEDATA);
		if (hConf == null)
		{ SetFailState("[SM] Failed to load auto-generated gamedata file!"); }
		
		PrintToServer("[SM] %s successfully generated %s.txt gamedata file!", PLUGIN_NAME, GAMEDATA);
	}
}