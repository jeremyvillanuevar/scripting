#define PLUGIN_VERSION "1.19"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PRIVATE_STUFF 1

const int MAX_MARK = 6;
const int MAX_CAMPAIGN_NAME = 64;
const int MAX_CAMPAIGN_TITLE = 128;
const int MAX_MAP_NAME = 64;
const int MAP_RATING_ANY = -1;
const int MAP_GROUP_ANY = -1;

#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] MapChanger",
	author = "Alex Dragokas",
	description = "Campaign and map chooser with rating system, groups and sorting",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
};

char g_sGameMode[32];
char g_sVoteResult[MAX_MAP_NAME];

KeyValues kv;
KeyValues kvinfo;

char mapInfoPath[PLATFORM_MAX_PATH];
char g_Campaign[MAXPLAYERS+1][MAX_CAMPAIGN_NAME];
char g_sCurMap[MAX_MAP_NAME];

int g_MapGroup[MAXPLAYERS+1];
int g_Rating[MAXPLAYERS+1];
int g_iVoteMark;

float g_fLastTime[MAXPLAYERS+1];

int iNumCampaignsGroup[3];
int iNumCampaignsCustom;

bool g_RatingMenu[MAXPLAYERS+1];
bool g_bLeft4Dead2;
bool g_bVeto;
bool g_bVotepass;
bool g_bVoteInProgress;
bool g_bVoteDisplayed;
bool g_bDedic;

StringMap g_hNameByMap;
StringMap g_hNameByMapCustom;
StringMap g_hCampaignByMap;
StringMap g_hCampaignByMapCustom;

ArrayList g_aMapOrder;
ArrayList g_aMapCustomOrder;

char g_sLog[PLATFORM_MAX_PATH];

ConVar g_hConVarGameMode;
ConVar g_hCvarDelay;
ConVar g_hCvarTimeout;
ConVar g_hCvarAnnounceDelay;
ConVar g_hCvarServerNameShort;
ConVar g_hCvarVoteMarkMinPlayers;
ConVar g_hCvarMapVoteAccessDef;
ConVar g_hCvarMapVoteAccessCustom;
ConVar g_ConVarHostName;
ConVar g_hCvarAllowDefault;
ConVar g_hCvarAllowCustom;

static Handle hDirectorChangeLevel;

#pragma unused g_bDedic

//Credit ProdigySim for l4d2_direct reading of TheDirector class https://forums.alliedmods.net/showthread.php?t=180028
static Address TheDirector = Address_Null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	if (test == Engine_Left4Dead2) g_bLeft4Dead2 = true;
	g_bDedic = IsDedicatedServer();
	return APLRes_Success;
}

bool CanVote(int client, bool bIsCustom)
{
	#if PRIVATE_STUFF
		static char sName[MAX_NAME_LENGTH];
		GetClientName(client, sName, sizeof(sName));
		if (StrContains(sName, "Ведьмак") != -1) return false;
		if (StrContains(sName, "Beдьмaк") != -1) return false;
	#endif

	int iUserFlag = GetUserFlagBits(client);
	if (iUserFlag & ADMFLAG_ROOT != 0) return true;
	
	static char sReq[32];
	if ( !bIsCustom )
	{
		g_hCvarMapVoteAccessDef.GetString(sReq, sizeof(sReq));
	}
	else {
		g_hCvarMapVoteAccessCustom.GetString(sReq, sizeof(sReq));
	}
	if ( sReq[0] == 0 ) return true;
	
	int iReqFlags = ReadFlagString(sReq);
	return (iUserFlag & iReqFlags != 0);
}

