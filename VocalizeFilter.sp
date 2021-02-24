#include <sourcemod>
#include <sdktools>
#include <sceneprocessor>
public Plugin:myinfo =
{
	name		= "Vocalize Filter",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Allow administrators to filter out vocalize commands.",
	version		= "1.0.1",
}
#define CVAR_FILTERMODE_NAME "vocalizefilter_mode"
#define CVAR_FILTERMODE_DESC "Whether Vocalize Filter will blacklist or whitelist vocalize strings defined in config. 0 = Blacklist mode, 1 = Whitelist mode."
#define CVAR_FILTERMODE_VALUE "1"
#define COMMAND_VOCALIZE_FILTER_ACCESS "vocalize_filter_access"
#define COMMAND_VOCALIZE_FILTER_ACCESS_FLAG ADMFLAG_ROOT
#define VOCALIZE_FILTER_FILE "configs/VocalizeFilter.cfg"
#define CR '\r'
#define LF '\n'
#define TAB '\t'
#define SPACE ' '
#define COMMENT '/'
#define FILTER_MODE_BLACKLIST 0
#define FILTER_MODE_WHITELIST 1
new g_FilterMode
new Handle:g_VocalizeStringArray
public OnPluginStart()
{
	g_VocalizeStringArray = CreateArray(MAX_VOCALIZE_LENGTH)
	ReadVocalizeFilterFile(VOCALIZE_FILTER_FILE)
	new Handle:convar = CreateConVar(CVAR_FILTERMODE_NAME, CVAR_FILTERMODE_VALUE, CVAR_FILTERMODE_DESC, FCVAR_PROTECTED)
	g_FilterMode = GetConVarInt(convar)
	HookConVarChange(convar, FilterMode_ConVarChanged)
}
public FilterMode_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_FilterMode = GetConVarInt(convar)
}
public Action:OnVocalizeCommand(client, const String:vocalize[], initiator)
{
	if (client != initiator)
	{
		return Plugin_Continue
	}
	decl flags
	if (GetCommandOverride(COMMAND_VOCALIZE_FILTER_ACCESS, Override_Command, flags) &&
		CheckCommandAccess(client, COMMAND_VOCALIZE_FILTER_ACCESS, COMMAND_VOCALIZE_FILTER_ACCESS_FLAG, true))
	{
		return Plugin_Continue
	}
	new String:searchVocalize[MAX_VOCALIZE_LENGTH]
	strcopy(searchVocalize, MAX_VOCALIZE_LENGTH, vocalize)
	new searchVocalizeLen = strlen(searchVocalize)
	for (new i = 1; i < searchVocalizeLen; i++)
	{
		if (IsCharMB(searchVocalize[i]))
		{
			return Plugin_Continue
		}
	}
	StringToLower(searchVocalize, MAX_VOCALIZE_LENGTH)
	return (FindStringInArray(g_VocalizeStringArray, searchVocalize) != -1 && g_FilterMode == FILTER_MODE_WHITELIST ? Plugin_Continue : Plugin_Stop)
}
static ReadVocalizeFilterFile(const String:filename[])
{
	decl String:path[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, filename)
	new Handle:file = OpenFile(path, "r")
	if (file == INVALID_HANDLE)
	{
		SetFailState("Vocalize filter file was not found. File path: \"%s\"", path)
	}
	decl String:buffer[256], tmp, bufferLen
	while (!IsEndOfFile(file) && ReadFileLine(file, buffer, sizeof(buffer)))
	{
		tmp = buffer[0]
		if (tmp == 0 ||
				tmp == CR ||
				tmp == LF ||
				tmp == TAB ||
				tmp == SPACE ||
				tmp == COMMENT)
		continue
		bufferLen = strlen(buffer)
		for (new i = 1; i < bufferLen; i++)
		{
			tmp = buffer[i]
			if (tmp == 0 ||
					tmp == CR ||
					tmp == LF ||
					tmp == TAB ||
					tmp == SPACE ||
					tmp == COMMENT)
			{
				buffer[i] = 0
				break
			}
		}
		StringToLower(buffer, sizeof(buffer))
		PushArrayString(g_VocalizeStringArray, buffer)
	}
	CloseHandle(file)
}
stock StringToLower(String:string[], len)
{
	len--
	new i = 0
	for (i = 0; i < len; i++)
	{
		if (string[i] == '\0' || IsCharMB(string[i]))
		{
			break
		}
		string[i] = CharToLower(string[i])
	}
	string[i] = '\0'
}