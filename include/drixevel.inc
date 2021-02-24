/*
**	My own personal include because reasons... thanks Obama.
**	This file just helps me keep all of my custom functions and defines in 1 easy include.
**	No licensing on the file... nor can there be. Feel free to use it or rip from it. I don't give a shit.
**	http://www.drixevel.com/
**
*/
#if defined _Drixevel_included
 #endinput
#endif
#define _Drixevel_included

////////////////////////
//Copy Pasta Shit
/*
--sql
char sQuery[QUERY_LENGTH];
Format(sQuery, sizeof(sQuery), "");
SQL_TQuery(hDatabase, TQuery_, sQuery);

--sql callback
public void CopyPasta123123(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		return;
	}
	
	
}

--menu
	Handle hMenu = CreateMenu(MenuHandle_);
	SetMenuTitle(hMenu, "");
	
	AddMenuItem(hMenu, "", "");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);

--menu handle
public int CopyPasta123123(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

--back
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				
			}
		}
		
--ask plugin load 2
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("", Native_);
	
	RegPluginLibrary("");
	return APLRes_Success;
}
*/

//Includes
#include <sdktools>

//Defines
#define QUERY_LENGTH 4096

////////////////////////
//Replace Colors Stuff

bool g_bCSS;
bool g_bCSGO;

Handle g_hRGBTrie;
Handle g_hNormalTrie;
Handle g_hRGBArray;
Handle g_hNormalArray;

//
////////////////////////

//Converts seconds to a buffer string. (picked this up from timer plugins, could be useful)
stock void Timer_SecondsToTime(float seconds, char[] buffer, int maxlength, bool precision = true)
{
	int t = RoundToFloor(seconds);
	
	int hour; int mins;
	
	if (t >= 3600)
	{
		hour = RoundToFloor(t / 3600.0);
		t %= 3600;
	}
	
	if (t >= 60)
	{
		mins = RoundToFloor(t / 60.0);
		t %= 60;
	}
	
	Format(buffer, maxlength, "");

	if (hour)
	{
		Format(buffer, maxlength, "%s%02d:", buffer, hour);
	}
	
	Format(buffer, maxlength, "%s%02d:", buffer, mins);
	
	if (precision)
	{
		Format(buffer, maxlength, "%s%06.3f", buffer, float(t) + seconds - RoundToFloor(seconds));
	}
	else 
	{
		Format(buffer, maxlength, "%s%02d", buffer, t);
	}
}

//Changes all characters to upper case.
stock void StringToLower(char[] f_sInput)
{	
	for (int i = 0 ; i < strlen(f_sInput); i++)
	{
		f_sInput[i] = CharToLower(f_sInput[i]);
	}
}

//Copies static arrays even though I don't like using them.
stock void Array_Copy(const any[] array, any[] newArray, int size)
{
	for (new i = 0; i < size; i++)
	{
		newArray[i] = array[i];
	}
}

//It's surprisingly useful and even more surprisingly used often.
//This makes sure a string is only filled with numbers... I KNOW RIGHT?
stock bool String_IsNumeric(const char[] str)
{
	int x = 0;
	int dotsFound = 0;
	int numbersFound = 0;

	if (str[x] == '+' || str[x] == '-')
	{
		x++;
	}

	while (str[x] != '\0')
	{
		if (IsCharNumeric(str[x]))
		{
			numbersFound++;
		}
		else if (str[x] == '.')
		{
			dotsFound++;
			
			if (dotsFound > 1)
			{
				return false;
			}
		}
		else
		{
			return false;
		}
		
		x++;
	}
	
	if (!numbersFound)
	{
		return false;
	}
	
	return true;
}

//GLORIOUS MENU SUPPORT (this should already be a thing with Sourcemod)
//Ease of use when formatting strings for menu items.
stock bool AddMenuItemFormat(Handle &menu, const char[] info, int style = ITEMDRAW_DEFAULT, const char[] format, any...)
{
	char display[128];
	VFormat(display, sizeof(display), format, 5);
	
	return AddMenuItem(menu, info, display, style);
}