public void OnPluginStart()
{
	LoadTranslations("MapChanger.phrases");
	
	CreateConVar("mapchanger_version", PLUGIN_VERSION, "MapChanger Version", FCVAR_DONTRECORD | CVAR_FLAGS);
	g_hCvarDelay = CreateConVar(				"l4d_mapchanger_delay",					"60",		"Minimum delay (in sec.) allowed between votes", CVAR_FLAGS );
	g_hCvarTimeout = CreateConVar(				"l4d_mapchanger_timeout",				"10",		"How long (in sec.) does the vote last", CVAR_FLAGS );
	g_hCvarAnnounceDelay = CreateConVar(		"l4d_mapchanger_announcedelay",			"2.0",		"Delay (in sec.) between announce and vote menu appearing", CVAR_FLAGS );
	g_hCvarAllowDefault = CreateConVar(			"l4d_mapchanger_allow_default",			"1",		"Display default maps menu items? (1 - Yes, 0 - No)", CVAR_FLAGS );
	g_hCvarAllowCustom = CreateConVar(			"l4d_mapchanger_allow_custom",			"1",		"Display custom maps menu items? (1 - Yes, 0 - No)", CVAR_FLAGS );
	g_hCvarServerNameShort = CreateConVar(		"l4d_mapchanger_servername_short", 		"", 		"Short name of your server (specify it, if you want custom campaign name will be prepended to it)", CVAR_FLAGS);
	g_hCvarVoteMarkMinPlayers = CreateConVar(	"l4d_mapchanger_votemark_minplayers", 	"3", 		"Minimum number of players to allow starting the vote for mark", CVAR_FLAGS);
	g_hCvarMapVoteAccessDef = CreateConVar(		"l4d_mapchanger_default_voteaccess", 	"kp", 		"Flag allowed to access the vote for change to default maps", CVAR_FLAGS);
	g_hCvarMapVoteAccessCustom = CreateConVar(	"l4d_mapchanger_custom_voteaccess", 	"k", 		"Flag allowed to access the vote for change to custom maps", CVAR_FLAGS);
	
	//sm_cvar sv_vote_issue_change_map_later_allowed 0 
	//sm_cvar sv_vote_issue_change_map_now_allowed 0
	//sm_cvar sv_vote_issue_change_mission_allowed 0
	//sm_cvar sv_vote_issue_restart_game_allowed 0
	
	AutoExecConfig(true, "l4d_mapchanger"); 
	
	if( (g_hConVarGameMode = FindConVar("mp_gamemode")) == null )
		SetFailState("Failed to find convar handle 'mp_gamemode'. Cannot load plugin.");
	
	g_ConVarHostName = FindConVar("hostname");
	
	g_hConVarGameMode.AddChangeHook(ConVarChangedCallback);
	g_hConVarGameMode.GetString(g_sGameMode, sizeof(g_sGameMode));
	
	RegConsoleCmd("sm_maps", 		Command_MapChoose, 					"Show map list to begin vote for changelevel / set mark etc.");
	
	RegAdminCmd("sm_veto", 			Command_Veto, 		ADMFLAG_BAN, 	"Allow admin to veto current vote.");
	RegAdminCmd("sm_votepass", 		Command_Votepass, 	ADMFLAG_BAN, 	"Allow admin to bypass current vote.");
	RegAdminCmd("sm_maps_reload", 	Command_ReloadMaps, ADMFLAG_ROOT, 	"Refresh the list of maps");
	
	HookEvent("round_start", 			Event_RoundStart);
	HookEvent("finale_win", 			Event_FinaleWin, 		EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_leaving",	Event_VehicleLeaving,	EventHookMode_PostNoCopy);
	
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/vote_map.log");
	
	g_aMapOrder = new ArrayList(ByteCountToCells(MAX_MAP_NAME));
	g_aMapCustomOrder = new ArrayList(ByteCountToCells(MAX_MAP_NAME));
	
	if (!g_hNameByMap) {
		g_hNameByMap = new StringMap();
		g_hNameByMapCustom = new StringMap();
		g_hCampaignByMap = new StringMap();
		g_hCampaignByMapCustom = new StringMap();
		
		if (g_bLeft4Dead2) {
			AddMap("#L4D360UI_CampaignName_C1", "#L4D360UI_LevelName_COOP_C1M1", "c1m1_hotel");
			AddMap("#L4D360UI_CampaignName_C1", "#L4D360UI_LevelName_COOP_C1M2", "c1m2_streets");
			AddMap("#L4D360UI_CampaignName_C1", "#L4D360UI_LevelName_COOP_C1M3", "c1m3_mall");
			AddMap("#L4D360UI_CampaignName_C1", "#L4D360UI_LevelName_COOP_C1M4", "c1m4_atrium");
			AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M1", "c2m1_highway");
			AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M2", "c2m2_fairgrounds");
			AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M3", "c2m3_coaster");
			AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M4", "c2m4_barns");
			AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M5", "c2m5_concert");
			AddMap("#L4D360UI_CampaignName_C3", "#L4D360UI_LevelName_COOP_C3M1", "c3m1_plankcountry");
			AddMap("#L4D360UI_CampaignName_C3", "#L4D360UI_LevelName_COOP_C3M2", "c3m2_swamp");
			AddMap("#L4D360UI_CampaignName_C3", "#L4D360UI_LevelName_COOP_C3M3", "c3m3_shantytown");
			AddMap("#L4D360UI_CampaignName_C3", "#L4D360UI_LevelName_COOP_C3M4", "c3m4_plantation");
			AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M1", "c4m1_milltown_a");
			AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M2", "c4m2_sugarmill_a");
			AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M3", "c4m3_sugarmill_b");
			AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M4", "c4m4_milltown_b");
			AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M5", "c4m5_milltown_escape");
			AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M1", "c5m1_waterfront");
			AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M2", "c5m2_park");
			AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M3", "c5m3_cemetery");
			AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M4", "c5m4_quarter");
			AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M5", "c5m5_bridge");
			AddMap("#L4D360UI_CampaignName_C6", "#L4D360UI_LevelName_COOP_C6M1", "c6m1_riverbank");
			AddMap("#L4D360UI_CampaignName_C6", "#L4D360UI_LevelName_COOP_C6M2", "c6m2_bedlam");
			AddMap("#L4D360UI_CampaignName_C6", "#L4D360UI_LevelName_COOP_C6M3", "c6m3_port");
			AddMap("#L4D360UI_CampaignName_C7", "#L4D360UI_LevelName_COOP_C7M1", "c7m1_docks");
			AddMap("#L4D360UI_CampaignName_C7", "#L4D360UI_LevelName_COOP_C7M2", "c7m2_barge");
			AddMap("#L4D360UI_CampaignName_C7", "#L4D360UI_LevelName_COOP_C7M3", "c7m3_port");
			AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M1", "c8m1_apartment");
			AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M2", "c8m2_subway");
			AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M3", "c8m3_sewers");
			AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M4", "c8m4_interior");
			AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M5", "c8m5_rooftop");
			AddMap("#L4D360UI_CampaignName_C9", "#L4D360UI_LevelName_COOP_C9M1", "c9m1_alleys");
			AddMap("#L4D360UI_CampaignName_C9", "#L4D360UI_LevelName_COOP_C9M2", "c9m2_lots");
			AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M1", "c10m1_caves");
			AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M2", "c10m2_drainage");
			AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M3", "c10m3_ranchhouse");
			AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M4", "c10m4_mainstreet");
			AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M5", "c10m5_houseboat");
			AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M1", "c11m1_greenhouse");
			AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M2", "c11m2_offices");
			AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M3", "c11m3_garage");
			AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M4", "c11m4_terminal");
			AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M5", "c11m5_runway");
			AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M1", "C12m1_hilltop");
			AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M2", "C12m2_traintunnel");
			AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M3", "C12m3_bridge");
			AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M4", "C12m4_barn");
			AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M5", "C12m5_cornfield");
			AddMap("#L4D360UI_CampaignName_C13", "#L4D360UI_LevelName_COOP_C13M1", "c13m1_alpinecreek");
			AddMap("#L4D360UI_CampaignName_C13", "#L4D360UI_LevelName_COOP_C13M2", "c13m2_southpinestream");
			AddMap("#L4D360UI_CampaignName_C13", "#L4D360UI_LevelName_COOP_C13M3", "c13m3_memorialbridge");
			AddMap("#L4D360UI_CampaignName_C13", "#L4D360UI_LevelName_COOP_C13M4", "c13m4_cutthroatcreek");
			AddMap("#L4D360UI_CampaignName_C14", "#L4D360UI_LevelName_COOP_C14M1", "c14m1_junkyard");
			AddMap("#L4D360UI_CampaignName_C14", "#L4D360UI_LevelName_COOP_C14M2", "c14m2_lighthouse");
		}
		else {
			AddMap("No_Mercy", "#L4D360UI_Chapter_01_1", "l4d_hospital01_apartment");
			AddMap("No_Mercy", "#L4D360UI_Chapter_01_2", "l4d_hospital02_subway");
			AddMap("No_Mercy", "#L4D360UI_Chapter_01_3", "l4d_hospital03_sewers");
			AddMap("No_Mercy", "#L4D360UI_Chapter_01_4", "l4d_hospital04_interior");
			AddMap("No_Mercy", "#L4D360UI_Chapter_01_5", "l4d_hospital05_rooftop");
			AddMap("Crash_Course", "#L4D360UI_Chapter_02_1", "l4d_garage01_alleys");
			AddMap("Crash_Course", "#L4D360UI_Chapter_02_2", "l4d_garage02_lots");
			AddMap("Death_Toll", "#L4D360UI_Chapter_03_1", "l4d_smalltown01_caves");
			AddMap("Death_Toll", "#L4D360UI_Chapter_03_2", "l4d_smalltown02_drainage");
			AddMap("Death_Toll", "#L4D360UI_Chapter_03_3", "l4d_smalltown03_ranchhouse");
			AddMap("Death_Toll", "#L4D360UI_Chapter_03_4", "l4d_smalltown04_mainstreet");
			AddMap("Death_Toll", "#L4D360UI_Chapter_03_5", "l4d_smalltown05_houseboat");
			AddMap("Dead_Air", "#L4D360UI_Chapter_04_1", "l4d_airport01_greenhouse");
			AddMap("Dead_Air", "#L4D360UI_Chapter_04_2", "l4d_airport02_offices");
			AddMap("Dead_Air", "#L4D360UI_Chapter_04_3", "l4d_airport03_garage");
			AddMap("Dead_Air", "#L4D360UI_Chapter_04_4", "l4d_airport04_terminal");
			AddMap("Dead_Air", "#L4D360UI_Chapter_04_5", "l4d_airport05_runway");
			AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_1", "l4d_farm01_hilltop");
			AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_2", "l4d_farm02_traintunnel");
			AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_3", "l4d_farm03_bridge");
			AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_4", "l4d_farm04_barn");
			AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_5", "l4d_farm05_cornfield");
			AddMap("Sacrifice", "#L4D360UI_Chapter_06_1", "l4d_river01_docks");
			AddMap("Sacrifice", "#L4D360UI_Chapter_06_2", "l4d_river02_barge");
			AddMap("Sacrifice", "#L4D360UI_Chapter_06_3", "l4d_river03_port");
			//AddMap("Last_Stand", "#L4D360UI_Chapter_07_1", "l4d_sv_lighthouse");
		}
		Command_ReloadMaps(0, 0);
	}
	
	if ( g_bLeft4Dead2 )
	{
		PrepareSig();
	}
	
	RegAdminCmd("sm_mapnext", CmdNextMap, ADMFLAG_ROOT, "Force change level to the next map");
}

public Action CmdNextMap(int client, int args)
{
	FinaleMapChange();
	return Plugin_Handled;
}

void PrepareSig()
{
	Handle hGamedata = LoadGameConfigFile("l4d_mapchanger");
	if(hGamedata == null) 
		SetFailState("Failed to load \"l4d_mapchanger.txt\" gamedata.");
	
	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CDirector::OnChangeChapterVote"))
		SetFailState("Error finding the 'CDirector::OnChangeChapterVote' signature.");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	
	hDirectorChangeLevel = EndPrepSDKCall();
	if(hDirectorChangeLevel == null)
		SetFailState("Unable to prep SDKCall 'CDirector::OnChangeChapterVote'");
	
	TheDirector = GameConfGetAddress(hGamedata, "CDirector");
	if(TheDirector == Address_Null)
		SetFailState("Unable to get 'CDirector' Address");
	
	delete hGamedata;
}

void PrintMapToServer()
{
	PrintToServer("[MapChanger] Current map is: %s", g_sCurMap);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	PrintMapToServer();
}

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	//FinaleMapChange();
	//CreateTimer(12.0, Timer_FinaleMapChange, _, TIMER_FLAG_NO_MAPCHANGE); // just in case;
	PrintToServer("Event_FinaleWin");
}

