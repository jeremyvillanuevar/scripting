#include <sourcemod>
#include <sdktools>
#include <regex>

#undef REQUIRE_PLUGIN
#include <sourcebanspp>

#pragma semicolon 1
#pragma newdecls required

// Global variables
Regex regex;
Regex regexip;

ConVar gc_bChatFilters;
ConVar gc_bChatIpFilters;
ConVar gc_bChatSymbols;
ConVar gc_bHideNamechange;
ConVar gc_bHideCommands;
ConVar gc_iChatPunishment;
ConVar gc_iBanDuration;
ConVar gc_iBanMethod;

ConVar gc_bNameFilters;
ConVar gc_bNameIpFilters;
ConVar gc_bNameSymbols;
ConVar gc_bNameTooShort;
ConVar gc_sReplacement;
ConVar gc_bWhitelist;

char chatfilters[360][50];
char namefilters[360][50];
char allowedips[20][20];

char chatfile[PLATFORM_MAX_PATH];
char namefile[PLATFORM_MAX_PATH];
char whitelistfile[PLATFORM_MAX_PATH];
char logfile[PLATFORM_MAX_PATH];

bool Sourcebans = false;

// Plugin Info
public Plugin myinfo = 
{
	name = "Simple Filters",
	author = "FAQU",
	version = "1.0.6",
	description = "Name and chat filtering"
};

// Plugin Initialization
public void OnPluginStart()
{
	regex = CompileRegex("[^\\w \\-\\/!@#$%^&*()+=,.<>\"':;?[\\]]+", PCRE_UTF8);
	regexip = CompileRegex("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}");
	
	if (!regex)
	{
		SetFailState("Invalid regex pattern - Handle: regex");
	}
	else if (!regexip)
	{
		SetFailState("Invalid regex pattern - Handle: regexip");
	}
	
	BuildPath(Path_SM, chatfile, sizeof(chatfile), "configs/simple-chatfilters.txt");
	BuildPath(Path_SM, namefile, sizeof(namefile), "configs/simple-namefilters.txt");
	BuildPath(Path_SM, whitelistfile, sizeof(whitelistfile), "configs/simple-ipwhitelist.txt");
	BuildPath(Path_SM, logfile, sizeof(logfile), "logs/simple-filters.log");
	
	gc_bChatFilters = CreateConVar("simple_chat_filters", "1", "Enable the usage of chat filters (0 = Disabled / 1 = Enabled)");
	gc_bChatIpFilters = CreateConVar("simple_chat_ipfilters", "1", "Enable the usage of chat IP filters (0 = Disabled / 1 = Enabled)");
	gc_bChatSymbols = CreateConVar("simple_chat_blocksymbols", "1", "Block chat messages if they contain symbols/custom fonts (0 = Disabled / 1 = Enabled)");
	gc_bHideNamechange = CreateConVar("simple_chat_hidenamechange", "1", "Hide 'player changed name' messages from chat (0 = Disabled / 1 = Enabled)");
	gc_bHideCommands = CreateConVar("simple_chat_hidecommands", "1", "Hide chat commands - ex. !admin (0 = Disabled / 1 = Enabled)");
	gc_iChatPunishment = CreateConVar("simple_chat_punishment", "0", "How to punish the player if message contains bad word / IP address (0 = Block message / 1 = Kick player / 2 = Ban Player)");
	gc_iBanDuration = CreateConVar("simple_chat_banduration", "1440", "Ban duration in minutes (0 = permanent)");
	gc_iBanMethod = CreateConVar("simple_chat_banmethod", "0", "Method of banning player (0 = SteamID only / 1 = IP only / 2 = SteamID + IP)");
	
	gc_bNameFilters = CreateConVar("simple_name_filters", "1", "Enable the usage of name filters (0 = Disabled / 1 = Enabled)");
	gc_bNameIpFilters = CreateConVar("simple_name_ipfilters", "1", "Enable the usage of name IP filters (0 = Disabled / 1 = Enabled)");
	gc_bNameSymbols = CreateConVar("simple_name_removesymbols", "1", "Remove symbols/custom fonts from player's name (0 = Disabled / 1 = Enabled)");
	gc_bNameTooShort = CreateConVar("simple_name_tooshort", "1", "Rename players into 'Player #userid' if their name has less than 3 characters (0 = Disabled / 1 = Enabled)");
	gc_sReplacement = CreateConVar("simple_name_replacement", "", "Replacement word for name filters (Empty = just remove bad words/IPs)");
	
	gc_bWhitelist = CreateConVar("simple_whitelist", "0", "Enable the usage of global IP whitelist (0 = Disabled / 1 = Enabled)");
	AutoExecConfig(true, "Simple-Filters");
	
	HookEvent("player_changename", Event_PlayerChangename);
	HookUserMessage(GetUserMessageId("SayText2"), Hook_SayText2, true);
	
	RegAdminCmd("sm_chatfilters", Command_Chatfilters, ADMFLAG_ROOT, "Prints a list of currently loaded chat filters");
	RegAdminCmd("sm_namefilters", Command_Namefilters, ADMFLAG_ROOT, "Prints a list of currently loaded name filters");
	RegAdminCmd("sm_whitelist", Command_Whitelist, ADMFLAG_ROOT, "Prints a list of currently whitelisted IPs");
	RegAdminCmd("sm_reloadfilters", Command_Reloadfilters, ADMFLAG_ROOT, "Reloads chat and name filters");
}