//Allows you to push a cell to a menu for ease of use.
stock void PushMenuCell(Handle hndl, const char[] id, int data)
{
	char DataString[64];
	IntToString(data, DataString, sizeof(DataString));
	AddMenuItem(hndl, id, DataString, ITEMDRAW_IGNORE);
}

//Gets the menus tring that was pushed with 'GetMenuCell'.
//Returns true if found, false otherwise.
stock int GetMenuCell(Handle hndl, const char[] id, int DefaultValue = 0)
{
	int ItemCount = GetMenuItemCount(hndl);
	char info[64]; char data[64];
	
	for (int i = 0; i < ItemCount; i++)
	{
		GetMenuItem(hndl, i, info, sizeof(info), _, data, sizeof(data));
		
		if (StrEqual(info, id))
		{
			return StringToInt(data);
		}
	}
	
	return DefaultValue;
}

//Allows you to push a string to a menu for ease of use.
stock void PushMenuString(Handle hndl, const char[] id, const char[] data)
{
	AddMenuItem(hndl, id, data, ITEMDRAW_IGNORE);
}

//Gets the menus tring that was pushed with 'PushMenuString'.
//Returns true if found, false otherwise.
stock bool GetMenuString(Handle hndl, const char[] id, char[] Buffer, int size)
{
	int ItemCount = GetMenuItemCount(hndl);
	char info[64]; char data[64];
	
	for (int i = 0; i < ItemCount; i++)
	{
		GetMenuItem(hndl, i, info, sizeof(info), _, data, sizeof(data));
		
		if (StrEqual(info, id))
		{
			strcopy(Buffer, size, data);
			return true;
		}
	}
	
	return false;
}

//Gets the clients exact look position.
stock bool GetClientSightEnd(int client, float fResults[3], TraceEntityFilter filter, int flags = MASK_PLAYERSOLID, RayType rtype = RayType_Infinite, any data)
{
	//Get their eye position
	float m_fEyes[3];
	GetClientEyePosition(client, m_fEyes);
	
	//Get their eye angle
	float m_fAngles[3];
	GetClientEyeAngles(client, m_fAngles);
	
	//Calculate the data so we can send it back.
	Handle hTrace = TR_TraceRayFilterEx(m_fEyes, m_fAngles, flags, rtype, filter, data);
	TR_GetEndPosition(fResults, hTrace);
	
	return TR_DidHit(hTrace);
}

//Checks a client for flags from a string and returns true if they have them or false otherwise.
//This will return false if they have no flags.
stock bool CheckAdminFlagsByString(int client, const char[] flagString)
{
	AdminId admin = GetUserAdmin(client);
	
	if (admin != INVALID_ADMIN_ID)
	{
		int count; int found; int flags = ReadFlagString(flagString);
		
		for (int i = 0; i <= 20; i++)
		{
			if (flags & (1 << i))
			{
				count++;
				
				if (GetAdminFlag(admin, view_as<AdminFlag>(i)))
				{
					found++;
				}
			}
		}
		
		if (count == found)
		{
			return true;
		}
	}
	
	return false;
}

//Allows for faster queries while keeping the treading bits. (no callback)
stock void SQL_TFastQuery(Handle database, const char[] query, DBPriority prio = DBPrio_Normal)
{
	SQL_TQuery(database, VoidCallback, query, _, prio);
}

//Callback for the threaded query with no callback required.
public void VoidCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("Error on SQL callback: %s", error);
	}
}

//KvGetBool	- Ease of life stock.
stock bool KvGetBool(Handle hKV, const char[] sKey, bool bDefaultValue = false)
{
	return view_as<bool>(KvGetNum(hKV, sKey, view_as<int>(bDefaultValue)));
}

//SQL_FetchBool - Why is this not in the API? I know SQL_FetchInt is a thing but... cmon.
stock bool SQL_FetchBool(Handle query, int field, DBResult &result = DBVal_Error)
{
	return view_as<bool>(SQL_FetchInt(query, field, result));
}