public void Event_VehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	//CreateTimer(17.0, Timer_FinaleMapChange, _, TIMER_FLAG_NO_MAPCHANGE); // just in case;
	PrintToServer("Event_VehicleLeaving");
}

public void OnMapStart()
{
	GetCurrentMap(g_sCurMap, sizeof(g_sCurMap));
	PrintMapToServer();
	CreateTimer(5.0, Timer_ChangeHostName, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ChangeHostName(Handle timer)
{
	static char sSrv[64];
	static char sShort[48];
	char sCampaign[64], sCampaignTr[64];
	bool bCustom = false;
	
	if (g_hCampaignByMap.GetString(g_sCurMap, sCampaign, sizeof(sCampaign))) {
	}
	else {
		g_hCampaignByMapCustom.GetString(g_sCurMap, sCampaignTr, sizeof(sCampaignTr));
		bCustom = true;
	}
	
	g_hCvarServerNameShort.GetString(sShort, sizeof(sShort));
	if (sShort[0] == '\0')
		return;
	
	if (bCustom) {
		FormatEx (sSrv, sizeof(sSrv), "%s: [%s]", sShort, sCampaignTr);
	}
	else {
		strcopy(sSrv, sizeof(sSrv), sShort);
	}
	g_ConVarHostName.SetString(sSrv);
}

public void OnAllPluginsLoaded()
{
	AddCommandListener(CheckVote, "callvote");
}

public Action CheckVote(int client, char[] command, int args)
{
	static char s[32];
	if (args >= 2) {
		GetCmdArg(1, s, sizeof(s));
		if (strcmp(s, "ChangeMission", false) == 0) {
			Command_MapChoose(client, 0);
			return Plugin_Stop;
		}
	}
	if (args >= 1) {
		GetCmdArg(1, s, sizeof(s));
		if (strcmp(s, "RestartGame", false) == 0) {
			Command_MapChoose(client, 0);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public void ConVarChangedCallback (ConVar convar, const char[] oldValue, const char[] newValue)
{
	strcopy(g_sGameMode, sizeof(g_sGameMode), newValue);
	Actualize_MapChangerInfo();
}

void AddMap(char[] sCampaign, char[] sDisplay, char[] sMap)
{
	g_hNameByMap.SetString(sMap, sDisplay, false);
	g_hCampaignByMap.SetString(sMap, sCampaign, false);
	g_aMapOrder.PushString(sMap);
}

public Action Command_Veto(int client, int args)
{
	if ( g_bVoteInProgress ) { // IsVoteInProgress() is not working here, sm bug?
		g_bVeto = true;
		CPrintToChatAll("%t", "veto", client);
		if (g_bVoteDisplayed) CancelVote();
		LogVoteAction(client, "[VETO]");
	}
	return Plugin_Handled;
}

public Action Command_Votepass(int client, int args)
{
	if ( g_bVoteInProgress ) {
		g_bVotepass = true;
		CPrintToChatAll("%t", "votepass", client);
		if (g_bVoteDisplayed) CancelVote();
		LogVoteAction(client, "[PASS]");
	}
	return Plugin_Handled;
}

public Action Command_ReloadMaps(int client, int args)
{
	char mapListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, mapListPath, PLATFORM_MAX_PATH, "configs/%s", g_bLeft4Dead2 ? "MapChanger.l4d2.txt" : "MapChanger.l4d1.txt");
	
	if (!FileExists(mapListPath))
		SetFailState("[SM] ERROR: MapChanger - Missing file, '%s'", mapListPath);
	
	kv = new KeyValues("campaigns");
	if (!kv.ImportFromFile(mapListPath))
		SetFailState("[SM] ERROR: MapChanger - Incorrectly formatted file, '%s'", mapListPath);
	
	if (!kv.GotoFirstSubKey())
		SetFailState("[SM] ERROR: MapChanger - Config file is empty, '%s'", mapListPath);
	
	BuildPath(Path_SM, mapInfoPath, PLATFORM_MAX_PATH, "configs/MapChanger_info.txt");

	if (!FileExists(mapInfoPath))
		SetFailState("[SM] ERROR: MapChanger - Missing file, '%s'", mapInfoPath);
	
	kvinfo = new KeyValues("info");
	if (!kvinfo.ImportFromFile(mapInfoPath) || !kvinfo.JumpToKey("campaigns"))
		SetFailState("[SM] ERROR: MapChanger - Incorrectly formatted file, '%s'", mapInfoPath);
	
	Actualize_MapChangerInfo();
}

void Actualize_MapChangerInfo()
{
	kvinfo.Rewind();
	kvinfo.JumpToKey("campaigns");
	kvinfo.GotoFirstSubKey();
	
	kv.Rewind();
	kv.GotoFirstSubKey();
	
	static char sCampaign[MAX_CAMPAIGN_NAME], map[MAX_MAP_NAME], DisplayName[MAX_CAMPAIGN_TITLE];
	ArrayList Compaigns = new ArrayList(50, 50);
	bool fWrite = false;

	do
	{
		kvinfo.GetSectionName(sCampaign, sizeof(sCampaign)); // retrieve campaign names
		Compaigns.PushString(sCampaign);
	} while (kvinfo.GotoNextKey());
	
	int iGrp;
	static char sGrp[4];
	iNumCampaignsCustom = 0;
	for (int i = 0; i < sizeof(iNumCampaignsGroup); i++)
		iNumCampaignsGroup[i] = 0;
	
	g_aMapCustomOrder.Clear();
	
	do
	{
		kv.GetSectionName(sCampaign, sizeof(sCampaign)); // compare to full list

		kvinfo.GoBack();
		kvinfo.JumpToKey(sCampaign, true);
		
		if (-1 == Compaigns.FindString(sCampaign))
		{
			kvinfo.SetString("group", "0");
			kvinfo.SetString("mark", "0");
			iGrp = 0;
			fWrite = true;
		}
		else {
			kvinfo.GetString("group", sGrp, sizeof(sGrp), "0");
			iGrp = StringToInt(sGrp);
		}
		
		if (IsValidMapKv()) {
			FillCustomCampaignOrder();
			iNumCampaignsGroup[iGrp]++;
		}
		
	} while (kv.GotoNextKey());
	delete Compaigns;
	
	if (fWrite)
	{
		kvinfo.Rewind();
		kvinfo.ExportToFile(mapInfoPath);
	}
	
	for (int i = 0; i < sizeof(iNumCampaignsGroup); i++)
		iNumCampaignsCustom += iNumCampaignsGroup[i];
	
	// fill StringMaps
	kv.Rewind();
	kv.GotoFirstSubKey();
	do
	{
		kv.GetSectionName(sCampaign, sizeof(sCampaign));
		
		if( !kv.JumpToKey(g_sGameMode) )
		{
			if( !kv.JumpToKey("coop") ) // default
				continue;
		}
		
		if (kv.GotoFirstSubKey()) {
			do
			{
				kv.GetString("Map", map, sizeof(map), "error");
				if ( strcmp(map, "error") != 0 )
				{
					kv.GetString("DisplayName", DisplayName, sizeof(DisplayName), "error");
					if ( strcmp(DisplayName, "error") != 0 )
					{
						g_hNameByMapCustom.SetString(map, DisplayName, false);
						g_hCampaignByMapCustom.SetString(map, sCampaign, false);
					}
				}
			} while (kv.GotoNextKey());
			kv.GoBack();
		}
		kv.GoBack();
		
	} while (kv.GotoNextKey());
}

stock char[] Translate(int client, const char[] format, any ...)
{
	static char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

public Action Command_MapChoose(int client, int args)
{
	static char sDisplay[64], sDisplayTr[64], sCampaign[64], sCampaignTr[64];
	int iCurMapNumber, iTotalMapsNumber;
	bool bCustom = false;
	
	Menu menu = new Menu(Menu_MapTypeHandler, MENU_ACTIONS_DEFAULT);
	
	if (g_hCampaignByMap.GetString(g_sCurMap, sCampaign, sizeof(sCampaign)))
	{
		g_hNameByMap.GetString(g_sCurMap, sDisplay, sizeof(sDisplay));
		FormatEx(sCampaignTr, sizeof(sCampaignTr), "%T", sCampaign, client);
		FormatEx(sDisplayTr, sizeof(sDisplayTr), "%T", sDisplay, client);
	}
	else {
		g_hCampaignByMapCustom.GetString(g_sCurMap, sCampaignTr, sizeof(sCampaignTr));
		g_hNameByMapCustom.GetString(g_sCurMap, sDisplayTr, sizeof(sDisplayTr));
		GetMapNumber(sCampaignTr, g_sCurMap, iCurMapNumber, iTotalMapsNumber);
		bCustom = true;
	}
	
	if (bCustom) {
		menu.SetTitle( "%T: [%i/%i] %s - %s", "Current_map", client, iCurMapNumber, iTotalMapsNumber, sCampaignTr, sDisplayTr); // Current map: %s - %s
	}
	else {
		menu.SetTitle( "%T: %s - %s", "Current_map", client, sCampaignTr, sDisplayTr); // Current map: %s - %s
	}
	
	if ( g_hCvarAllowDefault.BoolValue )
	{
		menu.AddItem("default", Translate(client, "%t", "Default_maps")); 	// Стандартные карты
	}
	
	if ( g_hCvarAllowCustom.BoolValue )
	{
		if (iNumCampaignsGroup[1] != 0)
			menu.AddItem("group1", Translate(client, "%t", "Custom_maps_1")); 	// Доп. карты  << набор № 1 >>
			
		if (iNumCampaignsGroup[2] != 0)
			menu.AddItem("group2", Translate(client, "%t", "Custom_maps_2")); 	// Доп. карты  << набор № 2 >>
		
		if (iNumCampaignsGroup[0] != 0)
			menu.AddItem("group0", Translate(client, "%t", "Test_maps")); 		// Тестовые карты
		
		if (iNumCampaignsCustom != 0)
			menu.AddItem("rating", Translate(client, "%t", "By_rating")); 		// По рейтингу
	}
	menu.DisplayAt(client, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int Menu_MapTypeHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			static char sgroup[32];
			menu.GetItem(ItemIndex, sgroup, sizeof(sgroup));

			if ( strcmp(sgroup, "default") == 0 ) {
				g_MapGroup[client] = MAP_GROUP_ANY;
				g_Rating[client] = MAP_RATING_ANY;
				g_RatingMenu[client] = false;
				CreateDefcampaignMenu(client);
			}
			else if ( strcmp(sgroup, "rating") == 0 ) {
				g_MapGroup[client] = MAP_GROUP_ANY;
				g_RatingMenu[client] = true;
				CreateMenuRating(client);
			}
			else if ( strcmp(sgroup, "group0") == 0 ) {
				g_MapGroup[client] = 0;
				g_Rating[client] = MAP_RATING_ANY;
				g_RatingMenu[client] = false;
				CreateMenuCampaigns(client, 0, MAP_RATING_ANY);
			}
			else if ( strcmp(sgroup, "group1") == 0 ) {
				g_MapGroup[client] = 1;
				g_Rating[client] = MAP_RATING_ANY;
				g_RatingMenu[client] = false;
				CreateMenuCampaigns(client, 1, MAP_RATING_ANY);
			}
			else if ( strcmp(sgroup, "group2") == 0 ) {
				g_MapGroup[client] = 2;
				g_Rating[client] = MAP_RATING_ANY;
				g_RatingMenu[client] = false;
				CreateMenuCampaigns(client, 2, MAP_RATING_ANY);
			}
		}
	}
}

void CreateMenuRating(int client)
{
	Menu menu = new Menu(Menu_RatingHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "Rating_value_ask", client); 			// - Кампании с каким рейтингом показать? -
	menu.AddItem("1", Translate(client, "%t", "Rating_1")); 	// балл (отвратительная)
	menu.AddItem("2", Translate(client, "%t", "Rating_2")); 	// балла (не очень)
	menu.AddItem("3", Translate(client, "%t", "Rating_3")); 	// балла (средненькая)
	menu.AddItem("4", Translate(client, "%t", "Rating_4")); 	// балла (неплохая)
	menu.AddItem("5", Translate(client, "%t", "Rating_5")); 	// баллов (очень хорошая)
	menu.AddItem("6", Translate(client, "%t", "Rating_6")); 	// баллов (блестящая)
	menu.AddItem("0", Translate(client, "%t", "Rating_No")); 	// Ещё без оценки
	menu.ExitBackButton = true;
	menu.DisplayAt( client, 0, MENU_TIME_FOREVER);
}

public int Menu_RatingHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if (ItemIndex == MenuCancel_ExitBack)
				Command_MapChoose(client, 0);
		
		case MenuAction_Select:
		{
			static char sMark[8];
			menu.GetItem(ItemIndex, sMark, sizeof(sMark));
			int mark = StringToInt(sMark);
			
			g_Rating[client] = mark;
			CreateMenuCampaigns(client, MAP_GROUP_ANY, mark);
		}
	}
}

void CreateMenuCampaigns(int client, int ChosenGroup, int ChosenRating)
{
	static char BlackStar[] = "★";
	static char WhiteStar[] = "☆";
	
	Menu menu = new Menu(Menu_CampaignHandler, MENU_ACTIONS_DEFAULT);
	menu.ExitBackButton = true;

	static char Value[MAX_CAMPAIGN_NAME];
	FormatEx(Value, sizeof(Value), "%T", "Choose_campaign", client); // - Выберите кампанию -
	menu.SetTitle(Value);
	
	kv.Rewind();
	kv.GotoFirstSubKey();

	kvinfo.Rewind();
	kvinfo.JumpToKey("campaigns");
	
	static char campaign[MAX_CAMPAIGN_NAME];
	static char name[MAX_CAMPAIGN_TITLE];
	int group = 0, mark = 0;
	bool bAtLeastOne = false;
	do
	{
		kv.GetSectionName(campaign, sizeof(campaign));

		if (kvinfo.JumpToKey(campaign))
		{
			group = kvinfo.GetNum("group", 0);
			mark = kvinfo.GetNum("mark", 0);
			kvinfo.GoBack();
		}
		if ((ChosenGroup == -1 || group == ChosenGroup) && (ChosenRating == -1 || mark == ChosenRating))
		{
			if (IsValidMapKv()) {
				FormatEx(name, sizeof(name), "%s%s   %s", StrRepeat(BlackStar, strlen(BlackStar), mark), StrRepeat(WhiteStar, strlen(WhiteStar), MAX_MARK - mark), campaign);
				menu.AddItem(campaign, name);
				bAtLeastOne = true;
			}
		}
	} while (kv.GotoNextKey());
	
	if (bAtLeastOne)
	{
		menu.DisplayAt(client, 0, MENU_TIME_FOREVER);
	} 
	else {
		if (g_RatingMenu[client])
		{
			FormatEx(Value, sizeof(Value), "%T", "No_maps_rating", client); // Карт с такой оценкой ещё нет.
			PrintToChat(client, "\x03[MapChanger] \x05%s", Value);
			CreateMenuRating(client);
		} else {
			FormatEx(Value, sizeof(Value), "%T", "No_maps_in_group", client); // В этой группе ещё нет карт.
			PrintToChat(client, "\x03[MapChanger] \x05%s", Value);
			Command_MapChoose(client, 0);
		}
	}
}

// in. - KeyValue in position of concrete campaign section
bool IsValidMapKv()
{
	char map[MAX_MAP_NAME];
	bool bValid = false;

	// get the first map of campaign to check is it exist
	if (!kv.JumpToKey(g_sGameMode))
	{
		if (!kv.JumpToKey("coop")) // default
			return false;
	}
	if (kv.GotoFirstSubKey()) {
		kv.GetString("Map", map, sizeof(map), "error");
		if ( strcmp(map, "error") != 0 )
		{
			if ( IsMapValidEx(map) )
				bValid = true;
		}
		kv.GoBack();
	}
	kv.GoBack();
	return bValid;
}

void FillCustomCampaignOrder()
{
	char map[MAX_MAP_NAME];

	// get the first map of campaign to check is it exist
	if (!kv.JumpToKey(g_sGameMode))
	{
		if (!kv.JumpToKey("coop")) // default
			return;
	}
	if (kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetString("Map", map, sizeof(map), "error");
			if ( strcmp(map, "error") != 0 )
			{
				if ( IsMapValidEx(map) )
				{
					g_aMapCustomOrder.PushString(map);
				}
			}
		} while (kv.GotoNextKey());
		kv.GoBack();
	}
	kv.GoBack();
}

char[] StrRepeat(char[] text, int maxlength, int times)
{
	char NewStr[MAX_CAMPAIGN_TITLE];

//	char[] NewStr = new char[times*maxlength];

	for (int i = 0; i < times*maxlength; i+=maxlength)
		for (int j = 0; j < maxlength; j++) {
			NewStr[i + j] = text[j];
		}
	if (times < 0)
		NewStr[0] = '\0';
	else
		NewStr[times*maxlength] = '\0';
	return NewStr;
}

void CreateDefcampaignMenu(int client)
{
	Menu menu = new Menu(Menu_DefCampaignHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "Choose_campaign", client); // - Выберите кампанию -
	
	// extract uniq. campaign names
	ArrayList aUniq = new ArrayList(ByteCountToCells(64));
	StringMapSnapshot hSnap = g_hCampaignByMap.Snapshot();
	static char sMap[64], sCampaign[64], sCampaignTr[64];
	
	for (int i = 0; i < hSnap.Length; i++) 
	{
		hSnap.GetKey(i, sMap, sizeof(sMap));
		g_hCampaignByMap.GetString(sMap, sCampaign, sizeof(sCampaign));
		if (aUniq.FindString(sCampaign) == -1) {
			aUniq.PushString(sCampaign);
			FormatEx(sCampaignTr, sizeof(sCampaignTr), "%T", sCampaign, client);
			menu.AddItem(sCampaign, sCampaignTr, ITEMDRAW_DEFAULT);
		}
	}
	delete hSnap;
	delete aUniq;
	menu.ExitBackButton = true;
	menu.DisplayAt(client, 0, MENU_TIME_FOREVER);
}


public int Menu_DefCampaignHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if (ItemIndex == MenuCancel_ExitBack)
				Command_MapChoose(client, 0);
		
		case MenuAction_Select:
		{
			static char campaign[MAX_CAMPAIGN_NAME];
			static char campaign_title[MAX_CAMPAIGN_TITLE];
			menu.GetItem(ItemIndex, campaign, sizeof(campaign), _, campaign_title, sizeof(campaign_title));
			
			CreateDefmapMenu(client, campaign, campaign_title);
		}
	}
}

