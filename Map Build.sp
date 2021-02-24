#pragma newdecls required
#pragma semicolon 1

#define CONFIGS_SPAWN		"data/builder/build_positions.cfg"
#define CARS_LIST		"data/builder/Default 1.ini"
#define PROPS_LIST		"data/builder/Default 2.ini"
#define CUSTOMS_LIST		"data/builder/build_custom.cfg"

#define MAXENTITIES 64

#include <sourcemod>
#include <sdktools>

public Plugin myinfo=
{
	name = "Map Build",
	author = "BHaType",
	description = "Admin can create onbjects.",
	version = "0.0.0",
	url = "N/A"
};


static const char sNamesConfigs[][] =
{
	"Default 1",
	"Default 2"
};

static const char sCustomsConfigs[12][56] =
{
	"sName",
	"sName",
	"sName",
	"sName",
	"sName",
	"sName",
	"sName",
	"sName",
	"sName",
	"sName",
	"sName",
	"sName"
};

int g_iBuilds[MAXENTITIES];
float g_vPos[MAXENTITIES][3], g_vAng[MAXENTITIES][3];
Menu g_hMainMenu, g_hCategories, g_hMenuSpawner, g_hRemoveMenu, g_hRotateMenu, g_hMoveMenu;
bool g_bLoaded;


public void OnPluginStart()
{
	char iLineBuffer[64], sPath[PLATFORM_MAX_PATH], sPathCustomConfig[PLATFORM_MAX_PATH], szPathCustoms[PLATFORM_MAX_PATH], szCustomsBuffer[56];
	int iNum;
	g_hCategories = new Menu(VCategoryHandler);
	g_hCategories.AddItem("", "Default config 1");
	g_hCategories.AddItem("", "Default config 2");
	for(int i; i < 2; i++)
	{
		BuildPath(Path_SM, sPath, sizeof(sPath), "data/builder/%s.ini", sNamesConfigs[i]);
		
		File iFile = OpenFile(sPath, "r");
		if(!iFile) continue;
		
		while(ReadFileLine(iFile, iLineBuffer, sizeof(iLineBuffer))) 
		{ 
			TrimString(iLineBuffer);
			PrecacheModel(iLineBuffer, true);
		}
		delete iFile;
	}
	PrintToServer("[Build Menu] Cached all models");
	
	BuildPath(Path_SM, sPathCustomConfig, sizeof(sPathCustomConfig), "%s", CUSTOMS_LIST);
	File iCustoms = OpenFile(sPathCustomConfig, "r");
	if(iCustoms)
	{
		while(ReadFileLine(iCustoms, sCustomsConfigs[iNum], sizeof sCustomsConfigs[]))
		{
			TrimString(sCustomsConfigs[iNum]);
			
			g_hCategories.AddItem(sCustomsConfigs[iNum], sCustomsConfigs[iNum]);
			
			BuildPath(Path_SM, szPathCustoms, sizeof(szPathCustoms), "data/builder/%s.ini", sCustomsConfigs[iNum]);
			File iCustomConfig = OpenFile(szPathCustoms, "r");
			if(!iCustomConfig) continue;

			while(ReadFileLine(iCustomConfig, szCustomsBuffer, sizeof szCustomsBuffer)) 
			{
				TrimString(szCustomsBuffer);
				PrecacheModel(szCustomsBuffer, true);
			}
			iNum++;
			delete iCustomConfig;
		}
		delete iCustoms;
		PrintToServer("[Build Menu] Cached all custom configs");
	}
	
	g_hCategories.SetTitle("Category Menu: Select");
	g_hCategories.ExitBackButton = true;
	
	g_hMainMenu = new Menu(VMainMenuHandler);
	g_hMainMenu.AddItem("", "CONFIGS");
	g_hMainMenu.AddItem("", "REMOVE");
	g_hMainMenu.AddItem("", "ROTATE");
	g_hMainMenu.AddItem("", "MOVE");
	g_hMainMenu.SetTitle("Main Menu: Select");
	g_hMainMenu.ExitButton = true;
	
	g_hRotateMenu = new Menu(VRotateHandler);
	g_hRotateMenu.AddItem("", "X + 1.0");
	g_hRotateMenu.AddItem("", "Y + 1.0");
	g_hRotateMenu.AddItem("", "Z + 1.0");
	g_hRotateMenu.AddItem("", "X - 1.0");
	g_hRotateMenu.AddItem("", "Y - 1.0");
	g_hRotateMenu.AddItem("", "Z - 1.0");
	g_hRotateMenu.SetTitle("Category Menu: Select");
	g_hRotateMenu.ExitBackButton = true;
	
	g_hMoveMenu = new Menu(VMoveHandler);
	g_hMoveMenu.AddItem("", "X + 1.0");
	g_hMoveMenu.AddItem("", "Y + 1.0");
	g_hMoveMenu.AddItem("", "Z + 1.0");
	g_hMoveMenu.AddItem("", "X - 1.0");
	g_hMoveMenu.AddItem("", "Y - 1.0");
	g_hMoveMenu.AddItem("", "Z - 1.0");
	g_hMoveMenu.SetTitle("Category Menu: Select");
	g_hMoveMenu.ExitBackButton = true;
	
	RegConsoleCmd("sm_b", cBuildMenu);
}