//ReplaceColors... Totally not stolen.
stock void ReplaceColors(char[] text, int maxlen, int client = 0)
{
	if (g_hRGBTrie == null) g_hRGBTrie = CreateTrie();
	if (g_hNormalTrie == null) g_hNormalTrie = CreateTrie();
	if (g_hRGBArray == null) g_hRGBArray = CreateArray(ByteCountToCells(256));
	if (g_hNormalArray == null) g_hNormalArray = CreateArray(ByteCountToCells(256));
	
	if (GetTrieSize(g_hRGBTrie) < 1)
	{
		FillTrieData();
	}
	
	int m_iPos = FindCharInString(text, '{');
	
	if (m_iPos == -1)
	{
		return;
	}
	
	char[] m_szBuffer = new char[maxlen];
	
	int m_iPad = 1;
	
	if (text[0] != 1)
	{
		m_szBuffer[0] = 0x1;
	}
	
	if (g_bCSGO && text[1] != ' ')
	{
		m_szBuffer[1] = ' ';
		++m_iPad;
	}
	
	strcopy(m_szBuffer[m_iPad], maxlen - m_iPad, text);
	
	char m_szReplace[256];
	m_szReplace[1] = 0;
	
	do
	{
		int m_iEnd = FindCharInString(text[m_iPos], '}');
		
		if (m_iEnd == -1)
		{
			break;
		}
		
		char m_szSubstring[256];
		strcopy(m_szSubstring, m_iEnd + 2, text[m_iPos]);
		m_iPos += m_iEnd + 2;
		
		m_szSubstring[strlen(m_szSubstring) - 1] = 0;
		
		bool m_bRet; int m_iValue;
		if (g_bCSS)
		{
			m_bRet = GetTrieValue(g_hRGBTrie, m_szSubstring[1], m_iValue);
			if (client != 0 && !m_bRet && strcmp(m_szSubstring[1], "teamcolor") == 0)
			{
				m_bRet = true;
				int m_iTeam = GetClientTeam(client);
				if (m_iTeam == 1)
				{
					m_iValue = 0xCCCCCC;
				}
				else if (g_bCSS)
				{
					switch (m_iTeam)
					{
						case 2: m_iValue = 0xFF4040;
						case 3: m_iValue = 0x99CCFF;
					}
				}
			}
		}
		else
		{
			m_bRet = GetTrieValue(g_hNormalTrie, m_szSubstring[1], m_iValue);
		}
		
		if (!m_bRet)
		{
			continue;
		}
		
		m_szSubstring[strlen(m_szSubstring)] = '}';
		
		if (g_bCSS)
		{
			Format(m_szReplace, sizeof(m_szReplace), "\x07%06X", m_iValue);
		}
		else
		{
			m_szReplace[0] = m_iValue;
		}
		
		ReplaceString(m_szBuffer, maxlen, m_szSubstring, m_szReplace, false);
	} while ((m_iPos += FindCharInString(text[m_iPos], '{')) != -1);
	
	strcopy(text, maxlen, m_szBuffer);
}

//Definition of an easy to use stock. Pushes the colors below into data.
stock void PushColor(const char[] sKey, any value, bool bOld = false)
{
	PushArrayString(bOld ? g_hNormalArray : g_hRGBArray, sKey);
	SetTrieValue(bOld ? g_hNormalTrie : g_hRGBTrie, sKey, value);
}