void CreateDefmapMenu(int client, char[] campaign, char[] campaign_title)
{
	Menu menu = new Menu(Menu_DefMapHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("- %T [%s] -", "Choose_map", client, campaign_title);  // Выберите карту
	
	// extract all campaign maps
	StringMapSnapshot hSnap = g_hCampaignByMap.Snapshot();
	static char sMap[64], sCampaign[64], sDisplay[64], sDisplayTr[64];
	
	char[][] sOrder = new char[hSnap.Length][64];
	int arrSize = 0;
	
	for (int i = 0; i < hSnap.Length; i++)
	{
		hSnap.GetKey(i, sMap, sizeof(sMap));
		
		g_hCampaignByMap.GetString(sMap, sCampaign, sizeof(sCampaign));
		
		if ( strcmp(sCampaign, campaign) == 0 )
		{
			g_hNameByMap.GetString(sMap, sDisplay, sizeof(sDisplay));
			strcopy(sOrder[arrSize], 64, sDisplay);
			arrSize++;
		}
	}
	delete hSnap;
	
	// StringMap snapshot order is sorted by hash, so I need to put this shit
	SortStrings(sOrder, arrSize, Sort_Ascending);

	hSnap = g_hNameByMap.Snapshot();
	
	for (int i = 0; i < arrSize; i++) 
	{
		for (int j = 0; j < hSnap.Length; j++) 
		{
			hSnap.GetKey(j, sMap, sizeof(sMap));
			g_hNameByMap.GetString(sMap, sDisplay, sizeof(sDisplay));
			
			if ( strcmp(sOrder[i], sDisplay) == 0 )
			{
				FormatEx(sDisplayTr, sizeof(sDisplayTr), "%T", sDisplay, client);
				menu.AddItem(sMap, sDisplayTr);
			}
		}
	}
	delete hSnap;
	
	menu.ExitBackButton = true;
	menu.DisplayAt(client, 0, MENU_TIME_FOREVER);
}

public int Menu_DefMapHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if (ItemIndex == MenuCancel_ExitBack)
				CreateDefcampaignMenu(client);
		
		case MenuAction_Select:
		{
			static char map[MAX_MAP_NAME];
			menu.GetItem(ItemIndex, map, sizeof(map));
			CheckVoteMap(client, map, false);
		}
	}
}

