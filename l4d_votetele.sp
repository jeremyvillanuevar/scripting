#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <left4dhooks>

#define PLUGIN_VERSION "1.2"

#define CVAR_FLAGS		FCVAR_NOTIFY
#define PRIVATE_STUFF	0

public Plugin myinfo = 
{
	name = "[L4D] Vote noobs teleporter",
	author = "Dragokas",
	description = "Vote for teleporting noobs and stucked players to your position",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
};

/*
	This plugin is based on "[L4D] Votekick (no black screen)" by Dragokas.
	
	====================================================================================
	
	Description:
	 - This plugin is usually intended to teleport noobs in saferoom.
	
	Features:
	 - teleport players with > X distance to your position.
	 - teleport players that collide with some objects, including self-help.
	
	Logfile location:
	 - logs/vote_tele.log

	Permissions:
	 - by default, vote can be started by everybody (adjustable).
	 - ability to set minimum time to allow repeat the vote.
	 - ability to set minimum players count to allow starting the vote.
	 - ability to start teleport without vote for players with selected admin flag.
	 - set #PRIVATE_STUFF to 1 to unlock some additional options - forbid vote by name or SteamID
	
	Settings (ConVars):
	 - sm_votetele_maxdist - def.: 100.0 - Maximum safe distance to player who vote (other players + stuck players will be teleported)
	 - sm_votetele_delay - def.: 60 - Minimum delay (in sec.) allowed between votes
	 - sm_votetele_timeout - def.: 10 - How long (in sec.) does the vote last
	 - sm_votetele_announcedelay - def.: 2.0 - Delay (in sec.) between announce and vote menu appearing
	 - sm_votetele_minplayers - def.: 2 - Minimum players present in game to allow starting vote for teleporting
	 - sm_votetele_accessflag - def.: "" - Admin flag required to start the vote (leave empty to allow for everybody)
	 - sm_votetele_overrideflag - def.: "k" - Admin flag required to start teleporting without the vote (leave empty to disable this ability)
	 - sm_votetele_log - def.: 1 - Use logging? (1 - Yes / 0 - No)
	 - sm_votetele_preventontanks - def.: 1 - Prevent using vote teleport when tanks count > 0 (require left4dragokas.smx)
	
	Commands:
	
	- sm_tele (sm_noobs, sm_noob) - Try to start vote for teleporting
	- sm_stuck - to self help in case you get stuck in texture by incident.
	- sm_veto - Allow admin to veto current vote (ADMFLAG_BAN is required)
	- sm_votepass - Allow admin to bypass current vote (ADMFLAG_BAN is required)
	
	Requirements:
	 - GeoIP extension (included in SourceMod).
	 - (optional) "left4dragokas" - to use "sm_votetele_preventontanks" functionality.
	
	Languages:
	 - Russian
	 - English
	
	Installation:
	 - copy smx file to addons/sourcemod/plugins/
	 - copy phrases.txt file to addons/sourcemod/translations/

*/

char g_sLog[PLATFORM_MAX_PATH];

int iLastTime[MAXPLAYERS+1];

bool g_bVeto;
bool g_bVotepass;
bool g_bVoteInProgress;
bool g_bVoteDisplayed;

float g_fDestPos[3];
int g_iInitiator;
int g_iGotoFriend;
int g_iTankCount;
int g_iVoteCommand = 1;

ConVar g_hCvarMaxDist;
ConVar g_hCvarDelay;
ConVar g_hCvarAnnounceDelay;
ConVar g_hCvarTimeout;
ConVar g_hCvarLog;
ConVar g_hMinPlayers;
ConVar g_hCvarAccessFlag;
ConVar g_hCvarOverrideFlag;
ConVar g_hConVarPreventOnTanks;

