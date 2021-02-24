#if defined stringdata
 #endinput
#endif

#define stringdata

#if !defined MAXTABLES
 #define MAXTABLES 32
#endif

#include <regex>

static const char szPrepsNames[][] =
{
	"CNetworkStringTableContainer::CreateStringTable",
	"CNetworkStringTable::CopyStringTable",
	"CNetworkStringTable::DeleteAllStrings",
	"CNetworkStringTableContainer::FindTable",
	"CNetworkStringTableContainer::GetTable"
};

enum StringTable
{
	INVALID_TABLE = -1
};

enum StringTableAction
{
	CREATE_TABLE = 0,
	COPY_TABLE,
	DELETE_ALL_STRINGS,
	FINDTABLE_BYNAME,
	FINDTABLE_BYINDEX
}

methodmap StringTable
{
	public StringTable ()
    {
        return view_as<StringTable>(GetPointer());
    }
	
	property int tableindex
    {
        public get()
		{
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(50), NumberType_Int8);
		}
    }
	
	public static void SetStateCreate(any state)
	{
		StoreToAddress(view_as<Address>(GetPointer()) + view_as<Address>(4), state, NumberType_Int32);
	}
	
	public static bool IsAllowCreate()
	{
		return view_as<bool>(LoadFromAddress(view_as<Address>(GetPointer()) + view_as<Address>(4), NumberType_Int32));
	}
	
	public static StringTable Create(const char[] szName, int maxstrings, int userdatafixedsize = 0, int userdatanetworkbits = 0, bool bIsFilenames = false)
	{
		StringTable pTable = view_as<StringTable>(SDKCall(PrepCall(CREATE_TABLE, SDKCall_Raw), GetPointer(), szName, maxstrings, userdatafixedsize, userdatanetworkbits, bIsFilenames));
		StoreToAddress(view_as<Address>(pTable) + view_as<Address>(50), FindStringTable(szName), NumberType_Int8);
		return pTable;
	}
	
	public int StoreData(int maxlenght, const char[] szData = "", const char[] szUserData = "")
	{
		int index = this.tableindex;
		AddToStringTable(index, szData, szUserData, maxlenght);
		return FindStringIndex(index, szData);
	}
	
	public void GetData(int stringindex, int maxlength = 0, char[] szStore = "", int maxuserdata = 0, char[] szUserData = "")
	{
		int index = this.tableindex;
		
		GetStringTableData(index, stringindex, szUserData, maxuserdata);
		ReadStringTable(index, stringindex, szStore, maxlength);
	}
	
	public static StringTable ByName (const char[] name)
	{
		return view_as<StringTable>(SDKCall(PrepCall(FINDTABLE_BYNAME, SDKCall_Raw), GetPointer(), name));
	}
	
	public static StringTable ByIndex (int index)
	{
		return view_as<StringTable>(SDKCall(PrepCall(FINDTABLE_BYINDEX, SDKCall_Raw), GetPointer(), index));
	}
	
	public void DeleteStrings ()
	{
		SDKCall(PrepCall(DELETE_ALL_STRINGS, SDKCall_Raw), this);
	}
	
	public void Name(char[] szSave, int maxlenght)
	{
		GetStringTableName(this.tableindex, szSave, maxlenght);
	}
	
	public void Copy(StringTable pTable)
	{
		SDKCall(PrepCall(COPY_TABLE, SDKCall_Raw), GetPointer(), view_as<int>(this), view_as<int>(pTable));
	}
	
	public static int MaxTables ()
	{
		return MAXTABLES;
	}
	
	public static int NumTables ()
	{
		return GetNumStringTables();
	}
	
	public int MaxStrings ()
	{
		return GetStringTableMaxStrings(this.tableindex);
	}
	
	public int Strings ()
	{
		return GetStringTableNumStrings(this.tableindex);
	}
};

GameData GetConf()
{
	static GameData hData;
	
	if (hData == null)
		hData = new GameData("stringtabledata");
		
	return hData;
}

Address GetPointer ()
{
	static Address s_NetworkStringTableServer;
	
	if (s_NetworkStringTableServer == Address_Null)
	{
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(GetConf(), SDKConf_Signature, "CreateInterface");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		s_NetworkStringTableServer = SDKCall(EndPrepSDKCall(), "VEngineServerStringTable001", 0);
		delete EndPrepSDKCall();
	}
		
	return s_NetworkStringTableServer;
}

Handle PrepCall (StringTableAction pTableAction, SDKCallType SDKCType)
{
	static Handle hCall;
	
	if (hCall != null)
		delete hCall;
	
	StartPrepSDKCall(SDKCType);
	PrepSDKCall_SetFromConf(GetConf(), SDKConf_Signature, szPrepsNames[view_as<int>(pTableAction)]);
	
	switch (pTableAction)
	{
		case CREATE_TABLE:
		{
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		}
		case FINDTABLE_BYNAME:
		{
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		}
		case FINDTABLE_BYINDEX:
		{
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		}
		case COPY_TABLE:
		{
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		}
	}
	
	hCall = EndPrepSDKCall();
	
	return hCall;
}