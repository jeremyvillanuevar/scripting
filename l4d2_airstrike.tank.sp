/*
*	F-18 Airstrike - Tank
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



#define PLUGIN_VERSION		"1.1.1-ta"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] F-18 Airstrike - Tank
*	Author	:	SilverShot
*	Descrp	:	An example plugin which uses the core plugin. Creates an Airstrike when and where a tank spawns.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=187567
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1.1-ta (03-Jul-2019)
	- Changed natives to use vectors. Only affects 3rd party plugins using the Airstrike core, which will need updating and recompiling.

1.1-ta (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.9 or newer.

1.0-ta (15-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <l4d2_airstrike>

bool g_bLoaded;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] F-18 Airstrike - Tank",
	author = "SilverShot",
	description = "An example plugin which uses the core plugin. Creates an Airstrike when and where a tank spawns.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=187567"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if( LibraryExists("l4d2_airstrike") == false )
	{
		SetFailState("F-18 Airstrike 'l4d2_airstrike.core.smx' plugin not loaded.");
	}
}

public void OnPluginStart()
{
	CreateConVar("l4d2_strike_tank",	PLUGIN_VERSION,			"F-18 Airstrike Tank plugin version",	FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void F18_OnPluginState(int pluginstate)
{
	static int mystate;

	if( pluginstate == 1 && mystate == 0 )
	{
		mystate = 1;
		g_bLoaded = true;
		HookEvent("tank_spawn", Event_TankSpawn);
	}
	else if( pluginstate == 0 && mystate == 1 )
	{
		mystate = 0;
		g_bLoaded = false;
		UnhookEvent("tank_spawn", Event_TankSpawn);
	}
}

public void F18_OnRoundState(int roundstate)
{
	static int mystate;

	if( roundstate == 1 && mystate == 0 )
	{
		mystate = 1;
		g_bLoaded = true;
	}
	else if( roundstate == 0 && mystate == 1 )
	{
		mystate = 0;
		g_bLoaded = false;
	}
}



// ====================================================================================================
//					CREATE AIRSTRIKE
// ====================================================================================================
public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bLoaded == true )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( client )
		{
			float vPos[3], vAng[3];
			GetClientAbsOrigin(client, vPos);
			GetClientEyeAngles(client, vAng);
			F18_ShowAirstrike(vPos, vAng[1]);
		}
	}
}