public void OnPluginStart()
{
	LoadTranslations("l4d_votetele.phrases");
	CreateConVar("l4d_votetele_version", PLUGIN_VERSION, "Version of L4D Votetele on this server", FCVAR_DONTRECORD);
	
	g_hCvarMaxDist = CreateConVar(			"sm_votetele_maxdist",			"100.0",			"Maximum safe distance to player who vote (other players + stuck players will be teleported)", CVAR_FLAGS );
	g_hCvarDelay = CreateConVar(			"sm_votetele_delay",			"60",				"Minimum delay (in sec.) allowed between votes", CVAR_FLAGS );
	g_hCvarTimeout = CreateConVar(			"sm_votetele_timeout",			"10",				"How long (in sec.) does the vote last", CVAR_FLAGS );
	g_hCvarAnnounceDelay = CreateConVar(	"sm_votetele_announcedelay",	"2.0",				"Delay (in sec.) between announce and vote menu appearing", CVAR_FLAGS );
	g_hMinPlayers = CreateConVar(			"sm_votetele_minplayers",		"2",				"Minimum players present in game to allow starting vote for teleporting", CVAR_FLAGS );
	g_hCvarAccessFlag = CreateConVar(		"sm_votetele_accessflag",		"",					"Admin flag required to start the vote (leave empty to allow for everybody)", CVAR_FLAGS );
	g_hCvarOverrideFlag = CreateConVar(		"sm_votetele_overrideflag",		"k",				"Admin flag required to start teleporting without the vote (leave empty to disable this ability)", CVAR_FLAGS );
	g_hConVarPreventOnTanks = CreateConVar(	"sm_votetele_preventontanks",	"1",				"Prevent using vote teleport when tanks count > 0", CVAR_FLAGS );
	g_hCvarLog = CreateConVar(				"sm_votetele_log",				"1",				"Use logging? (1 - Yes / 0 - No)", CVAR_FLAGS );
	
	AutoExecConfig(true,				"sm_votetele");
	
	RegConsoleCmd("sm_tele", Command_Votetele);
	RegConsoleCmd("sm_traer", Command_Votetele);
	RegConsoleCmd("sm_traeramigos", Command_Votetele);
	RegConsoleCmd("sm_noobs", Command_Votetele);
	RegConsoleCmd("sm_noob", Command_Votetele);
	RegConsoleCmd("sm_tpall", Command_Votetele);
	
	RegConsoleCmd("sm_stuck", Command_Unstuck);
	
	RegConsoleCmd("sm_tp", Command_VoteGotoF);
	RegConsoleCmd("sm_acercarseaamigos", Command_VoteGotoF);
	RegConsoleCmd("sm_acercarse", Command_VoteGotoF);
	RegConsoleCmd("sm_acercar", Command_VoteGotoF);
	RegConsoleCmd("sm_gotofriends", Command_VoteGotoF);
	
	RegAdminCmd("sm_veto", 			Command_Veto, 		ADMFLAG_VOTE, 	"Allow admin to veto current vote.");
	RegAdminCmd("sm_votepass", 		Command_Votepass, 	ADMFLAG_BAN, 	"Allow admin to bypass current vote.");
	
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/vote_tele.log");
	
	HookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
}

public Action Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast) 
{
	g_iTankCount = 0;
}

public void OnTankCountChanged(int iTanks)
{
	g_iTankCount = iTanks;
}

public Action Command_Unstuck(int client, int args)
{
	if (IsClientRootAdmin(client))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				UnStuck(i);
			}
		}
	}
	else {
		UnStuck(client);
	}
	return Plugin_Handled;
}