// Checking if Sourcebans++ is available
public void OnAllPluginsLoaded()
{
	Sourcebans = LibraryExists("sourcebans++");
}

public void OnLibraryAdded(const char[] library)
{
	if (StrEqual(library, "sourcebans++"))
	{
		Sourcebans = true;
	}
}

public void OnLibraryRemoved(const char[] library)
{
	if (StrEqual(library, "sourcebans++"))
	{
		Sourcebans = false;
	}
}

public void OnConfigsExecuted()
{
	GetFilters();
}

// Commands for server managers
public Action Command_Reloadfilters(int client, int args)
{
	GetFilters();
	ReplyToCommand(client, "[Simple Filters] Filters reloaded !");
	return Plugin_Handled;
}

public Action Command_Chatfilters(int client, int args)
{
	if (!gc_bChatFilters.BoolValue)
	{
		PrintToChat(client, "Chat filters disabled");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "[Simple Filters] See console for output");
	
	if (client == 0)
	{
		PrintToServer("Chat Filters:");
	}
	else
	{
		PrintToConsole(client, "Chat Filters:");
	}
	
	int filters = sizeof(chatfilters);
	for (int i = 0; i < filters; i++)
	{
		if (StrEqual(chatfilters[i], ""))
		{
			break;
		}
		else if (client == 0)
		{
			PrintToServer("%d. %s", i + 1, chatfilters[i]);
		}
		else
		{
			PrintToConsole(client, "%d. %s", i + 1, chatfilters[i]);
		}
	}
	return Plugin_Handled;
}

public Action Command_Namefilters(int client, int args)
{
	if (!gc_bNameFilters.BoolValue)
	{
		PrintToChat(client, "Name filters disabled");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "[Simple Filters] See console for output");
	
	if (client == 0)
	{
		PrintToServer("Name Filters:");
	}
	else
	{
		PrintToConsole(client, "Name Filters:");
	}
	
	int filters = sizeof(namefilters);
	for (int i = 0; i < filters; i++)
	{
		if (StrEqual(namefilters[i], ""))
		{
			break;
		}
		else if (client == 0)
		{
			PrintToServer("%d. %s", i + 1, namefilters[i]);
		}
		else
		{
			PrintToConsole(client, "%d. %s", i + 1, namefilters[i]);
		}
	}
	return Plugin_Handled;
}

