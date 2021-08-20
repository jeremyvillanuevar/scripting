/*
*	F-18 Airstrike - No Mercy
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



#define PLUGIN_VERSION		"1.3-nm"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] F-18 Airstrike - No Mercy
*	Author	:	SilverShot
*	Descrp	:	Causes the gas station to ignite on No Mercy - Sewers (c8m3) level when hit by the Airstrike.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=187567
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.3-nm (10-May-2020)
	- Various changes to tidy up code.

1.2.1-nm (03-Jul-2019)
	- Changed natives to use vectors. Only affects 3rd party plugins using the Airstrike core, which will need updating and recompiling.

1.2-nm (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.9 or newer.

1.1-nm (09-Aug-2013)
	- Fixed not working on the second round of versus.

1.0-nm (15-Jun-2013)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <l4d2_airstrike>


bool c8m3, g_bLoaded;
float g_vPos[3];
int g_iCounter, g_iEntity1, g_iEntity2;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] F-18 Airstrike - No Mercy",
	author = "SilverShot",
	description = "Causes the gas station to ignite on No Mercy - Sewers (c8m3) level when hit by the Airstrike.",
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
	CreateConVar("l4d2_strike_no_mercy",	PLUGIN_VERSION,			"F-18 Airstrike No Mercy plugin version",	FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void F18_OnPluginState(int pluginstate)
{
	static int mystate;

	if( pluginstate == 1 && mystate == 0 )
	{
		mystate = 1;
		g_bLoaded = true;
	}
	else if( pluginstate == 0 && mystate == 1 )
	{
		mystate = 0;
		g_bLoaded = false;
	}
}

public void F18_OnRoundState(int roundstate)
{
	static int mystate;

	if( roundstate == 1 && mystate == 0 )
	{
		mystate = 1;
		g_bLoaded = true;

		g_iCounter++;
		CreateTimer(1.0, TimerStart, g_iCounter);
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
public Action TimerStart(Handle timer, any count)
{
	if( g_iCounter == count )
	{
		c8m3 = false;
		char sTemp[20];
		GetCurrentMap(sTemp, sizeof(sTemp));
		if( strcmp(sTemp, "c8m3_sewers") == 0 )
		{
			int entity = -1;
			while( (entity = FindEntityByClassname(entity, "prop_physics")) != INVALID_ENT_REFERENCE )
			{
				GetEntPropString(entity, Prop_Data, "m_iName", sTemp, sizeof(sTemp));
				if( strcmp(sTemp, "pump01_breakable") == 0 )
				{
					GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", g_vPos);
					c8m3 = true;
					g_iEntity1 = EntIndexToEntRef(entity);
				}
				else if( strcmp(sTemp, "pump02_breakable") == 0 )
				{
					GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", g_vPos);
					c8m3 = true;
					g_iEntity2 = EntIndexToEntRef(entity);
				}
			}
		}
	}
}

public void F18_OnMissileHit(float vPos[3])
{
	if( c8m3 && g_bLoaded )
	{
		if( GetVectorDistance(vPos, g_vPos) <= 600 )
		{
			if( EntRefToEntIndex(g_iEntity1) != INVALID_ENT_REFERENCE ) AcceptEntityInput(g_iEntity1, "Break");
			if( EntRefToEntIndex(g_iEntity2) != INVALID_ENT_REFERENCE ) AcceptEntityInput(g_iEntity2, "Break");
		}
	}
}