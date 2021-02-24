#pragma	semicolon 1
#include <sourcemod>


public OnPluginStart()
{
	
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{	
	//SetConVarFloat(FindConVar("sb_vomit_blind_time"), 0.0);
	//SetConVarInt(FindConVar("survivor_vision_range"), 3000);
	//SetCommandFlags("sb_force_max_intensity", flags & ~FCVAR_CHEAT);
	//ServerCommand("sb_force_max_intensity Zoey");	
	
	
	//Tickrate	
	//tickrate 93//gameframe(tick) using tickrate_enabler extension
	SetConVarInt(FindConVar("fps_max"), 93);
	SetConVarInt(FindConVar("sv_minupdaterate"), 93);
	SetConVarInt(FindConVar("sv_maxupdaterate"), 93);
	SetConVarInt(FindConVar("sv_mincmdrate"), 93);
	SetConVarInt(FindConVar("sv_maxcmdrate"), 93);
	SetConVarFloat(FindConVar("net_maxcleartime"), 0.00001);
	SetConVarInt(FindConVar("net_splitrate"), 2);
	SetConVarInt(FindConVar("net_queued_packet_thread"), 1);
	SetConVarInt(FindConVar("net_splitpacket_maxrate"), 18000);
	SetConVarFloat(FindConVar("nb_update_frequency"), 0.01);
	SetConVarInt(FindConVar("net_splitpacket_maxrate"), 18000);
	SetConVarInt(FindConVar("z_vomit_velocity"), 3400);
	SetConVarInt(FindConVar("z_max_neighbor_range"), 16);
	SetConVarInt(FindConVar("nb_friction_forward"), 0);	
	
	//Uncommons	
	ServerCommand("sm_cvar l4d2_spawn_uncommons_autoshuffle 1");
	ServerCommand("sm_cvar l4d2_spawn_uncommons_hordecount 24");
	ServerCommand("sm_cvar sm_advertisements_interval 250");
	SetConVarFloat(FindConVar("z_mob_recharge_rate"), 0.015);
	
	//Mobs Spawns	
	SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10);
	SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30);
	SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), 5);
	SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), 60);
	SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 50);
	SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 60);
	SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 50);
	SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 60);
	SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 50);
	SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 60);
	SetConVarInt(FindConVar("z_spawn_mobs_behind_chance"), 50);
	SetConVarInt(FindConVar("z_scout_mob_spawn_range"), 600);
	SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), 60);
	SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), 120);

	SetConVarFloat(FindConVar("z_mob_population_density"), 0.0064);
	SetConVarFloat(FindConVar("z_wandering_density"), 0.05);
	SetConVarFloat(FindConVar("director_intensity_relax_allow_wanderers_threshold"), 0.95);
	SetConVarFloat(FindConVar("director_intensity_relax_allow_wanderers_threshold_hard"), 0.95);

	SetConVarInt(FindConVar("director_always_allow_wanderers"), 1);
	SetConVarInt(FindConVar("z_reserved_wanderers"), 30);
	SetConVarInt(FindConVar("director_num_reserved_wanderers"), 10);

	SetConVarFloat(FindConVar("cleared_wanderer_respawn_chance"), 0.6);
	//director
	SetConVarInt(FindConVar("director_special_initial_spawn_delay_min"), 1);
	SetConVarInt(FindConVar("director_special_initial_spawn_delay_max"), 2);
	SetConVarInt(FindConVar("director_special_initial_spawn_delay_max_extra"), 3);
	SetConVarInt(FindConVar("director_special_respawn_interval"), 1);
	SetConVarInt(FindConVar("z_director_special_spawn_delay"), 1);
	SetConVarInt(FindConVar("z_special_spawn_interval"), 1);
	SetConVarInt(FindConVar("director_special_battlefield_respawn_interval"), 1);
	SetConVarInt(FindConVar("director_build_up_min_interval"), 30);
	SetConVarInt(FindConVar("director_relax_min_interval"), 60);
	SetConVarInt(FindConVar("director_relax_max_interval"), 180);
	SetConVarInt(FindConVar("director_relax_max_flow_travel"), 1500);
	SetConVarInt(FindConVar("director_tank_bypass_max_flow_travel"), 100);
	
	SetConVarFloat(FindConVar("director_intensity_threshold"), 1.0);
	SetConVarFloat(FindConVar("director_intensity_relax_threshold"), 1.0);
	SetConVarFloat(FindConVar("intensity_factor"), 0.12);
	
	SetConVarInt(FindConVar("intensity_decay_time"), 15);
	SetConVarInt(FindConVar("intensity_averaged_following_decay"), 10);
	SetConVarFloat(FindConVar("director_per_map_weapon_upgrade_chance"), 0.75);
	SetConVarInt(FindConVar("director_afk_timeout"), 15);
	SetConVarInt(FindConVar("director_music_dynamic_mob_size"), 30);
	SetConVarInt(FindConVar("director_music_dynamic_mobstop_size"), 12);
	SetConVarInt(FindConVar("director_music_dynamic_scanmobstop_size"), 6);