//Fills the data for colors.
stock void FillTrieData()
{
	PushColor("default", 0xFFB400);
	PushColor("aliceblue", 0xF0F8FF);
	PushColor("allies", 0x4D7942);
	PushColor("antiquewhite", 0xFAEBD7);
	PushColor("aqua", 0x00FFFF);
	PushColor("aquamarine", 0x7FFFD4);
	PushColor("axis", 0xFF4040);
	PushColor("azure", 0x007FFF);
	PushColor("beige", 0xF5F5DC);
	PushColor("bisque", 0xFFE4C4);
	PushColor("black", 0x000000);
	PushColor("blanchedalmond", 0xFFEBCD);
	PushColor("blue", 0x99CCFF);
	PushColor("blueviolet", 0x8A2BE2);
	PushColor("brown", 0xA52A2A);
	PushColor("burlywood", 0xDEB887);
	PushColor("cadetblue", 0x5F9EA0);
	PushColor("chartreuse", 0x7FFF00);
	PushColor("chocolate", 0xD2691E);
	PushColor("community", 0x70B04A);
	PushColor("coral", 0xFF7F50);
	PushColor("cornflowerblue", 0x6495ED);
	PushColor("cornsilk", 0xFFF8DC);
	PushColor("crimson", 0xDC143C);
	PushColor("cyan", 0x00FFFF);
	PushColor("darkblue", 0x00008B);
	PushColor("darkcyan", 0x008B8B);
	PushColor("darkgoldenrod", 0xB8860B);
	PushColor("darkgray", 0xA9A9A9);
	PushColor("darkgrey", 0xA9A9A9);
	PushColor("darkgreen", 0x006400);
	PushColor("darkkhaki", 0xBDB76B);
	PushColor("darkmagenta", 0x8B008B);
	PushColor("darkolivegreen", 0x556B2F);
	PushColor("darkorange", 0xFF8C00);
	PushColor("darkorchid", 0x9932CC);
	PushColor("darkred", 0x8B0000);
	PushColor("darksalmon", 0xE9967A);
	PushColor("darkseagreen", 0x8FBC8F);
	PushColor("darkslateblue", 0x483D8B);
	PushColor("darkslategray", 0x2F4F4F);
	PushColor("darkslategrey", 0x2F4F4F);
	PushColor("darkturquoise", 0x00CED1);
	PushColor("darkviolet", 0x9400D3);
	PushColor("deeppink", 0xFF1493);
	PushColor("deepskyblue", 0x00BFFF);
	PushColor("dimgray", 0x696969);
	PushColor("dimgrey", 0x696969);
	PushColor("dodgerblue", 0x1E90FF);
	PushColor("firebrick", 0xB22222);
	PushColor("floralwhite", 0xFFFAF0);
	PushColor("forestgreen", 0x228B22);
	PushColor("fuchsia", 0xFF00FF);
	PushColor("fullblue", 0x0000FF);
	PushColor("fullred", 0xFF0000);
	PushColor("gainsboro", 0xDCDCDC);
	PushColor("genuine", 0x4D7455);
	PushColor("ghostwhite", 0xF8F8FF);
	PushColor("gold", 0xFFD700);
	PushColor("goldenrod", 0xDAA520);
	PushColor("gray", 0xCCCCCC);
	PushColor("grey", 0xCCCCCC);
	PushColor("green", 0x3EFF3E);
	PushColor("greenyellow", 0xADFF2F);
	PushColor("haunted", 0x38F3AB);
	PushColor("honeydew", 0xF0FFF0);
	PushColor("hotpink", 0xFF69B4);
	PushColor("indianred", 0xCD5C5C);
	PushColor("indigo", 0x4B0082);
	PushColor("ivory", 0xFFFFF0);
	PushColor("khaki", 0xF0E68C);
	PushColor("lavender", 0xE6E6FA);
	PushColor("lavenderblush", 0xFFF0F5);
	PushColor("lawngreen", 0x7CFC00);
	PushColor("lemonchiffon", 0xFFFACD);
	PushColor("lightblue", 0xADD8E6);
	PushColor("lightcoral", 0xF08080);
	PushColor("lightcyan", 0xE0FFFF);
	PushColor("lightgoldenrodyellow", 0xFAFAD2);
	PushColor("lightgray", 0xD3D3D3);
	PushColor("lightgrey", 0xD3D3D3);
	PushColor("lightgreen", 0x99FF99);
	PushColor("lightpink", 0xFFB6C1);
	PushColor("lightsalmon", 0xFFA07A);
	PushColor("lightseagreen", 0x20B2AA);
	PushColor("lightskyblue", 0x87CEFA);
	PushColor("lightslategray", 0x778899);
	PushColor("lightslategrey", 0x778899);
	PushColor("lightsteelblue", 0xB0C4DE);
	PushColor("lightyellow", 0xFFFFE0);
	PushColor("lime", 0x00FF00);
	PushColor("limegreen", 0x32CD32);
	PushColor("linen", 0xFAF0E6);
	PushColor("magenta", 0xFF00FF);
	PushColor("maroon", 0x800000);
	PushColor("mediumaquamarine", 0x66CDAA);
	PushColor("mediumblue", 0x0000CD);
	PushColor("mediumorchid", 0xBA55D3);
	PushColor("mediumpurple", 0x9370D8);
	PushColor("mediumseagreen", 0x3CB371);
	PushColor("mediumslateblue", 0x7B68EE);
	PushColor("mediumspringgreen", 0x00FA9A);
	PushColor("mediumturquoise", 0x48D1CC);
	PushColor("mediumvioletred", 0xC71585);
	PushColor("midnightblue", 0x191970);
	PushColor("mintcream", 0xF5FFFA);
	PushColor("mistyrose", 0xFFE4E1);
	PushColor("moccasin", 0xFFE4B5);
	PushColor("navajowhite", 0xFFDEAD);
	PushColor("navy", 0x000080);
	PushColor("normal", 0xB2B2B2);
	PushColor("oldlace", 0xFDF5E6);
	PushColor("olive", 0x9EC34F);
	PushColor("olivedrab", 0x6B8E23);
	PushColor("orange", 0xFFA500);
	PushColor("orangered", 0xFF4500);
	PushColor("orchid", 0xDA70D6);
	PushColor("palegoldenrod", 0xEEE8AA);
	PushColor("palegreen", 0x98FB98);
	PushColor("paleturquoise", 0xAFEEEE);
	PushColor("palevioletred", 0xD87093);
	PushColor("papayawhip", 0xFFEFD5);
	PushColor("peachpuff", 0xFFDAB9);
	PushColor("peru", 0xCD853F);
	PushColor("pink", 0xFFC0CB);
	PushColor("plum", 0xDDA0DD);
	PushColor("powderblue", 0xB0E0E6);
	PushColor("purple", 0x800080);
	PushColor("red", 0xFF4040);
	PushColor("lightred", 0xFF8080);
	PushColor("rosybrown", 0xBC8F8F);
	PushColor("royalblue", 0x4169E1);
	PushColor("saddlebrown", 0x8B4513);
	PushColor("salmon", 0xFA8072);
	PushColor("sandybrown", 0xF4A460);
	PushColor("seagreen", 0x2E8B57);
	PushColor("seashell", 0xFFF5EE);
	PushColor("selfmade", 0x70B04A);
	PushColor("sienna", 0xA0522D);
	PushColor("silver", 0xC0C0C0);
	PushColor("skyblue", 0x87CEEB);
	PushColor("slateblue", 0x6A5ACD);
	PushColor("slategray", 0x708090);
	PushColor("slategrey", 0x708090);
	PushColor("snow", 0xFFFAFA);
	PushColor("springgreen", 0x00FF7F);
	PushColor("steelblue", 0x4682B4);
	PushColor("strange", 0xCF6A32);
	PushColor("tan", 0xD2B48C);
	PushColor("teal", 0x008080);
	PushColor("thistle", 0xD8BFD8);
	PushColor("tomato", 0xFF6347);
	PushColor("turquoise", 0x40E0D0);
	PushColor("unique", 0xFFD700);
	PushColor("unusual", 0x8650AC);
	PushColor("valve", 0xA50F79);
	PushColor("vintage", 0x476291);
	PushColor("violet", 0xEE82EE);
	PushColor("wheat", 0xF5DEB3);
	PushColor("white", 0xFFFFFF);
	PushColor("whitesmoke", 0xF5F5F5);
	PushColor("yellow", 0xFFFF00);
	PushColor("yellowgreen", 0x9ACD32);
	
	PushColor("white", 0x1, true);
	PushColor("default", 0x1, true);
	PushColor("darkred", 0x2, true);
	PushColor("green", 0x4, true);
	PushColor("teamcolor", 0x3, true);
	PushColor("lightgreen", 0x3, true);
	PushColor("red", 0x3, true);
	PushColor("blue", 0x3, true);
	PushColor("olive", 0x5, true);
	PushColor("lime", 0x6, true);
	PushColor("lightred", 0x7, true);
	PushColor("purple", 0x3, true);
	PushColor("grey", 0x8, true);
	PushColor("gray", 0x8, true);
	PushColor("yellow", 0x9, true);
	PushColor("lightblue", 0xB, true);
	PushColor("blue", 0xC, true);
	PushColor("purple", 0xE, true);
	PushColor("darkorange", 0xF, true);
	PushColor("orange", 0x10, true);
}