void UnStuck(int client)
{
	static float vOrigin[3];
	
	if (IsClientStuck(client))
	{
		int iNear = GetNearestSurvivorEx(client);
		if (iNear != 0)
		{
			GetClientAbsOrigin(iNear, vOrigin);
			vOrigin[2] += GetRandomFloat(0.0, 10.0);
			TeleportEntity(client, vOrigin, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

int GetNearestSurvivorEx(int client) {
	static float tpos[3], spos[3], dist, mindist;
	static int i, iNearClient;
	mindist = 0.0;
	iNearClient = 0;
	GetClientAbsOrigin(client, tpos);
	
	for (i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsClientStuck(i)) {
			GetClientAbsOrigin(i, spos);
			dist = GetVectorDistance(tpos, spos, false);
			if (dist < mindist || mindist < 0.1) {
				mindist = dist;
				iNearClient = i;
			}
		}
	}
	return iNearClient;
}

public Action Command_Veto(int client, int args)
{
	if (g_bVoteInProgress) { // IsVoteInProgress() is not working here, sm bug?
		g_bVeto = true;
		CPrintToChatAll("%t", "veto", client);
		if (g_bVoteDisplayed) CancelVote();
		LogVoteAction(client, "[VETO]");
	}
	return Plugin_Handled;
}

public Action Command_Votepass(int client, int args)
{
	if (g_bVoteInProgress) {
		g_bVotepass = true;
		CPrintToChatAll("%t", "votepass", client);
		if (g_bVoteDisplayed) CancelVote();
		LogVoteAction(client, "[PASS]");
	}
	return Plugin_Handled;
}

public Action Command_Votetele(int client, int args)
{
	if(client != 0)
	{
		g_iInitiator = client;
		g_iVoteCommand =1;//Command_Votetele
		if (StartVoteAccessCheck(client))
		{
			StartVoteTele(client);
		}
	}
	return Plugin_Handled;
}

public Action Command_VoteGotoF(int client, int args)
{
		
	if(args < 1)//tp sin argumentos
	{		
		if(client != 0)
		{			
			g_iVoteCommand =2;//Command_VoteGotoF	
			g_iInitiator = client;
			if (StartVoteAccessCheck(client))
			{				
				StartVoteTele(client);
			}
		}
		//Return:
		return Plugin_Handled;
	}
	
	//tp con argumentos
	
	//Declare:
	int player;
	char playerName[32], name[32];
	
	//Initialize:
	player = -1;
	GetCmdArg(1, playerName, sizeof(playerName));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		//Connected:
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{			
			//Initialize:
			GetClientName(i, name, sizeof(name));

			//Save:
			if(StrContains(name, playerName, false) != -1) player = i;
		}
	}
		
	
	//Invalid Name:
	if(player == -1)
	{
		//Print:
		PrintToConsole(client, "No se encontró al jugador \x04%s", playerName);
		//Return:
		return Plugin_Handled;
	}
		
	if(client != 0)
	{
		g_iVoteCommand =3;//Command_VoteGotoF
		g_iInitiator = client;
		g_iGotoFriend=player;
		if (StartVoteAccessCheck(client))
		{
			StartVoteTele(client);
		}
	}
	
	//Return:
	return Plugin_Handled;
	
}

bool StartVoteAccessCheck(int client)
{
	
	if (IsVoteInProgress() || g_bVoteInProgress) {
		CPrintToChat(client, "%t", "other_vote");
		LogVoteAction(client, "[DENY] Reason: another vote is in progress.");
		return false;
	}
	
	if (HasOverrideAccess(client)) {
		LogVoteAction(client, "[FORCE-TELEPORTED]");
		if (g_iVoteCommand==1)
		{
			MakeTeleport();
		}
		if (g_iVoteCommand==2)
		{
			MakeGotoAhead();
		}
		if (g_iVoteCommand==3)
		{
			MakeGotoFriend();
		}
		return false;
	}
	
	if (!IsVoteAllowed(client))
	{
		CPrintToChatAll("%t", "no_access", client); // "%s tried to teleport noobs, but has no access."
		LogVoteAction(client, "[NO ACCESS]");
		return false;
	}
	
	if (g_hConVarPreventOnTanks.BoolValue && g_iTankCount)
	{
		CPrintToChatAll("%t", "no_access_tanks", client); // "%s can't vote for teleport, because there are tanks on the map"
		LogVoteAction(client, "[NO ACCESS-TANKS]");
		return false;
	}
	return true;
}

int GetSurvivorsCount() {
	int cnt;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) != 3) cnt++;
	return cnt;
}

