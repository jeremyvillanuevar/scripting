
#define DMG_VALUE			999999

#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define DIST_DOOR			1000.0
#define DIST_FINALE			300.0
#define DIST_SENSOR			20.0
#define DIST_REFERENCE		80.0
#define DIST_DUMMYHEIGHT	-53.0

#define FILE_SPAWN			"saferoom_boxspawn"
#define FILE_CPDOOR			"saferoom_cpdoor"
#define FILE_FINALE			"saferoom_finale"

#define SND_TELEPORT		"ui/menu_horror01.wav"
#define SND_BURNING			"ambient/fire/fire_small_loop2.wav"
#define SND_WARNING			"items/suitchargeok1.wav"

#define MDL_SPAWNROOM1		"models/props_doors/checkpoint_door_01.mdl"
#define MDL_SPAWNROOM2		"models/props_doors/checkpoint_door_-01.mdl"
#define MDL_CHECKROOM1		"models/props_doors/checkpoint_door_02.mdl"
#define MDL_CHECKROOM2		"models/props_doors/checkpoint_door_-02.mdl"

#define PAT_FIRE			"burning_character_screen"			// @Silver [L4D2] Hud Splatter

#define MAT_BEAM			"materials/sprites/laserbeam.vmt"	// @silver [ANY] Trigger Multiple Commands
#define MAT_HALO			"materials/sprites/halo01.vmt"
#define MAT_BLOOD			"materials/sprites/bloodspray.vmt"


int g_iColor_Green[]	= { 000, 255, 000, 20 };
int g_iColor_Red[]		= { 255, 000, 000, 20 };
int g_iColor_Purple[]	= { 128, 000, 128, 20 };

////////////////////////////////////////////////
////// Developer Touch Area Constructor ////////
int		g_iMaterialLaser;
int		g_iMaterialHalo;
int		g_iMaterialBlood;
int		g_iEntityTest;
int		g_iEntityReff;
float	g_fVecPos[3];
float	g_fVecAng[3];
float	g_fVecMin[3] = { -100.0, -100.0, 0.0 };
float	g_fVecMax[3] = { 100.0, 100.0, 100.0 };
////////////////////////////////////////////////
////////////////////////////////////////////////


enum //=== Constructor Move Type =======//
{
	MOVE_DELETE,
	MOVE_THICK,
	MOVE_WIDTH,
	MOVE_SIDE1,
	MOVE_SIDE2,
	MOVE_HEIGHT,
	MOVE_ANGLE,
	MOVE_LENGTH
}

enum //=== Map Vector Config ==========//
{
	VEC_POS,
	VEC_ANG,
	VEC_MIN,
	VEC_MAX,
	VEC_LEN
}

enum //=== Global Timer ==============//
{
	TIMER_GLOBAL,
	TIMER_VEHICLE,
	TIMER_CHECKPOINT,
	TIMER_LASER1,
	TIMER_LASER2,
	TIMER_LENGTH
}

enum //=== Client Room State =========//
{
	ROOM_STATE_OUTDOOR,
	ROOM_STATE_SPAWN,
	ROOM_STATE_RESCUE,
	ROOM_STATE_VEHICLE,
	ROOM_STATE_LEN
}

enum DmgType //=== Client Room State =========//
{
	DAMAGE_NONE,
	DAMAGE_SPAWN,
	DAMAGE_CHECKPOINT,
	DAMAGE_VEHICLE,
}

enum //=== Dummy Model ================//
{
	MDL_REFERANCE1,
	MDL_REFERANCE2,
	MDL_REFERANCE3,
	MDL_REFERANCE4,
	MDL_REFERANCE5,
	MDL_REFERANCE6,
	MDL_SENSOR,
	MDL_LENGTH
}
char g_sDummyModel[MDL_LENGTH][] =
{
	"models/props_fairgrounds/elephant.mdl",
	"models/props_fairgrounds/alligator.mdl",
	"models/props_fairgrounds/giraffe.mdl",
	"models/props_fairgrounds/mr_mustachio.mdl",
	"models/props_collectables/mushrooms.mdl",
	"models/items/l4d_gift.mdl",
	"models/editor/overlay_helper.mdl",
};

enum struct ClientManager
{
	int  iSpawnCount;
	int	 iStateRoom;
	bool bIsSoundBurn;
	bool bIsUsingDefib;
	bool bIsJoinGame;
	
	void Reset()
	{
		this.iSpawnCount 	= 0;
		this.iStateRoom 	= ROOM_STATE_OUTDOOR;
		this.bIsSoundBurn	= false;
		this.bIsUsingDefib	= false;
		this.bIsJoinGame	= true;
	}
}
ClientManager g_CMClient[MAXPLAYERS+1];

enum struct EntityManager
{
	DmgType	iDamageType;
	
	float	fPos_Spawn[3];
	float	fPos_Rescue[3];
	float	fPos_Vehicle1[3];
	float	fPos_Vehicle2[3];
	float	fBoxPos[3];
	float	fBoxAng[3];
	float	fBoxMin[3];
	float	fBoxMax[3];
	float	fCPRotate;
	bool	bIsSpawnLoaded;
	bool	bIsFinaleLoaded;
	int		iDoor_Spawn;
	int		iDoor_Rescue;
	int		iRefs_Spawn;
	int		iRefs_Rescue;
	int		iSpawnTrigger;
	int		iIndexModel;
	bool	bIsRound_Finale;
	bool	bIsFindDoorInit;
	bool	bIsVehiclReady;
	bool	bIsRoundStop;
	
	Handle	hTimer[TIMER_LENGTH];
	char	sCurrentMap[PLATFORM_MAX_PATH];
	
	void Reset()
	{
		this.fPos_Spawn			= view_as<float>({ 0.0, 0.0, 0.0 });
		this.fPos_Rescue		= view_as<float>({ 0.0, 0.0, 0.0 });
		
		this.iDoor_Spawn 		= -1;
		this.iDoor_Rescue 		= -1;
		this.iRefs_Spawn 		= -1;
		this.iRefs_Rescue 		= -1;
		this.iSpawnTrigger 		= -1;
		this.iIndexModel 		= -1;
		this.iDamageType 		= DAMAGE_NONE;
		
		this.bIsRound_Finale 	= false;
		this.bIsFindDoorInit	= false;
		this.bIsVehiclReady		= false;
		this.bIsRoundStop		= false;
		
		this.TimerKill();
	}
	
	void TimerKill()
	{
		for( int i = 0; i < TIMER_LENGTH; i++ )
		{
			delete this.hTimer[i];
		}
	}
}
EntityManager g_EMEntity;