/*
public void OnConfigsExecuted() // after server.cfg !
{
	// set survival mode for "The Last Stand"
	if (StrEqual(g_sCurMap, "l4d_sv_lighthouse"))
	{
		g_GameMode.SetString("survival");
	}
}
*/

void CreateMenuGroup(int client)
{
	Menu menu = new Menu(Menu_GroupHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle( "- %T [%s] ? -", "choose_new_map_type", client, g_Campaign[client]); // Какой тип присвоить
	menu.AddItem("1", Translate(client, "%t", "new_type_1")); // Тип: < набор № 1 >
	menu.AddItem("2", Translate(client, "%t", "new_type_2")); // Тип: < набор № 2 >
	menu.AddItem("0", Translate(client, "%t", "new_type_test")); // Тип: < тестовая карта >
	menu.ExitBackButton = true;
	menu.DisplayAt( client, 0, MENU_TIME_FOREVER);
}

public int Menu_GroupHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if (ItemIndex == MenuCancel_ExitBack)
				CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
		
		case MenuAction_Select:
		{
			static char sGroup[8];
			menu.GetItem(ItemIndex, sGroup, sizeof(sGroup));
			int group = StringToInt(sGroup);
			
			kvinfo.Rewind();
			kvinfo.JumpToKey("campaigns");
			kvinfo.JumpToKey(g_Campaign[client], true);
			kvinfo.SetNum("group", group);
			kvinfo.Rewind();
			kvinfo.ExportToFile(mapInfoPath);
			CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
		}
	}
}