public int VMoveHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
	
		int iModel = GetClientAimTarget(client, false);
		int g_iBuild;
		for(int i; i < MAXENTITIES; i++)
		{
			if(IsValidEntRef(g_iBuilds[i]) && EntRefToEntIndex(g_iBuilds[i]) == iModel)
			{
				iModel = EntRefToEntIndex(g_iBuilds[i]);
				g_iBuild = i;
				break;
			}
		}
		
		if(IsValidEntity(iModel))
		{
			float vPos[3];
			GetEntPropVector(iModel, Prop_Send, "m_vecOrigin", vPos);

			if( index == 0 )
				vPos[0] += 1.0;
			else if( index == 1 )
				vPos[1] += 1.0;
			else if( index == 2 )
				vPos[2] += 1.0;
			else if( index == 3 )
				vPos[0] -= 1.0;
			else if( index == 4 )
				vPos[1] -= 1.0;
			else if( index == 5 )
				vPos[2] -= 1.0;
				
			TeleportEntity(iModel, vPos, NULL_VECTOR, NULL_VECTOR);
			SaveModel(client, g_iBuild, "vpos", vPos, false);
		}
		g_hMoveMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int VRotateHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		int iModel = GetClientAimTarget(client, false);
		int g_iBuild;
		for(int i; i < MAXENTITIES; i++)
		{
			if(IsValidEntRef(g_iBuilds[i]) && EntRefToEntIndex(g_iBuilds[i]) == iModel)
			{
				iModel = EntRefToEntIndex(g_iBuilds[i]);
				g_iBuild = i;
				break;
			}
		}
		
		if(IsValidEntity(iModel))
		{
			float vAng[3];
			GetEntPropVector(iModel, Prop_Send, "m_angRotation", vAng);

			if( index == 0 )
				vAng[0] += 1.0;
			else if( index == 1 )
				vAng[1] += 1.0;
			else if( index == 2 )
				vAng[2] += 1.0;
			else if( index == 3 )
				vAng[0] -= 1.0;
			else if( index == 4 )
				vAng[1] -= 1.0;
			else if( index == 5 )
				vAng[2] -= 1.0;
				
			TeleportEntity(iModel, NULL_VECTOR, vAng, NULL_VECTOR);
			SaveModel(client, g_iBuild, "vang", vAng, false);
		}
		g_hRotateMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int VMainMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		switch (index)
		{
			case 0:
			{
				g_hCategories.Display(client, MENU_TIME_FOREVER);
			}
			case 1:
			{
				DeleteMenu(client);
			}
			case 2:
			{
				g_hRotateMenu.Display(client, MENU_TIME_FOREVER);
			}
			case 3:
			{
				g_hMoveMenu.Display(client, MENU_TIME_FOREVER);
			}
		}
	}
}

public int VCategoryHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		switch (index)
		{
			case 0:
			{
				keySetup(client, 0, "sName");
			}
			case 1:
			{
				keySetup(client, 1, "sName");
			}
			default:
			{
				char sItemName[36];
				GetMenuItem(menu, index, sItemName, sizeof sItemName);
				keySetup(client, -1, sItemName);
			}
		}
	}
}

public int VSpawnerHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hCategories.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		float vPos[3], vAng[3], vVectorEnd[3];
		char szMenuItem[128];
		GetMenuItem(menu, index, szMenuItem, sizeof szMenuItem);
		GetClientEyePosition(client, vPos); 
		GetClientEyeAngles(client, vAng);

		Handle hTrace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter);
		if( TR_DidHit(hTrace) )
		{
			TR_GetEndPosition(vVectorEnd, hTrace);
			GetVectorAngles(vAng, vAng);
			CreateBuild(-1, vVectorEnd, vAng, szMenuItem, client);
		}
		g_hCategories.Display(client, MENU_TIME_FOREVER);
		delete hTrace;
	}
}

