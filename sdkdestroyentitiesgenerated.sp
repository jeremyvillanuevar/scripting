#define PLUGIN_VERSION		"1.0"
#define BUFFER_SIZE			8192

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

static Handle sdkcall;

public Plugin myinfo =
{
	name = "[ANY/CSGO] cutlrbtree overflow, memory access",
	author = "ekshon",
	description = "you can get this unique ID and remove string in OnEntityDestroyed very easily.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=328421"
}

public void OnPluginStart()
{
/*
    sdkcall = INVALID_HANDLE;
    StartPrepSDKCall(SDKCall_Static);
    //signature is for windows
    PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x56\x8D\x45\x08\xB9",8);
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	if ((sdkcall = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create SDKCall for SDKPass_Pointer signature!"); 
*/
}

public void OnEntityCreated(int entity, const char[] classname)
{
    SetEntProp(entity,Prop_Data,"m_bForcePurgeFixedupStrings",true);
}

public void OnEntityDestroyed(int entity)
{
/*
	PrintToChatAll("testeando");
	char buffer[128] = "";
	GetEntPropString(entity, Prop_Data, "m_iszScriptId", buffer, sizeof(buffer));	

	if (strlen(buffer) <= 0)
	{
		PrintToChatAll("no hay buffer = %i", buffer);
		return;
	}
	else
	{
		PrintToChatAll("buffer = %i", buffer);
		SDKCall(sdkcall,buffer);
	}
*/
}

public void OnPluginEnd()
{
    
//		CloseHandle(sdkcall);		
}