bool IsVoteAllowed(int client)
{
	if (IsClientRootAdmin(client))
		return true;
	
	if (iLastTime[client] != 0)
	{
		if (iLastTime[client] + g_hCvarDelay.IntValue > GetTime()) {
			CPrintToChat(client, "%t", "too_often"); // "You can't vote too often!"
			LogVoteAction(client, "[DENY] Reason: too often.");
			return false;
		}
	}
	iLastTime[client] = GetTime();
	
	int iClients = GetSurvivorsCount();
	
	if (iClients < g_hMinPlayers.IntValue) {
		CPrintToChat(client, "%t", "not_enough_players", g_hMinPlayers.IntValue); // "Not enough players to start the vote. Required minimum: %i"
		LogVoteAction(client, "[DENY] Reason: Not enough players. Now: %i, required: %i.", iClients, g_hMinPlayers.IntValue);
		return false;
	}
	
	#if PRIVATE_STUFF
		static char sName[MAX_NAME_LENGTH];
		static char sSteam[64];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		
		if (StrEqual(sSteam, "STEAM_1:0:218709151")) { // by SteamID
			LogVoteAction(client, "[DENY] Reason: it's a XXX :).");
			CPrintToChat(client, "%t", "no_access", client);
			return false;
		}
		if (StrEqual(sSteam, "STEAM_1:1:246331117")) { // by SteamID - Demon
			LogVoteAction(client, "[DENY] Reason: it's a Demon :).");
			CPrintToChat(client, "%t", "no_access", client);
			return false;
		}
		if (StrEqual(sSteam, "STEAM_1:0:167549178")) { // by SteamID - Student
			LogVoteAction(client, "[DENY] Reason: it's a Student :).");
			CPrintToChat(client, "%t", "no_access", client);
			return false;
		}
		if (StrEqual(sSteam, "STEAM_1:0:1631844512")) { // by SteamID - KILLER
			LogVoteAction(client, "[DENY] Reason: it's a KILLER :).");
			CPrintToChat(client, "%t", "no_access", client);
			return false;
		}
		
		GetClientName(client, sName, sizeof(sName));
		
		if ( (StrContains(sName, "Ведьмак") != -1) || (StrContains(sName, "Beдьмaк") != -1) ) {
			LogVoteAction(client, "[DENY] Reason: he is a noob:");
			return false;
		}
	#endif
	
	if (!HasVoteAccess(client)) return false;
	
	return true;
}

void StartVoteTele(int client)
{
	Menu menu = new Menu(Handle_Votetele, MenuAction_DisplayItem | MenuAction_Display);
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	
	if (g_iVoteCommand==1)
	{
		LogVoteAction(client, "[STARTED] VOTETELE by");
		CPrintToChatAll("%t", "vote_started_tele", client); // %N is started vote for teleporting noobs
		PrintToServer("Vote for teleporting is started by: %N", client);
		PrintToConsoleAll("Vote for teleporting is started by: %N", client);
	
	}
	if (g_iVoteCommand==2)
	{
		LogVoteAction(client, "[STARTED] VOTEGOTOF by");
		CPrintToChatAll("%t", "vote_started_gotof", client);
		PrintToServer("Vote for teleporting is started by: %N", client);
		PrintToConsoleAll("Vote for teleporting is started by: %N", client);	
	}
	if (g_iVoteCommand==3)
	{
		LogVoteAction(client, "[STARTED] VOTEGOTOF by");
		CPrintToChatAll("%t", "vote_started_gotofriend", client);
		PrintToServer("Vote for teleporting is started by: %N", client);
		PrintToConsoleAll("Vote for teleporting is started by: %N", client);	
	}
	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	
	CreateTimer(g_hCvarAnnounceDelay.FloatValue, Timer_VoteDelayed, menu);
	
	if (g_iVoteCommand==1)
	{
		CPrintHintTextToAll("%t", "vote_started_tele_announce");
	}	
	if (g_iVoteCommand==2)
	{
		CPrintHintTextToAll("%t", "vote_started_gotof_announce");
	}	
	if (g_iVoteCommand==3)
	{
		CPrintHintTextToAll("%t", "vote_started_gotofriend_announce");
	}	
}