void CreateMenuMark(int client)
{
	Menu menu = new Menu(Menu_MarkHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle( "- %T [%s] -", "set_rating", client, g_Campaign[client]); // Поставьте оценку кампании
	menu.AddItem("1", Translate(client, "%t", "Rating_1")); // балл (отвратительная)
	menu.AddItem("2", Translate(client, "%t", "Rating_2")); // балла (не очень)
	menu.AddItem("3", Translate(client, "%t", "Rating_3")); // балла (средненькая)
	menu.AddItem("4", Translate(client, "%t", "Rating_4")); // балла (неплохая)
	menu.AddItem("5", Translate(client, "%t", "Rating_5")); // баллов (очень хорошая)
	menu.AddItem("6", Translate(client, "%t", "Rating_6")); // баллов (блестящая)
	if (IsClientRootAdmin(client))
		menu.AddItem("0", Translate(client, "%t", "Rating_remove")); // Удалить рейтинг
	menu.ExitBackButton = true;
	menu.DisplayAt( client, 0, MENU_TIME_FOREVER);
}

public int Menu_MarkHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if (ItemIndex == MenuCancel_ExitBack)
				CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
		
		case MenuAction_Select:
		{
			static char sMark[8];
			menu.GetItem(ItemIndex, sMark, sizeof(sMark));
			g_iVoteMark = StringToInt(sMark);
			
			if (g_iVoteMark == 0) {
				SetRating(g_Campaign[client], 0); // Remove rating is intended for admin only
				CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
			}
			else {
				if (IsClientRootAdmin(client)) {
					StartVoteMark(client, g_Campaign[client]);
				}
				else {
					PrintToChat(client, "\04%t", "no_access");
				}
			}
		}
	}
}

