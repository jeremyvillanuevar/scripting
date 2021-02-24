#if defined _config_included
  #endinput
#endif
#define _config_included
#include <core>

enum SettingType {
	ST_None = 0,
	ST_Group = 1,
	ST_Int = 2,
	ST_Float = 3,
	ST_String = 4,
	ST_Bool = 5,
	ST_Array = 6,
	ST_List = 7,
}


// the api documentation can be found at http://forums.alliedmods.net/showthread.php?t=69167


/**
 * Creates a new empty config object.
 *
 * @note this handle has to be closed
 *
 * @return Handle					The config handle
 */
native Handle:ConfigCreate();

native bool:ConfigFileExists(const String:FileName[]="");
native bool:ConfigReadFile(Handle:Config, const String:FileName[]="", String:ErrorMsg[]="", MaxLength=0, &ErrorLine=0);
native bool:ConfigWriteFile(Handle:Config, const String:FileName[]="");

// config set/get auto convert

native ConfigLookupInt(Handle:Config, const String:Path[]);
native Float:ConfigLookupFloat(Handle:Config, const String:Path[]);
native bool:ConfigLookupBool(Handle:Config, const String:Path[]);
native bool:ConfigLookupString(Handle:Config, const String:Path[], String:Result[], MaxLength);

native Handle:ConfigLookup(Handle:Config, const String:Path[]);

native ConfigSettingGetInt(Handle:Setting);
native Float:ConfigSettingGetFloat(Handle:Setting);
native bool:ConfigSettingGetBool(Handle:Setting);
native bool:ConfigSettingGetString(Handle:Setting, String:Result[], MaxLength);

native bool:ConfigSettingSetInt(Handle:Setting, Value);
native bool:ConfigSettingSetFloat(Handle:Setting, Float:Value);
native bool:ConfigSettingSetBool(Handle:Setting, bool:Value);
native bool:ConfigSettingSetString(Handle:Setting, const String:Value[]);

// setting get/set format

native Handle:ConfigSettingGetMember(Handle:Setting, String:Name[]);
native Handle:ConfigSettingGetElement(Handle:Setting, Index);

native ConfigSettingGetIntElement(Handle:Setting, Index);
native Float:ConfigSettingGetFloatElement(Handle:Setting, Index);
native bool:ConfigSettingGetBoolElement(Handle:Setting, Index);
native bool:ConfigSettingGetStringElement(Handle:Setting, Index, String:Result[], MaxLength);

native bool:ConfigSettingSetIntElement(Handle:Setting, Index, Value);
native bool:ConfigSettingSetFloatElement(Handle:Setting, Index, Float:Value);
native bool:ConfigSettingSetBoolElement(Handle:Setting, Index, bool:Value);
native bool:ConfigSettingSetStringElement(Handle:Setting, Index, const String:Value[]);

native Handle:ConfigSettingAdd(Handle:ParentSetting, String:Name[], SettingType:Type);
native bool:ConfigSettingRemove(Handle:ParentSetting, String:Name[]);

native Handle:ConfigRootSetting(Handle:Config);

native ConfigSettingName(Handle:Setting, String:Result[], MaxLength);
native ConfigSettingLength(Handle:Setting);
native SettingType:ConfigSettingType(Handle:Setting);

native bool:ConfigSettingIsGroup(Handle:Setting);
native bool:ConfigSettingIsArray(Handle:Setting);
native bool:ConfigSettingIsList(Handle:Setting);

native bool:ConfigSettingIsAggregate(Handle:Setting);
native bool:ConfigSettingIsScalar(Handle:Setting);
native bool:ConfigSettingIsNumber(Handle:Setting);

native ConfigSettingSourceLine(Handle:Setting);

/**
 * _________________Do not edit below this line!_______________________
 */
public Extension:__ext_smconfig = 
{
	name = "Config",
	file = "config.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
