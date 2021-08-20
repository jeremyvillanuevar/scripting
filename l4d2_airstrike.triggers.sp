/*
*	F-18 Airstrike - Triggers
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



#define PLUGIN_VERSION		"1.3-tr"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] F-18 Airstrike - Triggers
*	Author	:	SilverShot
*	Descrp	:	Creates F-18 flybys which shoot missiles to where they were triggered from.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=187567
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.4-1.2insky-tr (01-Apr-2015)
	- Added RegAdminCmd "sm_show_airstrike" for sky.cfg

1.3-tr (10-May-2020)
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.2.1-tr (03-Jul-2019)
	- Changed natives to use vectors. Only affects 3rd party plugins using the Airstrike core, which will need updating and recompiling.

1.2-tr (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.1-tr (20-Jun-2012)
	- Prevents setting the Refire Time and Count values lower than 0.

1.0-tr (15-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2_airstrike>

#define CHAT_TAG			"\x03[Airstrike] \x05"
#define CONFIG_SPAWNS		"data/l4d2_airstrike.cfg"

#define MODEL_BOX			"models/props/cs_militia/silo_01.mdl"
#define MAX_ENTITIES		14


Handle g_hTimerBeam, g_hTimerEnable[MAX_ENTITIES];
int g_iHaloMaterial, g_iLaserMaterial, g_iMenuSelected[MAXPLAYERS+1], g_iRefireAtOnce[MAX_ENTITIES], g_iRefireCount[MAX_ENTITIES], g_iSelectedTrig, g_iTriggers[MAX_ENTITIES];
bool g_bLoaded;
float g_fRefireTime[MAX_ENTITIES], g_fTargetAng[MAX_ENTITIES], g_vTargetZone[MAX_ENTITIES][3];
Menu g_hMenuAtOnce, g_hMenuPos, g_hMenuRefire, g_hMenuTime, g_hMenuVMaxs, g_hMenuVMins;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] F-18 Airstrike - Triggers",
	author = "SilverShot",
	description = "Creates F-18 flybys which shoot missiles to where they were triggered from.",
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

	RegPluginLibrary("l4d2_airstrike.triggers");
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
	RegAdminCmd("sm_strike_triggers",		CmdAirstrikeMenu,		ADMFLAG_ROOT,	"Displays a menu with options to show/save an airstrike and triggers.");
	RegAdminCmd("sm_show_airstrike",		Cmd_ShowAirstrikeById,	ADMFLAG_CONVARS,	"Usage: sm_show_airstrike <index>");

	CreateConVar("l4d2_strike_triggers",	PLUGIN_VERSION,			"F-18 Airstrike Triggers plugin version",	FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hMenuVMaxs = new Menu(VMaxsMenuHandler);
	g_hMenuVMaxs.AddItem("", "10 x 10 x 100");
	g_hMenuVMaxs.AddItem("", "25 x 25 x 100");
	g_hMenuVMaxs.AddItem("", "50 x 50 x 100");
	g_hMenuVMaxs.AddItem("", "100 x 100 x 100");
	g_hMenuVMaxs.AddItem("", "150 x 150 x 100");
	g_hMenuVMaxs.AddItem("", "200 x 200 x 100");
	g_hMenuVMaxs.AddItem("", "250 x 250 x 100");
	g_hMenuVMaxs.SetTitle("Airstrike: Trigger Box - VMaxs");
	g_hMenuVMaxs.ExitBackButton = true;

	g_hMenuVMins = new Menu(VMinsMenuHandler);
	g_hMenuVMins.AddItem("", "-10 x -10 x 0");
	g_hMenuVMins.AddItem("", "-25 x -25 x 0");
	g_hMenuVMins.AddItem("", "-50 x -50 x 0");
	g_hMenuVMins.AddItem("", "-100 x -100 x 0");
	g_hMenuVMins.AddItem("", "-150 x -150 x 0");
	g_hMenuVMins.AddItem("", "-200 x -200 x 0");
	g_hMenuVMins.AddItem("", "-250 x -250 x 0");
	g_hMenuVMins.SetTitle("Airstrike: Trigger Box - VMins");
	g_hMenuVMins.ExitBackButton = true;

	g_hMenuPos = new Menu(PosMenuHandler);
	g_hMenuPos.AddItem("", "X + 1.0");
	g_hMenuPos.AddItem("", "Y + 1.0");
	g_hMenuPos.AddItem("", "Z + 1.0");
	g_hMenuPos.AddItem("", "X - 1.0");
	g_hMenuPos.AddItem("", "Y - 1.0");
	g_hMenuPos.AddItem("", "Z - 1.0");
	g_hMenuPos.AddItem("", "SAVE");
	g_hMenuPos.SetTitle("Airstrike: Trigger Box - Origin");
	g_hMenuPos.ExitBackButton = true;

	g_hMenuRefire = new Menu(RefireMenuHandler);
	g_hMenuRefire.AddItem("", "1");
	g_hMenuRefire.AddItem("", "2");
	g_hMenuRefire.AddItem("", "3");
	g_hMenuRefire.AddItem("", "5");
	g_hMenuRefire.AddItem("", "- 1");
	g_hMenuRefire.AddItem("", "+ 1");
	g_hMenuRefire.AddItem("", "Unlimited");
	g_hMenuRefire.SetTitle("Airstrike: Trigger Box - Refire Count");
	g_hMenuRefire.ExitBackButton = true;

	g_hMenuTime = new Menu(TimeMenuHandler);
	g_hMenuTime.AddItem("", "0.5");
	g_hMenuTime.AddItem("", "1.0");
	g_hMenuTime.AddItem("", "2.0");
	g_hMenuTime.AddItem("", "3.0");
	g_hMenuTime.AddItem("", "5.0");
	g_hMenuTime.AddItem("", "- 0.5");
	g_hMenuTime.AddItem("", "+ 0.5");
	g_hMenuTime.SetTitle("Airstrike: Trigger Box - Refire Time");
	g_hMenuTime.ExitBackButton = true;

	g_hMenuAtOnce = new Menu(AtOnceMenuHandler);
	g_hMenuAtOnce.AddItem("", "1");
	g_hMenuAtOnce.AddItem("", "2");
	g_hMenuAtOnce.AddItem("", "3");
	g_hMenuAtOnce.AddItem("", "4");
	g_hMenuAtOnce.AddItem("", "5");
	g_hMenuAtOnce.AddItem("", "6");
	g_hMenuAtOnce.AddItem("", "7");
	g_hMenuAtOnce.SetTitle("Airstrike: Trigger Box - Max At Once");
	g_hMenuAtOnce.ExitBackButton = true;
}

public Action Cmd_ShowAirstrikeById(int client,int  args)
{
    char index[4];
    GetCmdArg(1, index, sizeof(index));
    ShowAirStrike(StringToInt(index) - 1);
    return Plugin_Handled;
}

public void F18_OnPluginState(int pluginstate)
{
	static int mystate;

	if( pluginstate == 1 && mystate == 0 )
	{
		LoadAirstrikes();
		mystate = 1;
	}
	else if( pluginstate == 0 && mystate == 1 )
	{
		ResetPlugin();
		mystate = 0;
	}
}

public void F18_OnRoundState(int roundstate)
{
	static int mystate;

	if( roundstate == 1 && mystate == 0 )
	{
		ResetPlugin();
		LoadAirstrikes();
		mystate = 1;
	}
	else if( roundstate == 0 && mystate == 1 )
	{
		ResetPlugin();
		mystate = 0;
	}
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
	PrecacheModel(MODEL_BOX, true);
}

void ResetPlugin()
{
	g_bLoaded = false;
	g_iSelectedTrig = 0;

	for( int i = 0; i < MAX_ENTITIES; i++ )
	{
		g_vTargetZone[i] = view_as<float>({ 0.0, 0.0, 0.0 });
		g_iRefireCount[i] = 0;
		g_fRefireTime[i] = 3.0;
		g_iRefireAtOnce[i] = 1;
		g_fTargetAng[i] = 0.0;

		if( IsValidEntRef(g_iTriggers[i]) )
			AcceptEntityInput(g_iTriggers[i], "Kill");
		g_iTriggers[i] = 0;
	}
}



// ====================================================================================================
//					LOAD
// ====================================================================================================
void LoadAirstrikes()
{
	if( g_bLoaded == true )
		return;
	g_bLoaded = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	KeyValues hFile = new KeyValues("airstrike");
	hFile.ImportFromFile(sPath);

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	char sTemp[4];
	float fAng, vPos[3], vMax[3], vMin[3];

	for( int i = 1; i <= MAX_ENTITIES; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp, false) )
		{
			// AIRSTRIKE POSITION
			fAng = hFile.GetFloat("ang");
			hFile.GetVector("pos", vPos);
			g_vTargetZone[i-1] = vPos;
			g_fTargetAng[i-1] = fAng;
			g_fRefireTime[i-1] = 3.0;

			// TRIGGER BOXES
			hFile.GetVector("vpos", vPos);
			if( vPos[0] != 0.0 && vPos[1] != 0.0 && vPos[2] != 0.0 )
			{
				hFile.GetVector("vmin", vMin);
				hFile.GetVector("vmax", vMax);
				g_fRefireTime[i-1] = hFile.GetFloat("time", 3.0);
				g_iRefireCount[i-1] = hFile.GetNum("trig");
				g_iRefireAtOnce[i-1] = hFile.GetNum("once", 1);

				CreateTriggerMultiple(i, vPos, vMax, vMin);
			}

			hFile.GoBack();
		}
	}

	delete hFile;
}



// ====================================================================================================
//					MENU - MAIN
// ====================================================================================================
public Action CmdAirstrikeMenu(int client, int args)
{
	ShowMenuMain(client);
	return Plugin_Handled;
}

void ShowMenuMain(int client)
{
	Menu hMenu = new Menu(MainMenuHandler);
	hMenu.AddItem("1", "Airstrike on Crosshair");
	hMenu.AddItem("2", "Airstrike on Position");
	hMenu.AddItem("3", "Target Zone");
	hMenu.AddItem("4", "Trigger Box");
	hMenu.SetTitle("F-18 Airstrike");
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Select )
	{
		if( index == 0 )
		{
			float vPos[3], vAng[3], direction;
			GetClientEyePosition(client, vPos);
			GetClientEyeAngles(client, vAng);
			direction = vAng[1];

			Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter);

			if( TR_DidHit(trace) )
			{
				float vStart[3];
				TR_GetEndPosition(vStart, trace);
				GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
				vPos[0] = vStart[0] + vAng[0];
				vPos[1] = vStart[1] + vAng[1];
				vPos[2] = vStart[2] + vAng[2];
				F18_ShowAirstrike(vPos, direction);
			}

			delete trace;
			ShowMenuMain(client);
		}
		else if( index == 1 )
		{
			float vPos[3], vAng[3];
			GetClientAbsOrigin(client, vPos);
			GetClientEyeAngles(client, vAng);
			F18_ShowAirstrike(vPos, vAng[1]);
			ShowMenuMain(client);
		}
		else if( index == 2 )
		{
			ShowMenuTarget(client);
		}
		else if( index == 3 )
		{
			ShowMenuTrigger(client);
		}
	}
}

public bool TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients;
}



// ====================================================================================================
//					MENU - TARGET ZONE
// ====================================================================================================
void ShowMenuTarget(int client)
{
	Menu hMenu = new Menu(TargetMenuHandler);

	hMenu.AddItem("0", "Create/Replace");
	hMenu.AddItem("1", "Show Airstrike");
	hMenu.AddItem("2", "Delete");
	hMenu.AddItem("3", "Go To");

	hMenu.SetTitle("Airstrike - Target Zone:");
	hMenu.ExitBackButton = true;

	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int TargetMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_Select )
	{
		char sTemp[4];
		menu.GetItem(index, sTemp, sizeof(sTemp));
		index = StringToInt(sTemp);
		ShowMenuTargetList(client, index);
	}
}

void ShowMenuTargetList(int client, int index)
{
	g_iMenuSelected[client] = index;

	int count;
	Menu hMenu = new Menu(TargetListMenuHandler);
	char sIndex[4], sTemp[32];

	if( index == 0 )
		hMenu.AddItem("-1", "NEW");

	for( int i = 0; i < MAX_ENTITIES; i++ )
	{
		if( index == 0 )
		{
			count++;
			if( g_vTargetZone[i][0] != 0.0 && g_vTargetZone[i][1] != 0.0 && g_vTargetZone[i][2] != 0.0 )
			{
				Format(sTemp, sizeof(sTemp), "Replace %d", i+1);
				IntToString(i, sIndex, sizeof(sIndex));
				hMenu.AddItem(sIndex, sTemp);
			}
			else if( IsValidEntRef(g_iTriggers[i]) == true )
			{
				Format(sTemp, sizeof(sTemp), "Pair to Trigger %d", i+1);
				IntToString(i, sIndex, sizeof(sIndex));
				hMenu.AddItem(sIndex, sTemp);
			}
		}
		else if( g_vTargetZone[i][0] != 0.0 && g_vTargetZone[i][1] != 0.0 && g_vTargetZone[i][2] != 0.0 )
		{
			count++;
			if( index == 0 )
				Format(sTemp, sizeof(sTemp), "Replace %d", i+1);
			else
				Format(sTemp, sizeof(sTemp), "Target %d", i+1);

			IntToString(i, sIndex, sizeof(sIndex));
			hMenu.AddItem(sIndex, sTemp);
		}
	}

	if( index != 0 && count == 0 )
	{
		PrintToChat(client, "%sError: No saved Airstrikes were found.", CHAT_TAG);
		delete hMenu;
		ShowMenuMain(client);
		return;
	}

	if( index == 0 )
		hMenu.SetTitle("Airstrike: Target Zone - Create/Replace:");
	else if( index == 1 )
		hMenu.SetTitle("Airstrike: Target Zone - Show:");
	else if( index == 2 )
		hMenu.SetTitle("Airstrike: Target Zone - Delete:");
	else if( index == 3 )
		hMenu.SetTitle("Airstrike: Target Zone - Go To:");

	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int TargetListMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuTarget(client);
	}
	else if( action == MenuAction_Select )
	{
		int type = g_iMenuSelected[client];
		char sTemp[4];
		menu.GetItem(index, sTemp, sizeof(sTemp));
		index = StringToInt(sTemp);

		if( type == 0 )
		{
			if( index == -1 )
				SaveAirstrike(client, 0);
			else
				SaveAirstrike(client, index + 1);
			ShowMenuTarget(client);
		}
		else if( type == 1 )
		{
			ShowAirStrike(index);
			ShowMenuTarget(client);
		}
		else if( type == 2 )
		{
			DeleteTrigger(client, false, index+1);
			ShowMenuTarget(client);
		}
		else if( type == 3 )
		{
			float vPos[3];
			vPos = g_vTargetZone[index];

			if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 )
			{
				PrintToChat(client, "%sCannot teleport you, the Target Zone is missing.", CHAT_TAG);
			}
			else
			{
				vPos[2] += 10.0;
				TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			}
			ShowMenuTarget(client);
		}
	}
}



// ====================================================================================================
//					SAVE AIRSTRIKE
// ====================================================================================================
void SaveAirstrike(int client, int index)
{
	KeyValues hFile = ConfigOpen();

	if( hFile != null )
	{
		char sMap[64], sTemp[4];
		GetCurrentMap(sMap, sizeof(sMap));

		if( index == 0 )
		{
			if( hFile.JumpToKey(sMap, true) == true )
			{
				for( int i = 1; i <= MAX_ENTITIES; i++ )
				{
					IntToString(i, sTemp, sizeof(sTemp));
					if( hFile.JumpToKey(sTemp) == false )
					{
						index = i;
						break;
					}
					else
					{
						hFile.GoBack();
					}
				}
			}

			if( index == 0 )
			{
				delete hFile;
				PrintToChat(client, "%sCould not save airstrike, no free index or other error.", CHAT_TAG);
				return;
			}
		}
		else
		{
			if( hFile.JumpToKey(sMap, true) == false )
			{
				delete hFile;
				PrintToChat(client, "%sCould not save airstrike, could not create map data.", CHAT_TAG);
				return;
			}
		}

		IntToString(index, sTemp, sizeof(sTemp));
		if( hFile.JumpToKey(sTemp, true) == true )
		{
			float vAng[3], vPos[3];
			GetClientEyeAngles(client, vAng);
			GetClientAbsOrigin(client, vPos);

			hFile.SetFloat("ang", vAng[1]);
			hFile.SetVector("pos", vPos);

			g_fTargetAng[index-1] = vAng[1];
			g_vTargetZone[index-1] = vPos;

			ConfigSave(hFile);

			PrintToChat(client, "%sSaved airstrike to the map.", CHAT_TAG);
		}
		else
		{
			PrintToChat(client, "%sCould not save airstrike to the map.", CHAT_TAG);
		}

		delete hFile;
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX
// ====================================================================================================
void ShowMenuTrigger(int client)
{
	Menu hMenu = new Menu(TrigMenuHandler);

	hMenu.AddItem("0", "Create/Replace");
	if( g_hTimerBeam == null )
		hMenu.AddItem("1", "Show");
	else
		hMenu.AddItem("1", "Hide");
	hMenu.AddItem("2", "Delete");
	hMenu.AddItem("3", "VMaxs");
	hMenu.AddItem("4", "VMins");
	hMenu.AddItem("5", "Origin");
	hMenu.AddItem("6", "Go To");
	hMenu.AddItem("7", "Refire Count");
	hMenu.AddItem("8", "Refire Time");
	hMenu.AddItem("9", "Max At Once");

	hMenu.SetTitle("Airstrike - Trigger Box:");
	hMenu.ExitBackButton = true;

	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int TrigMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_Select )
	{
		if( index == 1 )
		{
			if( g_hTimerBeam != null )
			{
				delete g_hTimerBeam;
				g_iSelectedTrig = 0;
			}
			ShowMenuTrigList(client, index);
		}
		else
		{
			ShowMenuTrigList(client, index);
		}
	}
}

void ShowMenuTrigList(int client, int index)
{
	g_iMenuSelected[client] = index;

	int count;
	Menu hMenu = new Menu(TrigListMenuHandler);
	char sIndex[4], sTemp[32];

	if( index == 0 )
		hMenu.AddItem("-1", "NEW");

	for( int i = 0; i < MAX_ENTITIES; i++ )
	{
		if( index == 0 )
		{
			count++;
			if( IsValidEntRef(g_iTriggers[i]) == true )
			{
				Format(sTemp, sizeof(sTemp), "Replace %d", i+1);
				IntToString(i, sIndex, sizeof(sIndex));
				hMenu.AddItem(sIndex, sTemp);
			}
			else if( g_vTargetZone[i][0] != 0.0 && g_vTargetZone[i][1] != 0.0 && g_vTargetZone[i][2] != 0.0 )
			{
				Format(sTemp, sizeof(sTemp), "Pair to Target %d", i+1);
				IntToString(i, sIndex, sizeof(sIndex));
				hMenu.AddItem(sIndex, sTemp);
			}
		}
		else if( IsValidEntRef(g_iTriggers[i]) == true )
		{
			count++;
			if( index == 0 )
				Format(sTemp, sizeof(sTemp), "Replace %d", i+1);
			else
				Format(sTemp, sizeof(sTemp), "Trigger %d", i+1);

			IntToString(i, sIndex, sizeof(sIndex));
			hMenu.AddItem(sIndex, sTemp);
		}
	}

	if( index != 0 && count == 0 )
	{
		PrintToChat(client, "%sError: No saved Triggers were found.", CHAT_TAG);
		delete hMenu;
		ShowMenuMain(client);
		return;
	}

	switch( index )
	{
		case 0:		hMenu.SetTitle("Airstrike: Trigger Box - Create/Replace:");
		case 1:		hMenu.SetTitle("Airstrike: Trigger Box - Show:");
		case 2:		hMenu.SetTitle("Airstrike: Trigger Box - Delete:");
		case 3:		hMenu.SetTitle("Airstrike: Trigger Box - Maxs:");
		case 4:		hMenu.SetTitle("Airstrike: Trigger Box - Mins:");
		case 5:		hMenu.SetTitle("Airstrike: Trigger Box - Origin:");
		case 6:		hMenu.SetTitle("Airstrike: Trigger Box - Go To:");
		case 7:		hMenu.SetTitle("Airstrike: Trigger Box - Refire Count:");
		case 8:		hMenu.SetTitle("Airstrike: Trigger Box - Refire Time:");
		case 9:		hMenu.SetTitle("Airstrike: Trigger Box - Max At Once:");
	}

	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int TrigListMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuTrigger(client);
	}
	else if( action == MenuAction_Select )
	{
		int type = g_iMenuSelected[client];
		char sTemp[4];
		menu.GetItem(index, sTemp, sizeof(sTemp));
		index = StringToInt(sTemp);

		switch( type )
		{
			case 0:
			{
				if( index == -1 )
					CreateTrigger(index, client); // NEW
				else
					CreateTrigger(index, client); // REPLACE

				ShowMenuTrigger(client);
			}
			case 1:
			{
				g_iSelectedTrig = g_iTriggers[index];

				if( IsValidEntRef(g_iSelectedTrig) )
					g_hTimerBeam = CreateTimer(0.1, TimerBeam, _, TIMER_REPEAT);
				else
					g_iSelectedTrig = 0;

				ShowMenuTrigger(client);
			}
			case 2:
			{
				DeleteTrigger(client, true, index+1);
				ShowMenuTrigger(client);
			}
			case 3:
			{
				g_iMenuSelected[client] = index;
				g_hMenuVMaxs.Display(client, MENU_TIME_FOREVER);
			}
			case 4:
			{
				g_iMenuSelected[client] = index;
				g_hMenuVMins.Display(client, MENU_TIME_FOREVER);
			}
			case 5:
			{
				g_iMenuSelected[client] = index;
				g_hMenuPos.Display(client, MENU_TIME_FOREVER);
			}
			case 6:
			{
				int trigger = g_iTriggers[index];
				if( IsValidEntRef(trigger) )
				{
					float vPos[3];
					GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", vPos);

					if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 )
					{
						PrintToChat(client, "%sCannot teleport you, the Target Zone is missing.", CHAT_TAG);
					}
					else
					{
						vPos[2] += 10.0;
						TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
					}
				}
				ShowMenuTrigger(client);
			}
			case 7:
			{
				g_iMenuSelected[client] = index;
				g_hMenuRefire.Display(client, MENU_TIME_FOREVER);
			}
			case 8:
			{
				g_iMenuSelected[client] = index;
				g_hMenuTime.Display(client, MENU_TIME_FOREVER);
			}
			case 9:
			{
				g_iMenuSelected[client] = index;
				g_hMenuAtOnce.Display(client, MENU_TIME_FOREVER);
			}
		}
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - REFIRE COUNT
// ====================================================================================================
public int RefireMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuTrigger(client);
	}
	else if( action == MenuAction_Select )
	{
		int cfgindex = g_iMenuSelected[client];
		int trigger = g_iTriggers[cfgindex];

		int value;
		switch( index )
		{
			case 0, 1, 2:		value = index + 1;
			case 3:				value = 5;
			case 4:				value = g_iRefireCount[cfgindex] - 1;
			case 5:				value = g_iRefireCount[cfgindex] + 1;
			case 6:				value = 0;
		}
		if( value < 0 ) value = 0;


		KeyValues hFile = ConfigOpen();

		if( hFile != null )
		{
			char sTemp[64];
			GetCurrentMap(sTemp, sizeof(sTemp));

			if( hFile.JumpToKey(sTemp) == true )
			{
				IntToString(cfgindex+1, sTemp, sizeof(sTemp));

				if( hFile.JumpToKey(sTemp) == true )
				{
					if( value == 0 )
					{
						g_iRefireCount[cfgindex] = 0;
						hFile.DeleteKey("trig");
						PrintToChat(client, "%sRemoved trigger box '\x03%d\x05' refire count. Set to unlimited.", CHAT_TAG, cfgindex+1);

						if( IsValidEntRef(trigger) )
						{
							delete g_hTimerEnable[cfgindex];
							g_hTimerEnable[cfgindex] = CreateTimer(g_fRefireTime[cfgindex], TimerEnable, cfgindex);
						}
					}
					else
					{
						g_iRefireCount[cfgindex] = value;
						hFile.SetNum("trig", value);
						PrintToChat(client, "%sSet trigger box '\x03%d\x05' refire count to \x03%d", CHAT_TAG, cfgindex+1, value);

						if( IsValidEntRef(trigger) && GetEntProp(trigger, Prop_Data, "m_iHammerID") <= value )
						{
							delete g_hTimerEnable[cfgindex];
							g_hTimerEnable[cfgindex] = CreateTimer(g_fRefireTime[cfgindex], TimerEnable, cfgindex);
						}
					}

					ConfigSave(hFile);
				}
			}

			delete hFile;
		}

		g_hMenuRefire.Display(client, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - REFIRE TIME
// ====================================================================================================
public int TimeMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuTrigger(client);
	}
	else if( action == MenuAction_Select )
	{
		int cfgindex = g_iMenuSelected[client];
		int trigger = g_iTriggers[cfgindex];

		float value;
		switch( index )
		{
			case 0:		value = 0.5;
			case 1:		value = 1.0;
			case 2:		value = 2.0;
			case 3:		value = 3.0;
			case 4:		value = 5.0;
			case 5:		value = g_fRefireTime[cfgindex] - 0.5;
			case 6:		value = g_fRefireTime[cfgindex] + 0.5;
		}
		if( value < 0.5 ) value = 0.5;


		KeyValues hFile = ConfigOpen();

		if( hFile != null )
		{
			char sTemp[64];
			GetCurrentMap(sTemp, sizeof(sTemp));

			if( hFile.JumpToKey(sTemp) == true )
			{
				IntToString(cfgindex+1, sTemp, sizeof(sTemp));

				if( hFile.JumpToKey(sTemp) == true )
				{
					g_fRefireTime[cfgindex] = value;
					hFile.SetFloat("time", value);
					PrintToChat(client, "%sSet trigger box '\x03%d\x05' refire time to \x03%0.1f", CHAT_TAG, cfgindex+1, value);

					ConfigSave(hFile);

					if( IsValidEntRef(trigger) && GetEntProp(trigger, Prop_Data, "m_iHammerID") <= g_iRefireCount[cfgindex] )
					{
						delete g_hTimerEnable[cfgindex];
						g_hTimerEnable[cfgindex] = CreateTimer(value, TimerEnable, cfgindex);
					}
				}
			}

			delete hFile;
		}

		g_hMenuTime.Display(client, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - MAX AT ONCE
// ====================================================================================================
public int AtOnceMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuTrigger(client);
	}
	else if( action == MenuAction_Select )
	{
		int cfgindex = g_iMenuSelected[client];

		KeyValues hFile = ConfigOpen();

		if( hFile != null )
		{
			char sTemp[64];
			GetCurrentMap(sTemp, sizeof(sTemp));

			if( hFile.JumpToKey(sTemp) == true )
			{
				IntToString(cfgindex+1, sTemp, sizeof(sTemp));

				if( hFile.JumpToKey(sTemp) == true )
				{
					if( index == 0 )
					{
						g_iRefireAtOnce[cfgindex] = 1;
						hFile.DeleteKey("once");
					}
					else
					{
						g_iRefireAtOnce[cfgindex] = index + 1;
						hFile.SetNum("once", index + 1);
					}

					PrintToChat(client, "%sSet trigger box '\x03%d\x05' maximum airstrikes at once to \x03%d", CHAT_TAG, cfgindex+1, index + 1);
					ConfigSave(hFile);
				}
			}

			delete hFile;
		}

		g_hMenuAtOnce.Display(client, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - VMINS/VMAXS/VPOS - CALLBACKS
// ====================================================================================================
public int VMaxsMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuTrigger(client);
	}
	else if( action == MenuAction_Select )
	{
		float vVec[3];

		switch( index )
		{
			case 0:		vVec = view_as<float>({ 10.0, 10.0, 100.0 });
			case 1:		vVec = view_as<float>({ 25.0, 25.0, 100.0 });
			case 2:		vVec = view_as<float>({ 50.0, 50.0, 100.0 });
			case 3:		vVec = view_as<float>({ 100.0, 100.0, 100.0 });
			case 4:		vVec = view_as<float>({ 150.0, 150.0, 100.0 });
			case 5:		vVec = view_as<float>({ 200.0, 200.0, 100.0 });
			case 6:		vVec = view_as<float>({ 300.0, 300.0, 100.0 });
		}

		int cfgindex = g_iMenuSelected[client];
		int trigger = g_iTriggers[cfgindex];

		SaveTrigger(client, cfgindex + 1, "vmax", vVec);

		if( IsValidEntRef(trigger) )
			SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", vVec);

		g_iSelectedTrig = trigger;
		if( g_hTimerBeam == null )
			g_hTimerBeam = CreateTimer(0.1, TimerBeam, _, TIMER_REPEAT);

		g_hMenuVMaxs.Display(client, MENU_TIME_FOREVER);
	}
}

public int VMinsMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuTrigger(client);
	}
	else if( action == MenuAction_Select )
	{
		float vVec[3];

		switch( index )
		{
			case 0:		vVec = view_as<float>({ -10.0, -10.0, -100.0 });
			case 1:		vVec = view_as<float>({ -25.0, -25.0, -100.0 });
			case 2:		vVec = view_as<float>({ -50.0, -50.0, -100.0 });
			case 3:		vVec = view_as<float>({ -100.0, -100.0, -100.0 });
			case 4:		vVec = view_as<float>({ -150.0, -150.0, -100.0 });
			case 5:		vVec = view_as<float>({ -200.0, -200.0, -100.0 });
			case 6:		vVec = view_as<float>({ -300.0, -300.0, -100.0 });
		}

		int cfgindex = g_iMenuSelected[client];
		int trigger = g_iTriggers[cfgindex];

		SaveTrigger(client, cfgindex + 1, "vmin", vVec);

		if( IsValidEntRef(trigger) )
			SetEntPropVector(trigger, Prop_Send, "m_vecMins", vVec);

		g_iSelectedTrig = trigger;
		if( g_hTimerBeam == null )
			g_hTimerBeam = CreateTimer(0.1, TimerBeam, _, TIMER_REPEAT);

		g_hMenuVMins.Display(client, MENU_TIME_FOREVER);
	}
}

public int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuTrigger(client);
	}
	else if( action == MenuAction_Select )
	{
		int cfgindex = g_iMenuSelected[client];
		int trigger = g_iTriggers[cfgindex];

		float vPos[3];
		GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", vPos);

		switch( index )
		{
			case 0:		vPos[0] += 1.0;
			case 1:		vPos[1] += 1.0;
			case 2:		vPos[2] += 1.0;
			case 3:		vPos[0] -= 1.0;
			case 4:		vPos[1] -= 1.0;
			case 5:		vPos[2] -= 1.0;
		}

		if( index != 6 )
			TeleportEntity(trigger, vPos, NULL_VECTOR, NULL_VECTOR);
		else
			SaveTrigger(client, cfgindex + 1, "vpos", vPos);

		g_iSelectedTrig = trigger;
		if( g_hTimerBeam == null )
		{
			g_hTimerBeam = CreateTimer(0.1, TimerBeam, _, TIMER_REPEAT);
		}

		g_hMenuPos.Display(client, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					TRIGGER BOX - SAVE / DELETE
// ====================================================================================================
void SaveTrigger(int client, int index, char[] sKey, float vVec[3])
{
	KeyValues hFile = ConfigOpen();

	if( hFile != null )
	{
		char sTemp[64];
		GetCurrentMap(sTemp, sizeof(sTemp));
		if( hFile.JumpToKey(sTemp, true) )
		{
			IntToString(index, sTemp, sizeof(sTemp));

			if( hFile.JumpToKey(sTemp, true) )
			{
				hFile.SetVector(sKey, vVec);

				ConfigSave(hFile);

				if( client )
					PrintToChat(client, "%s\x01(\x05%d/%d\x01) - Saved trigger '%s'.", CHAT_TAG, index, MAX_ENTITIES, sKey);
			}
			else if( client )
			{
				PrintToChat(client, "%s\x01(\x05%d/%d\x01) - Failed to save trigger '%s'.", CHAT_TAG, index, MAX_ENTITIES, sKey);
			}
		}
		else if( client )
		{
			PrintToChat(client, "%s\x01(\x05%d/%d\x01) - Failed to save trigger '%s'.", CHAT_TAG, index, MAX_ENTITIES, sKey);
		}

		delete hFile;
	}
}

void DeleteTrigger(int client, bool trigger, int cfgindex)
{
	KeyValues hFile = ConfigOpen();

	if( hFile != null )
	{
		char sMap[64];
		GetCurrentMap(sMap, sizeof(sMap));

		if( hFile.JumpToKey(sMap) )
		{
			char sTemp[4];
			IntToString(cfgindex, sTemp, sizeof(sTemp));

			if( hFile.JumpToKey(sTemp) )
			{
				if( trigger == true )
				{
					if( IsValidEntRef(g_iTriggers[cfgindex-1]) )
						AcceptEntityInput(g_iTriggers[cfgindex-1], "Kill");
					g_iTriggers[cfgindex-1] = 0;

					hFile.DeleteKey("vpos");
					hFile.DeleteKey("vmax");
					hFile.DeleteKey("vmin");
				}
				else
				{
					g_fTargetAng[cfgindex-1] = 0.0;
					g_vTargetZone[cfgindex-1] = view_as<float>({ 0.0, 0.0, 0.0 });

					hFile.DeleteKey("pos");
					hFile.DeleteKey("ang");
				}

				float vPos[3];
				if( trigger == true )
					hFile.GetVector("pos", vPos);
				else
					hFile.GetVector("vpos", vPos);

				hFile.GoBack();

				if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 )
				{
					for( int i = cfgindex; i < MAX_ENTITIES; i++ )
					{
						g_iTriggers[i-1] = g_iTriggers[i];
						g_iTriggers[i] = 0;

						g_fTargetAng[i-1] = g_fTargetAng[i];
						g_fTargetAng[i] = 0.0;

						g_vTargetZone[i-1] = g_vTargetZone[i];
						g_vTargetZone[i] = view_as<float>({ 0.0, 0.0, 0.0 });

						IntToString(i+1, sTemp, sizeof(sTemp));

						if( hFile.JumpToKey(sTemp) )
						{
							IntToString(i, sTemp, sizeof(sTemp));
							hFile.SetSectionName(sTemp);
							hFile.GoBack();
						}
					}
				}

				ConfigSave(hFile);

				PrintToChat(client, "%sAirstrike TriggerBox removed from config.", CHAT_TAG);
			}
		}

		delete hFile;
	}
}



// ====================================================================================================
//					TRIGGER BOX - SPAWN TRIGGER / TOUCH CALLBACK
// ====================================================================================================
void CreateTrigger(int index = -1, int client)
{
	if( index == -1 )
	{
		for( int i = 0; i < MAX_ENTITIES; i++ )
		{
			if( g_vTargetZone[i][0] == 0.0 && g_vTargetZone[i][1] == 0.0 && g_vTargetZone[i][2] == 0.0 && IsValidEntRef(g_iTriggers[i]) == false )
			{
				index = i;
				break;
			}
		}
	}
	if( index == -1 )
	{
		PrintToChat(client, "%sError: Cannot create a new group, you must pair to a Target Zone or replace/delete triggers.", CHAT_TAG);
		return;
	}

	float vPos[3];
	GetClientAbsOrigin(client, vPos);

	g_iRefireCount[index] = 0;
	index += 1;

	CreateTriggerMultiple(index, vPos, view_as<float>({ 25.0, 25.0, 100.0}), view_as<float>({ -25.0, -25.0, 0.0 }));

	SaveTrigger(client, index, "vpos", vPos);
	SaveTrigger(client, index, "vmax", view_as<float>({ 25.0, 25.0, 100.0}));
	SaveTrigger(client, index, "vmin", view_as<float>({ -25.0, -25.0, 0.0 }));

	g_iSelectedTrig = g_iTriggers[index-1];

	if( g_hTimerBeam == null )
	{
		g_hTimerBeam = CreateTimer(0.1, TimerBeam, _, TIMER_REPEAT);
	}
}

void CreateTriggerMultiple(int index, float vPos[3], float vMaxs[3], float vMins[3])
{
	int trigger = CreateEntityByName("trigger_multiple");
	DispatchKeyValue(trigger, "StartDisabled", "1");
	DispatchKeyValue(trigger, "spawnflags", "1");
	DispatchKeyValue(trigger, "entireteam", "0");
	DispatchKeyValue(trigger, "allowincap", "0");
	DispatchKeyValue(trigger, "allowghost", "0");

	DispatchSpawn(trigger);
	SetEntityModel(trigger, MODEL_BOX);

	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", vMaxs);
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", vMins);
	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
	TeleportEntity(trigger, vPos, NULL_VECTOR, NULL_VECTOR);

	delete g_hTimerEnable[index-1];
	g_hTimerEnable[index-1] = CreateTimer(g_fRefireTime[index-1], TimerEnable, index-1);

	HookSingleEntityOutput(trigger, "OnStartTouch", OnStartTouch);
	g_iTriggers[index-1] = EntIndexToEntRef(trigger);
}

public Action TimerEnable(Handle timer, any index)
{
	g_hTimerEnable[index] = null;

	int entity = g_iTriggers[index];
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Enable");
}

public void OnStartTouch(const char[] output, int caller, int activator, float delay)
{
	if( IsClientInGame(activator) && GetClientTeam(activator) == 2 )
	{
		caller = EntIndexToEntRef(caller);

		for( int i = 0; i < MAX_ENTITIES; i++ )
		{
			if( caller == g_iTriggers[i] )
			{
				AcceptEntityInput(caller, "Disable");

				if( g_iRefireCount[i] == 0 ) // Unlimited refires or limited, create timer to enable the trigger.
				{
					ShowAirStrike(i);

					delete g_hTimerEnable[i];
					g_hTimerEnable[i] = CreateTimer(g_fRefireTime[i], TimerEnable, i);
				}
				else
				{
					int fired = GetEntProp(caller, Prop_Data, "m_iHammerID");

					if( g_iRefireCount[i] > fired )
					{
						ShowAirStrike(i);

						SetEntProp(caller, Prop_Data, "m_iHammerID", fired + 1);
						if( fired + 1 != g_iRefireCount[i] )
						{
							delete g_hTimerEnable[i];
							g_hTimerEnable[i] = CreateTimer(g_fRefireTime[i], TimerEnable, i);
						}
					}
				}

				break;
			}
		}
	}
}

void ShowAirStrike(int i)
{
	int count = g_iRefireAtOnce[i];

	if( count > 1 )
	{
		if( count > 7 ) count = 7;

		for( int loop = 1; loop < count; loop++ )
		{
			CreateTimer(0.3 * loop, TimerCreate, i);
		}
	}

	F18_ShowAirstrike(g_vTargetZone[i], g_fTargetAng[i]);
}

public Action TimerCreate(Handle timer, any i)
{
	F18_ShowAirstrike(g_vTargetZone[i], g_fTargetAng[i]);
}



// ====================================================================================================
//					TRIGGER BOX - DISPLAY BEAM BOX
// ====================================================================================================
public Action TimerBeam(Handle timer)
{
	if( IsValidEntRef(g_iSelectedTrig) )
	{
		float vMaxs[3], vMins[3], vPos[3];
		GetEntPropVector(g_iSelectedTrig, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(g_iSelectedTrig, Prop_Send, "m_vecMaxs", vMaxs);
		GetEntPropVector(g_iSelectedTrig, Prop_Send, "m_vecMins", vMins);
		AddVectors(vPos, vMaxs, vMaxs);
		AddVectors(vPos, vMins, vMins);
		TE_SendBox(vMins, vMaxs);
		return Plugin_Continue;
	}

	g_hTimerBeam = null;
	return Plugin_Stop;
}

void TE_SendBox(float vMins[3], float vMaxs[3])
{
	float vPos1[3], vPos2[3], vPos3[3], vPos4[3], vPos5[3], vPos6[3];
	vPos1 = vMaxs;
	vPos1[0] = vMins[0];
	vPos2 = vMaxs;
	vPos2[1] = vMins[1];
	vPos3 = vMaxs;
	vPos3[2] = vMins[2];
	vPos4 = vMins;
	vPos4[0] = vMaxs[0];
	vPos5 = vMins;
	vPos5[1] = vMaxs[1];
	vPos6 = vMins;
	vPos6[2] = vMaxs[2];
	TE_SendBeam(vMaxs, vPos1);
	TE_SendBeam(vMaxs, vPos2);
	TE_SendBeam(vMaxs, vPos3);
	TE_SendBeam(vPos6, vPos1);
	TE_SendBeam(vPos6, vPos2);
	TE_SendBeam(vPos6, vMins);
	TE_SendBeam(vPos4, vMins);
	TE_SendBeam(vPos5, vMins);
	TE_SendBeam(vPos5, vPos1);
	TE_SendBeam(vPos5, vPos3);
	TE_SendBeam(vPos4, vPos3);
	TE_SendBeam(vPos4, vPos2);
}

void TE_SendBeam(const float vMins[3], const float vMaxs[3])
{
	TE_SetupBeamPoints(vMins, vMaxs, g_iLaserMaterial, g_iHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 155, 0, 255 }, 0);
	TE_SendToAll();
}



// ====================================================================================================
//					CONFIG - OPEN
// ====================================================================================================
KeyValues ConfigOpen()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);

	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	KeyValues hFile = new KeyValues("airstrike");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return null;
	}

	return hFile;
}



// ====================================================================================================
//					CONFIG - SAVE
// ====================================================================================================
void ConfigSave(KeyValues hFile)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);

	if( !FileExists(sPath) )
		return;

	hFile.Rewind();
	hFile.ExportToFile(sPath);
}



// ====================================================================================================
//					OTHER
// ====================================================================================================
bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}