public int Menu_CampaignHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if (ItemIndex == MenuCancel_ExitBack)
				if (g_RatingMenu[client])
					CreateMenuRating(client);
				else
					Command_MapChoose(client, 0);
		
		case MenuAction_Select:
		{
			static char campaign[MAX_CAMPAIGN_NAME];
			menu.GetItem(ItemIndex, campaign, sizeof(campaign));
			strcopy(g_Campaign[client], sizeof(g_Campaign[]), campaign);
			CreateCutomMapMenu(client, campaign);
		}
	}
}

void CreateCutomMapMenu(int client, char[] campaign)
{
	kv.Rewind();
	if (kv.JumpToKey(campaign))
	{
		if (!kv.JumpToKey(g_sGameMode))
		{
			if (!kv.JumpToKey("coop")) { // default
				PrintToChat(client, "\x03[MapChanger] %T %s!", "no_maps_for_mode", client, g_sGameMode); // Не найдено карт в кофигурации для режима
				return;
			}
		}
		
		Menu menu2 = new Menu(Menu_MapHandler, MENU_ACTIONS_DEFAULT);
		menu2.SetTitle("- %T [%s] -", "Choose_map", client, campaign);  // Выберите карту

		char map[MAX_MAP_NAME];
		char DisplayName[MAX_CAMPAIGN_TITLE];
		
		kv.GotoFirstSubKey();
		do
		{
			kv.GetString("Map", map, sizeof(map), "error");
			if ( strcmp(map, "error") != 0 )
			{
				kv.GetString("DisplayName", DisplayName, sizeof(DisplayName), "error");
				if ( strcmp(DisplayName, "error") != 0 )
				{
					menu2.AddItem(map, DisplayName, ITEMDRAW_DEFAULT);
				}
			}
		} while (kv.GotoNextKey());
		
		if (IsClientRootAdmin(client)) {
			menu2.AddItem("group", Translate(client, "%t", "Move_map_type"));  // Переместить в другую группу
		}
		menu2.AddItem("mark", Translate(client, "%t", "set_rating2"));  // Поставить оценку
		menu2.ExitBackButton = true;
		menu2.DisplayAt(client, 0, MENU_TIME_FOREVER);
	}
}

void GetMapNumber(const char[] campaign, const char[] sMap, int &iCurNumber, int &iTotalNumber)
{
	static char map[MAX_MAP_NAME];
	iTotalNumber = 0;
 	kv.Rewind();
	if (kv.JumpToKey(campaign))
	{
		if (!kv.JumpToKey(g_sGameMode))
		{
			if (!kv.JumpToKey("coop")) { // default
				return;
			}
		}
		kv.GotoFirstSubKey();
		do
		{
			kv.GetString("Map", map, sizeof(map), "error");
			if ( strcmp(map, "error") != 0 )
			{
				iTotalNumber++;
				
				if ( strcmp(map, sMap) == 0 )
				{
					iCurNumber = iTotalNumber;
				}
			}
		} while (kv.GotoNextKey());
	}
}

int GetRealClientCount() {
	int cnt;
	//for (int i = g_bDedic ? 1 : 0; i <= MaxClients; i++)
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i)) cnt++;
	return cnt;
}

public int Menu_MapHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if (ItemIndex == MenuCancel_ExitBack)
				CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
		
		case MenuAction_Select:
		{
			static char map[MAX_MAP_NAME];
			static char DisplayName[MAX_CAMPAIGN_TITLE];
			menu.GetItem(ItemIndex, map, sizeof(map), _, DisplayName, sizeof(DisplayName));

			if ( strcmp(map, "mark") == 0 )
			{
				if ( GetRealClientCount() >= g_hCvarVoteMarkMinPlayers.IntValue || IsClientRootAdmin(client) ) 
				{
					CreateMenuMark(client);
				}
				else {
					PrintToChat(client, "%t", "Not_enough_votemark_players", g_hCvarVoteMarkMinPlayers.IntValue); // Not enough clients to start vote for mark (should be %i+)
					CreateCutomMapMenu(client, g_Campaign[client]);
				}
			}
			else if ( strcmp(map, "group") == 0 )
			{
				CreateMenuGroup(client);
			} 
			else {
				LogVoteAction(client, "[TRY] Change map to: %s from %s", map, g_sCurMap);
				CheckVoteMap(client, map, true);
			}
		}
	}
}

void CheckVoteMap(int client, char[] map, bool bIsCustom)
{
	if ( IsMapValidEx(map) )
	{
		if ( IsClientRootAdmin(client) && GetRealClientCount() == 1 )
		{
			strcopy(g_sVoteResult, sizeof(g_sVoteResult), map);
			Handler_PostVoteAction(true);
			return;
		}
	
		if ( CanVote(client, bIsCustom) )
		{
			float fCurTime = GetEngineTime();
		
			if ( g_fLastTime[client] != 0 && !IsClientRootAdmin(client) )
			{
				if ( g_fLastTime[client] + g_hCvarDelay.FloatValue > fCurTime ) {
					PrintToChat(client, "\x03[MapChanger] %t", "too_often"); // "You can't vote too often!"
					LogVoteAction(client, "[DELAY] Attempt to vote too often. Time left: %i sec.", (g_fLastTime[client] + g_hCvarDelay.FloatValue) - fCurTime);
					return;
				}
			}
			g_fLastTime[client] = fCurTime;
			
			StartVoteMap(client, map);
		}
		else {
			PrintToChat(client, "\x04No access!");
			LogVoteAction(client, "[DENY] Change map");
		}
	} else {
		//if (client != 0 || !g_bDedic) {
		if ( client ) {
			PrintToChat(client, "\x03[MapChanger] %t %s %t", "map", map, "not_exist");  // Карта XXX больше не существует на сервере!
		}
		LogVoteAction(client, "[DENY] Map is not exist.");
	}
}

void StartVoteMap(int client, char[] sMap)
{
	if ( g_bVoteInProgress || IsVoteInProgress() ) {
		PrintToChat(client, "%t", "vote_in_progress"); // Другое голосование ещё не закончилось!
		return;
	}
	strcopy(g_sVoteResult, sizeof(g_sVoteResult), sMap);
	
	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	LogVoteAction(client, "[STARTED] Change map to: %s", sMap);
	
	Menu menu = new Menu(Handle_VoteMapMenu, MenuAction_DisplayItem | MenuAction_Display);
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	CreateTimer(g_hCvarAnnounceDelay.FloatValue, Timer_VoteDelayed, menu, TIMER_FLAG_NO_MAPCHANGE);
	CPrintHintTextToAll("%t", "vote_started_announce", g_sVoteResult);
}