public int VRemoveHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		char szMenuItem[128];
		GetMenuItem(menu, index, szMenuItem, sizeof szMenuItem);
		index = StringToInt(szMenuItem);
		DeleteModel(client, index + 1);
		g_hRemoveMenu.Display(client, MENU_TIME_FOREVER);
	}
}

void keySetup (int client, int index = -1, char[] sConfigName)
{
	char iLineBuffer[64], sPath[PLATFORM_MAX_PATH], szExplodeString[6][128];
	int iStringsCount;
	g_hMenuSpawner = new Menu(VSpawnerHandler);
	
	if(index != -1)
	{
		BuildPath(Path_SM, sPath, sizeof(sPath), "data/builder/%s.ini", sNamesConfigs[index]);
		
		File iFile = OpenFile(sPath, "r");
		if(iFile)
		{
			while(ReadFileLine(iFile, iLineBuffer, sizeof(iLineBuffer))) 
			{ 
				TrimString(iLineBuffer);
				iStringsCount = ExplodeString(iLineBuffer, "/", szExplodeString, sizeof szExplodeString, sizeof szExplodeString[]);
				ReplaceString(szExplodeString[iStringsCount - 1], sizeof szExplodeString[], ".mdl", "");
				g_hMenuSpawner.AddItem(iLineBuffer, szExplodeString[iStringsCount - 1]);
			}
		}
		delete iFile;
	}
	else
	{
		if(strcmp(sConfigName, "sName") == -1)
		{
			BuildPath(Path_SM, sPath, sizeof(sPath), "data/builder/%s.ini", sConfigName);
			File iFileCustom = OpenFile(sPath, "r");
			if(!iFileCustom) SetFailState("You dont have %s.ini", sConfigName);
			while(ReadFileLine(iFileCustom, iLineBuffer, sizeof(iLineBuffer))) 
			{ 
				TrimString(iLineBuffer);
				iStringsCount = ExplodeString(iLineBuffer, "/", szExplodeString, sizeof szExplodeString, sizeof szExplodeString[]);
				ReplaceString(szExplodeString[iStringsCount - 1], sizeof szExplodeString[], ".mdl", "");
				g_hMenuSpawner.AddItem(iLineBuffer, szExplodeString[iStringsCount - 1]);
			}
			delete iFileCustom;
		}
	}
	g_hMenuSpawner.SetTitle("Category Menu: Select");
	g_hMenuSpawner.ExitBackButton = true;
	
	g_hMenuSpawner.Display(client, MENU_TIME_FOREVER);
}

public void OnPluginEnd()
{
	ResetPlugin();
}

void ResetPlugin()
{
	g_bLoaded = false;

	for( int i = 0; i < MAXENTITIES; i++ )
	{
		g_vPos[i] = view_as<float>({0.0, 0.0, 0.0});

		if( IsValidEntRef(g_iBuilds[i]) )
			AcceptEntityInput(g_iBuilds[i], "Kill");
		g_iBuilds[i] = 0;
	}
}

public void OnMapStart()
{
	g_bLoaded = false;
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	LoadModels();
}

public void OnRoundStart (Event event, const char[] name, bool dontbroadcast)
{
	ResetPlugin();
	g_bLoaded = false;
	LoadModels();
}

void LoadModels()
{
	if(g_bLoaded)
		return;
	g_bLoaded = true;
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIGS_SPAWN);
	if( !FileExists(sPath) )
		return;

	KeyValues hFile = new KeyValues("airdrop");
	hFile.ImportFromFile(sPath);

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	char sTemp[16], szModel[128];
	float vPos[3], vAng[3];

	for( int i = 0; i <= MAXENTITIES; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp, false) )
		{
			hFile.GetVector("vpos", vPos);
			hFile.GetVector("vang", vAng);
			hFile.GetString("model", szModel, sizeof szModel);
			
			g_vPos[i] = vPos;
			g_vAng[i] = vAng;

			if( vPos[0] != 0.0 && vPos[1] != 0.0 && vPos[2] != 0.0 )
			{
				CreateModel(i, vPos, vAng, szModel);
			}

			hFile.GoBack();
		}
	}

	delete hFile;
}

// ====================================================================================================
//					CREATING
// ====================================================================================================

void CreateBuild(int index = -1, float vPos[3], float vAng[3], char[] szModel, int client)
{
	if( index == -1 )
	{
		for( int i = 0; i < MAXENTITIES; i++ )
		{
			if(g_vAng[i][0] == 0.0 && g_vAng[i][1] == 0.0 && g_vAng[i][2] == 0.0 && g_vPos[i][0] == 0.0 && g_vPos[i][1] == 0.0 && g_vPos[i][2] == 0.0 && !IsValidEntRef(g_iBuilds[i]))
			{
				index = i;
				break;
			}
		}
	}
	if( index == -1 )
	{
		PrintToChat(client, "[Build Menu] Error: not enough space");
		return;
	}
	
	CreateModel(index, vPos, vAng, szModel);

	SaveModel(client, index, "vpos", vPos, true);
	SaveModel(client, index, "vang", vAng, false);
	SaveModel(client, index, "model", vAng, false, true, szModel);
	g_vPos[index] = vPos;
	g_vAng[index] = vAng;
}