Action Timer_VoteDelayed(Handle timer, Menu menu)
{
	if (g_bVotepass || g_bVeto) {
		Handler_PostVoteAction(g_bVotepass);
		delete menu;
	}
	else {
		if (!IsVoteInProgress()) {
			g_bVoteInProgress = true;
			menu.DisplayVoteToAll(g_hCvarTimeout.IntValue);
			g_bVoteDisplayed = true;
		}
		else {
			delete menu;
		}
	}
}

public int Handle_Votetele(Menu menu, MenuAction action, int param1, int param2)
{
	static char display[64], buffer[255];

	switch (action)
	{
		case MenuAction_End: {
			if (g_bVoteInProgress && g_bVotepass) { // in case vote is passed with CancelVote(), so MenuAction_VoteEnd is not called.
				Handler_PostVoteAction(true);
			}
			g_bVoteInProgress = false;
			delete menu;
		}
		
		case MenuAction_VoteEnd: // 0=yes, 1=no
		{
			if ((param1 == 0 || g_bVotepass) && !g_bVeto) {
				Handler_PostVoteAction(true);
			}
			else {
				Handler_PostVoteAction(false);
			}
			g_bVoteInProgress = false;
		}
		case MenuAction_DisplayItem:
		{
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			Format(buffer, sizeof(buffer), "%T", display, param1);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			if (g_iVoteCommand==1)
			{
				Format(buffer, sizeof(buffer), "%T", "vote_started_tele_announce", param1); // "Do you want to teleport noobs?"
			}	
			if (g_iVoteCommand==2)
			{
				Format(buffer, sizeof(buffer), "%T", "vote_started_gotof_announce", param1); // "Do you want to teleport noobs?"
			}	
			if (g_iVoteCommand==3)
			{
				Format(buffer, sizeof(buffer), "%T", "vote_started_gotofriend_announce", param1); // "Do you want to teleport noobs?"
			}	
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void Handler_PostVoteAction(bool bVoteSuccess)
{
	if (bVoteSuccess) {
		if (g_iVoteCommand==1)
		{	
			MakeTeleport();
			LogVoteAction(0, "[TELEPORTED]");
		}
		if (g_iVoteCommand==2)
		{	
			MakeGotoAhead();
			LogVoteAction(0, "[GOTOF]");
		}
		if (g_iVoteCommand==3)
		{	
			MakeGotoFriend();
			LogVoteAction(0, "[GOTOF]");
		}
		CPrintToChatAll("%t", "vote_success");
	}
	else {
		LogVoteAction(0, "[NOT ACCEPTED]");
		CPrintToChatAll("%t", "vote_failed");
	}
	g_bVoteInProgress = false;
}

void MakeTeleport()
{
	GetClientAbsOrigin(g_iInitiator, g_fDestPos);
	float vPos[3], vDest[3];	
	for (int i = 1; i <= MaxClients; i++) {
		if (g_iInitiator != i && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, vPos);
			if (IsClientStuck(i) || GetVectorDistance(vPos, g_fDestPos) > g_hCvarMaxDist.FloatValue) {
				vDest[0] = g_fDestPos[0] + GetRandomFloat(0.0, 5.0);
				vDest[1] = g_fDestPos[1] + GetRandomFloat(0.0, 5.0);
				vDest[2] = g_fDestPos[2];
				TeleportEntity(i, vDest, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

void MakeGotoFriend()
{
	int client=g_iInitiator;
	float vPos[3], vDest[3];
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client)) {
		//Initialize
		GetClientAbsOrigin(client, vPos);
		GetClientAbsOrigin(g_iGotoFriend, g_fDestPos);		
		if (IsClientStuck(client) || GetVectorDistance(vPos, g_fDestPos) > g_hCvarMaxDist.FloatValue) {
			//Math
			vDest[0] = g_fDestPos[0] + GetRandomFloat(0.0, 5.0);
			vDest[1] = g_fDestPos[1] + GetRandomFloat(0.0, 5.0);
			vDest[2] = g_fDestPos[2];
			//Teleport
			TeleportEntity(client, vDest, NULL_VECTOR, NULL_VECTOR);
		}
	}	
}

void MakeGotoAhead()
{
	int client=g_iInitiator;
	float vPos[3], vDest[3];
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client)) {
		//Initialize
		GetClientAbsOrigin(client, vPos);
		GetClientAbsOrigin(GetAheadClient(), g_fDestPos);		
		if (IsClientStuck(client) || GetVectorDistance(vPos, g_fDestPos) > g_hCvarMaxDist.FloatValue) {
			//Math
			vDest[0] = g_fDestPos[0] + GetRandomFloat(0.0, 5.0);
			vDest[1] = g_fDestPos[1] + GetRandomFloat(0.0, 5.0);
			vDest[2] = g_fDestPos[2];
			//Teleport
			TeleportEntity(client, vDest, NULL_VECTOR, NULL_VECTOR);
		}
	}	
}

bool IsClientStuck(int iClient)
{
	float vMin[3], vMax[3], vOrigin[3];
	bool bHit;
	GetClientMins(iClient, vMin);
	GetClientMaxs(iClient, vMax);
	GetClientAbsOrigin(iClient, vOrigin);
	Handle hTrace = TR_TraceHullFilterEx(vOrigin, vOrigin, vMin, vMax, MASK_PLAYERSOLID, TraceRay_NoPlayers, iClient);
	if (hTrace != INVALID_HANDLE)
	{
		bHit = TR_DidHit(hTrace);
		CloseHandle(hTrace);
	}
	return bHit;
}

public bool TraceRay_NoPlayers(int entity, int mask, any data)
{
    if(entity == data || (entity >= 1 && entity <= MaxClients))
    {
        return false;
    }
    return true;
}

stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

bool HasVoteAccess(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if (iUserFlag & ADMFLAG_ROOT != 0) return true;
	
	char sReq[32];
	g_hCvarAccessFlag.GetString(sReq, sizeof(sReq));
	if (strlen(sReq) == 0) return true;
	
	int iReqFlags = ReadFlagString(sReq);
	return (iUserFlag & iReqFlags != 0);
}

bool HasOverrideAccess(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if (iUserFlag & ADMFLAG_ROOT != 0) return true;
	
	char sReq[32];
	g_hCvarOverrideFlag.GetString(sReq, sizeof(sReq));
	if (strlen(sReq) == 0) return false;
	
	int iReqFlags = ReadFlagString(sReq);
	return (iUserFlag & iReqFlags != 0);
}

void LogVoteAction(int client, const char[] format, any ...)
{
	if (!g_hCvarLog.BoolValue)
		return;
	
	static char sSteam[64];
	static char sIP[32];
	static char sCountry[4];
	static char sName[MAX_NAME_LENGTH];
	static char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	
	if (client != 0 && IsClientInGame(client)) {
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		GetClientName(client, sName, sizeof(sName));
		GetClientIP(client, sIP, sizeof(sIP));
		GeoipCode3(sIP, sCountry);
		LogToFile(g_sLog, "%s %s (%s | [%s] %s)", buffer, sName, sSteam, sCountry, sIP);
	}
	else {
		LogToFile(g_sLog, buffer);
	}
}

stock char[] Translate(int client, const char[] format, any ...)
{
	char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void CPrintHintTextToAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintHintText(i, buffer);
        }
    }
}


int GetAheadClient()
{	
	float flow;
	int count, countflow, index;
	// Get survivors flow distance
	ArrayList aList = new ArrayList(2);
	// Account for incapped
	int clients[MAXPLAYERS+1];
	int client=0;
	countflow=0;
	// Check valid survivors, count incapped
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			clients[count++] = i;
		}
	}

	for( int i = 0; i < count; i++ )
	{
		client = clients[i];
		// Ignore bot
		if(IsFakeClient(client))
			continue;
		flow = L4D2Direct_GetFlowDistance(client);
		if( flow && flow != -9999.0 ) // Invalid flows
		{
			countflow++;
			index = aList.Push(flow);
			aList.Set(index, client, 1);
		}
	}
	// Incase not enough players or some have invalid flow distance, we still need an average.
	if( countflow >= 1 )
	{
		aList.Sort(Sort_Descending, Sort_Float);
		client = aList.Get(0, 1);
	}
	delete aList;
	return client;
}