public Action Command_Whitelist(int client, int args)
{
	if (!gc_bWhitelist.BoolValue)
	{
		ReplyToCommand(client, "IP Whitelist disabled");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "[Simple Filters] See console for output");
	
	if (client == 0)
	{
		PrintToServer("IP Whitelist:");
	}
	else 
	{
		PrintToConsole(client, "IP Whitelist:");
	}
	
	int filters = sizeof(allowedips);
	for (int i = 0; i < filters; i++)
	{
		if (StrEqual(allowedips[i], ""))
		{
			break;
		}
		else if (client == 0)
		{
			PrintToServer("%d. %s", i + 1, allowedips[i]);
		}
		else
		{
			PrintToConsole(client, "%d. %s", i + 1, allowedips[i]);
		}
	}
	return Plugin_Handled;
}

// Chat-Filtering
public Action OnClientSayCommand(int client, const char[] command, const char[] message)
{
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	if (gc_bHideCommands.BoolValue)
	{
		if (message[0] == '!' || message[0] == '/' || message[1] == '!' || message[1] == '/')
		{
			if (!IsChatTrigger())
			{
				PrintToChat(client, "This command does not exist.");
			}
			return Plugin_Handled;
		}
	}
	
	if (gc_bChatSymbols.BoolValue)
	{
		if (regex.Match(message) > 0)
		{
			PrintToChat(client, "Your message has been blocked because it contains symbols.");
			return Plugin_Handled;
		}
	}
	
	if (gc_bChatFilters.BoolValue)
	{
		int filters = sizeof(chatfilters);
		for (int i = 0; i < filters; i++)
		{
			if (StrEqual(chatfilters[i], ""))
			{
				break;
			}
			else if (StrContains(message, chatfilters[i], false) != -1)
			{
				switch (gc_iChatPunishment.IntValue)
				{
					case 0:
					{
						BlockMessage(client, message);
					}
					case 1:
					{
						KickPlayer(client, message, chatfilters[i]);
					}
					case 2:
					{
						BanPlayer(client, message, chatfilters[i]);
					}
				}
				return Plugin_Handled;
			}
		}
	}
	
	if (gc_bChatIpFilters.BoolValue)
	{
		if (regexip.Match(message) > 0)
		{
			char ipad[32];
			GetRegexSubString(regexip, 0, ipad, sizeof(ipad));
			
			if (gc_bWhitelist.BoolValue)
			{
				int filters = sizeof(allowedips);
				for (int i = 0; i < filters; i++)
				{
					if (StrEqual(allowedips[i], ""))
					{
						break;
					}
					else if (StrEqual(ipad, allowedips[i]))
					{
						return Plugin_Continue;
					}
				}
			}
			
			switch (gc_iChatPunishment.IntValue)
			{
				case 0:
				{
					BlockMessage(client, message);
				}
				case 1:
				{
					KickPlayer(client, message, ipad);
				}
				case 2:
				{
					BanPlayer(client, message, ipad);
				}
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Hook_SayText2(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (gc_bHideNamechange.BoolValue)
	{
		if (!reliable)
		{
			return Plugin_Continue;
		}
	
		char message[192];
	
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbReadString(msg, "msg_name", message, sizeof(message));
			if (StrContains(message, "Name_Change") != -1)
			{
				return Plugin_Handled;
			}
		}
		else
		{
			BfReadString(msg, message, sizeof(message));
			BfReadString(msg, message, sizeof(message));
			if (StrContains(message, "Name_Change") != -1)
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

// Name-Filtering
public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	char playername[MAX_NAME_LENGTH];
	GetClientName(client, playername, sizeof(playername));
		
	ApplyNameFilters(client, playername);
}

public void Event_PlayerChangename(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	char playername[MAX_NAME_LENGTH];
	event.GetString("newname", playername, sizeof(playername));
	
	ApplyNameFilters(client, playername);
}

// Functions
void GetFilters()
{
	int filters = sizeof(chatfilters);
	for (int i = 0; i < filters; i++)
	{
		chatfilters[i] = "";
	}
	
	filters = sizeof(namefilters);
	for (int i = 0; i < filters; i++)
	{
		namefilters[i] = "";
	}
	
	filters = sizeof(allowedips);
	for (int i = 0; i < filters; i++)
	{
		allowedips[i] = "";
	}
	
	if (gc_bChatFilters.BoolValue)
	{
		File chat = OpenFile(chatfile, "rt");
		if (!chat)
		{
			SetFailState("Couldn't read from file configs/simple-chatfilters.txt");
		}
		
		char line[192];
		for (int i = 0; !chat.EndOfFile() && chat.ReadLine(line, sizeof(line)); i++)
		{
			ReplaceString(line, sizeof(line), "\n", "", false);
			SplitString(line, "//", line, sizeof(line));
			TrimString(line);
		
			if (StrEqual(line, ""))
			{
				i--;
			}
			else BreakString(line, chatfilters[i], sizeof(chatfilters[]));
		}
		delete chat;
	}
	
	if (gc_bNameFilters.BoolValue)
	{
		File name = OpenFile(namefile, "rt");
		if (!name)
		{
			SetFailState("Couldn't read from file configs/simple-namefilters.txt");
		}
		
		char line[192];
		for (int i = 0; !name.EndOfFile() && name.ReadLine(line, sizeof(line)); i++)
		{
			ReplaceString(line, sizeof(line), "\n", "", false);
			SplitString(line, "//", line, sizeof(line));
			TrimString(line);
		
			if (StrEqual(line, ""))
			{
				i--;
			}
			else BreakString(line, namefilters[i], sizeof(namefilters[]));
		}
		delete name;
	}
	
	if (gc_bWhitelist.BoolValue)
	{
		File whitelist = OpenFile(whitelistfile, "rt");
		if (!whitelist)
		{
			SetFailState("Couldn't read from file configs/simple-ipwhitelist.txt");
		}
		
		char line[192];
		for (int i = 0; !whitelist.EndOfFile() && whitelist.ReadLine(line, sizeof(line)); i++)
		{
			ReplaceString(line, sizeof(line), "\n", "", false);
			SplitString(line, "//", line, sizeof(line));
			TrimString(line);
		
			if (StrEqual(line, ""))
			{
				i--;
			}
			else BreakString(line, allowedips[i], sizeof(allowedips[]));
		}
		delete whitelist;
	}
}

void ApplyNameFilters(int client, const char[] playername)
{
	bool shouldrename;
	
	char name[MAX_NAME_LENGTH];
	char oldname[MAX_NAME_LENGTH];
	
	strcopy(name, sizeof(name), playername);
	strcopy(oldname, sizeof(oldname), playername);

	if (gc_bNameSymbols.BoolValue)
	{
		if (regex.Match(name) > 0)
		{
			char substr[MAX_NAME_LENGTH];
		
			while (regex.Match(name) > 0)
			{
				GetRegexSubString(regex, 0, substr, sizeof(substr));
				ReplaceString(name, sizeof(name), substr, "", false);
			}	
			TrimString(name);
			shouldrename = true;
		}
	}
	
	if (gc_bNameFilters.BoolValue)
	{
		int filters = sizeof(namefilters);
		for (int i = 0; i < filters; i++)
		{
			if (StrEqual(namefilters[i], ""))
			{
				break;
			}
			else if (StrContains(name, namefilters[i], false) != -1)
			{
				Rename(name, sizeof(name), namefilters[i]);
				shouldrename = true;
			}
		}
	}
	
	if (gc_bNameIpFilters.BoolValue)
	{
		if (regexip.Match(name) > 0)
		{
			bool allowed;
			
			char ipad[32];
			GetRegexSubString(regexip, 0, ipad, sizeof(ipad));
			
			if (gc_bWhitelist.BoolValue)
			{
				int filters = sizeof(allowedips);
				for (int i = 0; i < filters; i++)
				{
					if (StrEqual(allowedips[i], ""))
					{
						break;
					}
					else if (StrEqual(ipad, allowedips[i]))
					{
						allowed = true;
					}
				}
			}
			
			if (!allowed)
			{
				Rename(name, sizeof(name), ipad);
				shouldrename = true;
			}
		}
	}
	
	if (gc_bNameTooShort.BoolValue)
	{
		if (strlen(name) < 3)
		{
			FormatEx(name, sizeof(name), "Player #%d", GetClientUserId(client));
			SetClientInfo(client, "name", name);
			LogToFile(logfile, "Renamed \"%s\" according to the given name filters. New name: \"%s\"", oldname, name);
			return;
		}
	}
	
	if (shouldrename)
	{
		SetClientInfo(client, "name", name);
		LogToFile(logfile, "Renamed \"%s\" according to the given name filters. New name: \"%s\"", oldname, name);
	}
}

void Rename(char[] name, int maxlength, const char[] badword)
{
	char replacement[32];
	gc_sReplacement.GetString(replacement, sizeof(replacement));
	ReplaceString(name, maxlength, badword, replacement, false);
	TrimString(name);
}

void BlockMessage(int client, const char[] message)
{
	PrintToChat(client, "Your message has been blocked because it contains a bad word.");
	LogToFile(logfile, "Blocked %N's message because it contains a bad word. Message: \"%s\"", client, message);
}

void KickPlayer(int client, const char[] message, const char[] badword)
{
	KickClient(client, "Simple Filters by FAQU\n\n\
							You have been kicked for using a bad word in chat.\n\
							Bad word: %s", badword);
						
	LogToFile(logfile, "Kicked %N for using a bad word in chat. Message: \"%s\"", client, message);
}

void BanPlayer(int client, const char[] message, const char[] badword)
{
	char steamid[32];
	char ip[32];
	char sBantime[32];
	
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetClientIP(client, ip, sizeof(ip));
	
	int iBantime = gc_iBanDuration.IntValue;
	
	switch (iBantime)
	{
		case 0:
		{
			FormatEx(sBantime, sizeof(sBantime), "permanent");
		}
		default:
		{
			FormatEx(sBantime, sizeof(sBantime), "%d minutes", iBantime);
		}
	}
	
	switch (gc_iBanMethod.IntValue)
	{
		case 0:
		{
			if (Sourcebans)
			{
				SBPP_BanPlayer(0, client, iBantime, "Simple Filters");
			}
			else
			{
				BanClient(client, iBantime, BANFLAG_AUTHID | BANFLAG_AUTO | BANFLAG_NOKICK, "Simple Filters");
			}
		}
		case 1:
		{
			if (Sourcebans)
			{
				SBPP_BanPlayer(0, client, iBantime, "Simple Filters");
			}
			else 
			{
				BanClient(client, iBantime, BANFLAG_IP | BANFLAG_NOKICK, "Simple Filters");
			}
		}
		case 2:
		{
			if (Sourcebans)
			{
				SBPP_BanPlayer(0, client, iBantime, "Simple Filters");
			}
			else
			{
				BanClient(client, iBantime, BANFLAG_AUTHID | BANFLAG_AUTO | BANFLAG_NOKICK, "Simple Filters");
				BanClient(client, iBantime, BANFLAG_IP | BANFLAG_NOKICK, "Simple Filters");
			}
		}
	}
	
	KickClient(client, "Simple Filters by FAQU\n\n\
							You have been banned for using a bad word in chat.\n\
							Ban duration: %s\n\
							Bad word: %s", sBantime, badword);
						
	LogToFile(logfile, "Banned %N [%s | %s] for using a bad word in chat. Message: \"%s\"", client, steamid, ip, message);
}