void SaveModel(int client, int index, char[] sKey, float vVec[3], bool chat, bool string = false, char[] szModelName = "")
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
				if(!string)
					hFile.SetVector(sKey, vVec);
				else
					hFile.SetString(sKey, szModelName);

				ConfigSave(hFile);

				if( client && chat)
					PrintToChat(client, "\x03[Build Menu] \x05Model has been created.");
			}
		}

		delete hFile;
	}
}

void DeleteModel(int client, int cfgindex)
{
	KeyValues hFile = ConfigOpen();

	if( hFile != null )
	{
		char sMap[64];
		GetCurrentMap(sMap, sizeof(sMap));

		if( hFile.JumpToKey(sMap) )
		{
			char sTemp[16];
			IntToString(cfgindex - 1, sTemp, sizeof(sTemp));
			if( hFile.JumpToKey(sTemp) )
			{
				if( IsValidEntRef(g_iBuilds[cfgindex - 1]) )
					AcceptEntityInput(g_iBuilds[cfgindex - 1], "Kill");
				g_iBuilds[cfgindex - 1] = 0;

				hFile.DeleteKey("vpos");
				hFile.DeleteKey("vang");
				hFile.DeleteKey("Model");

				float vPos[3];
				hFile.GetVector("pos", vPos);


				hFile.GoBack();

				if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 )
				{
					for( int i = cfgindex; i < MAXENTITIES; i++ )
					{
						g_iBuilds[i - 1] = g_iBuilds[i];
						g_iBuilds[i] = 0;

						g_vPos[i - 1] = g_vPos[i];
						g_vPos[i] = view_as<float>({ 0.0, 0.0, 0.0 });

						g_vAng[i - 1] = g_vAng[i];
						g_vAng[i] = view_as<float>({ 0.0, 0.0, 0.0 });

						IntToString(i, sTemp, sizeof(sTemp));
						if( hFile.JumpToKey(sTemp) )
						{
							IntToString(i - 1, sTemp, sizeof(sTemp));
							hFile.SetSectionName(sTemp);
							hFile.GoBack();
						}
					}
				}
				PrintToChat(client, "\x03[Build Menu] \x05 model has been deleted.");
				ConfigSave(hFile);

			}
		}

		delete hFile;
	}
}

void CreateModel(int index, float vPos[3], float vAng[3], char[] szModel)
{
	int iDynamic = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(iDynamic, "model", szModel);
	DispatchKeyValue(iDynamic, "solid", "6");
	TeleportEntity(iDynamic, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(iDynamic);


	g_iBuilds[index] = EntIndexToEntRef(iDynamic);
}

void DeleteMenu(int client)
{
	int count;
	char szTemp[4];
	g_hRemoveMenu = new Menu(VRemoveHandler);
	
	for( int i = 0; i < MAXENTITIES; i++ )
	{
		if( g_vPos[i][0] != 0.0 && g_vPos[i][1] != 0.0 && g_vPos[i][2] != 0.0 && IsValidEntRef(g_iBuilds[i]) == true)
		{
			count++;
			IntToString(i, szTemp, sizeof szTemp);
			g_hRemoveMenu.AddItem(szTemp, szTemp);
		}
	}
	
	if(!count)
	{
		PrintToChat(client, "\x03[Build Menu] \x05Error: Config didnt have any models in config");
		return;
	}
	
	g_hRemoveMenu.SetTitle("Remove Menu: Select Info");
	g_hRemoveMenu.ExitBackButton = true;
	g_hRemoveMenu.Display(client, MENU_TIME_FOREVER);
}

// ====================================================================================================
//					STUFF
// ====================================================================================================

public Action cBuildMenu (int client, int args)
{
	g_hMainMenu.Display(client, MENU_TIME_FOREVER);
}

public bool TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients;
}

KeyValues ConfigOpen()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIGS_SPAWN);

	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	KeyValues hFile = new KeyValues("buildings");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return null;
	}

	return hFile;
}

void ConfigSave(KeyValues hFile)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIGS_SPAWN);

	if( !FileExists(sPath) )
		return;

	hFile.Rewind();
	hFile.ExportToFile(sPath);
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}