// Survivor Health, Accuracy, Friendly Fire Variables/Modifiers
	SetConVarInt(FindConVar("survivor_revive_health"), 39);
	SetConVarInt(FindConVar("survivor_incapacitated_accuracy_penalty"), 0);
	SetConVarInt(FindConVar("survivor_burn_factor_easy"), 0);
	SetConVarInt(FindConVar("survivor_burn_factor_normal"), 0);
	SetConVarInt(FindConVar("survivor_burn_factor_hard"), 0);
	SetConVarInt(FindConVar("survivor_burn_factor_expert"), 0);

// Common Infected[All] Special Infected[lunge_push only]
	SetConVarInt(FindConVar("z_zombie_lunge_push"), 1);
	SetConVarFloat(FindConVar("z_hit_from_behind_factor"), 1.0);
	SetConVarFloat(FindConVar("z_hit_incap_factor_easy"), 1.0);
	SetConVarFloat(FindConVar("z_hit_incap_factor_normal"), 1.0);
	SetConVarFloat(FindConVar("z_hit_incap_factor_hard"), 1.0);
	SetConVarFloat(FindConVar("z_hit_incap_factor_expert"), 1.0);

//zombie alertness
	SetConVarInt(FindConVar("z_acquire_far_range"), 7000);
	SetConVarInt(FindConVar("z_acquire_far_time"), 1);
	SetConVarInt(FindConVar("z_acquire_near_range"), 500);
	SetConVarFloat(FindConVar("z_acquire_near_time"), 0.1);
	SetConVarInt(FindConVar("z_hear_gunfire_range"), 1200);
	SetConVarInt(FindConVar("z_hear_runner_far_range"), 850);
	SetConVarInt(FindConVar("z_hear_runner_near_range"), 600);
	SetConVarInt(FindConVar("z_force_attack_from_sound_range"), 850);
	SetConVarInt(FindConVar("z_vision_range"), 850);
	SetConVarInt(FindConVar("z_alert_range"), 1200);
	SetConVarInt(FindConVar("z_vision_range_obscured"), 600);
	SetConVarInt(FindConVar("z_vision_range_obscured_alert"), 800);
	SetConVarInt(FindConVar("z_close_target_notice_distance"), 75);
	SetConVarInt(FindConVar("z_must_wander"), 1);
	SetConVarInt(FindConVar("z_spawn_mobs_behind_chance"), 50);
	SetConVarInt(FindConVar("z_zombie_lunge_push"), 1);
	SetConVarFloat(FindConVar("z_throttle_hit_interval_normal"), 0.5);

	// Survivor A.I.
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_normal"), 0);
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_hard"), 0);
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_expert"), 0);
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_vs"), 0);
	SetConVarInt(FindConVar("sb_separation_range"), 100);
	SetConVarInt(FindConVar("sb_enforce_proximity_range"), 75);
	SetConVarInt(FindConVar("sb_separation_danger_min_range"), 75);
	SetConVarInt(FindConVar("sb_separation_danger_max_range"), 100);
	SetConVarInt(FindConVar("sb_battlestation_give_up_range_from_human"), 75);
	SetConVarInt(FindConVar("sb_max_battlestation_range_from_human"), 100);
	SetConVarInt(FindConVar("sb_max_team_melee_weapons"), 3);

}
