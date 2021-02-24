#pragma	semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

Config()
{
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
	SetConVarInt(FindConVar("sb_all_bot_game"), 1); 
	SetConVarInt(FindConVar("sb_debug_apoproach_wait_time"), 0);
	SetConVarInt(FindConVar("sb_allow_shoot_through_survivors"), 0);
	SetConVarInt(FindConVar("sb_escort"), 0); 
	SetConVarInt(FindConVar("sb_battlestation_give_up_range_from_human"), 100);
	SetConVarFloat(FindConVar("sb_battlestation_human_hold_time"), 0.25);

	SetConVarFloat(FindConVar("sb_close_checkpoint_door_interval"), 0.18);
	SetConVarInt(FindConVar("sb_combat_saccade_speed"), 2250);
	SetConVarFloat(FindConVar("sb_enforce_proximity_lookat_timeout"), 0.0);
	SetConVarInt(FindConVar("sb_enforce_proximity_range"), 10000);
	SetConVarFloat(FindConVar("sb_follow_stress_factor"), 0.0);
	SetConVarFloat(FindConVar("sb_friend_immobilized_reaction_time_expert"), 0.0);
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_hard"), 0);
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_normal"), 0);
	SetConVarFloat(FindConVar("sb_friend_immobilized_reaction_time_vs"), 0.0);
	SetConVarInt(FindConVar("sb_reachable_cache_paranoia"), 0);
	SetConVarFloat(FindConVar("sb_locomotion_wait_threshold"), 0.0);
	SetConVarInt(FindConVar("sb_use_button_range"), 1000);
	SetConVarInt(FindConVar("sb_max_battlestation_range_from_human"), 290);
	SetConVarInt(FindConVar("sb_max_scavenge_separation"), 2000);
	SetConVarFloat(FindConVar("sb_max_team_melee_weapons"), 1);
	SetConVarFloat(FindConVar("sb_melee_approach_victim"), 0);
	SetConVarFloat(FindConVar("sb_min_attention_notice_time"), 0.0);
	SetConVarFloat(FindConVar("sb_min_orphan_time_to_cover"), 0.0);
	SetConVarInt(FindConVar("sb_neighbor_range"), 100);
	SetConVarInt(FindConVar("sb_normal_saccade_speed"), 1500);
	SetConVarInt(FindConVar("sb_path_lookahead_range"), 975);
	SetConVarInt(FindConVar("sb_pushscale"), 4);
	SetConVarInt(FindConVar("sb_reachability_cache_lifetime"), 0);
	SetConVarInt(FindConVar("sb_rescue_vehicle_loading_range"), 50);
	SetConVarInt(FindConVar("sb_revive_friend_distance"), 125);
	SetConVarInt(FindConVar("sb_separation_danger_max_range"), 300);
	SetConVarInt(FindConVar("sb_separation_danger_min_range"), 84);
	SetConVarInt(FindConVar("sb_separation_range"), 300);
	SetConVarInt(FindConVar("sb_sidestep_for_horde"), 1);
	SetConVarFloat(FindConVar("sb_temp_health_consider_factor"), 1);
	SetConVarInt(FindConVar("sb_threat_exposure_stop"), 2147483646);
	SetConVarInt(FindConVar("sb_threat_exposure_walk"), 2147483647);
	SetConVarInt(FindConVar("sb_near_hearing_range"), 10000);
	SetConVarInt(FindConVar("sb_far_hearing_range"), 2147483647);	
	SetConVarInt(FindConVar("sb_threat_very_close_range"), 50);
	SetConVarInt(FindConVar("sb_close_threat_range"), 75);
	SetConVarInt(FindConVar("sb_threat_close_range"), 50);
	SetConVarInt(FindConVar("sb_threat_medium_range"), 3000);
	SetConVarInt(FindConVar("sb_threat_far_range"), 8000);
	SetConVarInt(FindConVar("sb_threat_very_far_range"), 2147483647);
	
	SetConVarFloat(FindConVar("sb_toughness_buffer"), 76);
	SetConVarFloat(FindConVar("sb_vomit_blind_time"), 0);
	
	SetConVarInt(FindConVar("survivor_calm_damage_delay"), 0.05);
	SetConVarInt(FindConVar("survivor_calm_damage_delay"), 1);
	SetConVarInt(FindConVar("survivor_calm_deploy_delay"), 1);
	
	SetConVarInt(FindConVar("survivor_calm_no_flashlight"), 0.6);
	SetConVarInt(FindConVar("survivor_calm_recent_enemy_delay"), 0.1);
	
	SetConVarInt(FindConVar("survivor_calm_weapon_delay"), 1);
	SetConVarInt(FindConVar("survivor_vision_range_obscured"), 1500);
	
	SetConVarInt(FindConVar("survivor_vision_range"), 3000);
	
	
	int flags=GetCommandFlags("sb_force_max_intensity");
	SetCommandFlags("sb_force_max_intensity", flags & ~FCVAR_CHEAT);

	ServerCommand("sb_force_max_intensity Coach");
	ServerCommand("sb_force_max_intensity Ellis");
	ServerCommand("sb_force_max_intensity Rochelle");
	ServerCommand("sb_force_max_intensity Nick");
	ServerCommand("sb_force_max_intensity Bill");
	ServerCommand("sb_force_max_intensity Louis");
	ServerCommand("sb_force_max_intensity Francis");
	ServerCommand("sb_force_max_intensity Zoey");
}

public OnPluginStart()
{
	CreateTimer(10.0, Competitive, _, TIMER_REPEAT);
	RegAdminCmd("sm_cb", ConfigBot, ADMFLAG_KICK, "Config the bot");
	Config();
}

public OnMapStart()
{
	Config();
}

public Action:Competitive(Handle:Timer)
{
	Config();
}

public Action ConfigBot(client, args) 
{
	Config();
	return Plugin_Handled;
}
 
stock UnlockConsoleCommandAndConvar(const String:command[])
{
    new flags = GetCommandFlags(command);
    if (flags != INVALID_FCVAR_FLAGS)
    {
        SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    }
    
    new Handle:cvar = FindConVar(command);
    if (cvar != INVALID_HANDLE)
    {
        flags = GetConVarFlags(cvar);
        SetConVarFlags(cvar, flags & ~FCVAR_CHEAT);
    }
}