Action Timer_VoteDelayed(Handle timer, Menu menu)
{
	if (g_bVotepass || g_bVeto) {
		Handler_PostVoteAction(g_bVotepass);
		delete menu;
	}
	else {
		if ( !IsVoteInProgress() ) {
			g_bVoteInProgress = true;
			menu.DisplayVoteToAll(g_hCvarTimeout.IntValue);
			g_bVoteDisplayed = true;
		}
		else {
			delete menu;
		}
	}
}

public int Handle_VoteMapMenu(Menu menu, MenuAction action, int param1, int param2)
{
	static char display[MAX_CAMPAIGN_NAME], buffer[MAX_CAMPAIGN_NAME];
	int client = param1;

	switch (action)
	{
		case MenuAction_End:
		{
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
			FormatEx(buffer, sizeof(buffer), "%T", display, client);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			FormatEx(buffer, sizeof(buffer), "%T", "vote_started_announce", client, g_sVoteResult);
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void Handler_PostVoteAction(bool bVoteSuccess)
{
	if (bVoteSuccess)
	{
		LogVoteAction(-1, "[ACCEPTED] Vote for map: %s", g_sVoteResult);
		CPrintToChatAll("%t", "vote_success");
		
		L4D_ChangeLevel(g_sVoteResult);
	}
	else {
		LogVoteAction(-1, "[NOT ACCEPTED] Vote for map.");
		CPrintToChatAll("%t", "vote_failed");
	}
	g_bVoteInProgress = false;
}

void StartVoteMark(int client, char[] sCampaign)
{
	if ( g_bVoteInProgress || IsVoteInProgress() ) {
		PrintToChat(client, "%t", "vote_in_progress"); // Другое голосование ещё не закончилось!
		return;
	}
	Menu menu = new Menu(Handle_VoteMarkMenu, MenuAction_DisplayItem | MenuAction_Display);
	menu.AddItem(sCampaign, "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(g_hCvarTimeout.IntValue);
	g_bVotepass = false;
	g_bVeto = false;
	LogVoteAction(client, "[STARTED] Vote for mark. Campaign: %s. Mark: %i", sCampaign, g_iVoteMark);
}

public int Handle_VoteMarkMenu(Menu menu, MenuAction action, int param1, int param2)
{
	static char display[MAX_CAMPAIGN_NAME], buffer[128], sCampaign[MAX_CAMPAIGN_NAME], sRate[32];
	int client = param1;
	
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_VoteEnd: // 0=yes, 1=no
		{
			if ((param1 == 0 || g_bVotepass) && !g_bVeto) {
				menu.GetItem(0, sCampaign, sizeof(sCampaign));
				SetRating(sCampaign, g_iVoteMark);
				LogVoteAction(-1, "[ACCEPTED] Vote for mark.");
			}
			else {
				LogVoteAction(-1, "[NOT ACCEPTED] Vote for mark.");
			}
		}
		case MenuAction_DisplayItem:
		{
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			FormatEx(buffer, sizeof(buffer), "%T", display, client);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			menu.GetItem(0, sCampaign, sizeof(sCampaign));
			FormatEx(sRate, sizeof(sRate), "Rating_%i", g_iVoteMark);
			FormatEx(buffer, sizeof(buffer), "%T", "set_mark_vote_title", client, g_iVoteMark, sRate, client, sCampaign); // "Set mark %i (%t) for the map: %s ?"
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void SetRating(char[] sCampaign, int iMark)
{
	kvinfo.Rewind();
	kvinfo.JumpToKey("campaigns");
	kvinfo.JumpToKey(sCampaign, true);
	kvinfo.SetNum("mark", iMark);
	kvinfo.Rewind();
	kvinfo.ExportToFile(mapInfoPath);
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
	static char buffer[192];
	SetGlobalTransTarget(iClient);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));
	PrintToChat(iClient, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
	static char buffer[192];
	//for( int i = g_bDedic ? 1 : 0; i <= MaxClients; i++ )
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
	//for( int i = g_bDedic ? 1 : 0; i <= MaxClients; i++ )
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

stock bool IsClientAdmin(int client)
{
	if (!IsClientInGame(client)) return false;
	return (GetUserAdmin(client) != INVALID_ADMIN_ID && GetUserFlagBits(client) != 0);
}
stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

void LogVoteAction(int client, const char[] format, any ...)
{
	static char sSteam[64];
	static char sIP[32];
	static char sName[MAX_NAME_LENGTH];
	static char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	
	if (client != -1) {
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		GetClientName(client, sName, sizeof(sName));
		GetClientIP(client, sIP, sizeof(sIP));
		LogToFileEx(g_sLog, "%s %s (%s | %s). Current map is: %s", buffer, sName, sSteam, sIP, g_sCurMap);
	}
	else {
		LogToFileEx(g_sLog, buffer);
	}	
}

void L4D_ChangeLevel(const char[] sMapName) // Thanks to Lux
{
	DataPack dp = new DataPack();
	dp.WriteString(sMapName);

	CreateTimer(2.0, Timer_AlternateChangeMap, dp, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
	
	if ( g_bLeft4Dead2 )
	{
		if( hDirectorChangeLevel != null )
		{
			SDKCall(hDirectorChangeLevel, TheDirector, sMapName);
		}
		else {
			ForceChangeLevel(sMapName, "Map Vote");
		}
	}
	else {
		ForceChangeLevel(sMapName, "Map Vote");
	}
}

public Action Timer_AlternateChangeMap(Handle timer, DataPack dp)
{
	static char g_sNewMap[MAX_MAP_NAME];
	
	dp.Reset();
	dp.ReadString(g_sNewMap, sizeof g_sNewMap);
	
	ServerCommand("changelevel %s", g_sNewMap);
	ServerExecute();
}

public Action Timer_FinaleMapChange(Handle timer)
{
	FinaleMapChange();
}

void FinaleMapChange()
{
	static char g_sNewMap[MAX_MAP_NAME];
	
	int idx = g_aMapOrder.FindString(g_sCurMap); // search default maps

	if( idx != -1 ) 
	{
		idx++;
		if( idx >= g_aMapOrder.Length )
		{
			idx = 0;
		}
		g_aMapOrder.GetString(idx, g_sNewMap, sizeof g_sNewMap);
	}
	else {
		idx = g_aMapCustomOrder.FindString(g_sCurMap); // search custom maps
		
		if( idx != -1 )
		{
			idx++;
			if( idx >= g_aMapOrder.Length )
			{
				idx = 0;
			}
			g_aMapCustomOrder.GetString(idx, g_sNewMap, sizeof g_sNewMap);
		}
		else {
			g_aMapOrder.GetString(0, g_sNewMap, sizeof g_sNewMap);
		}
	}
	
	L4D_ChangeLevel(g_sNewMap);
}

bool IsMapValidEx(char[] map)
{
	static char path[PLATFORM_MAX_PATH];
	return FindMap(map, path, sizeof(path)) == FindMap_Found;
}