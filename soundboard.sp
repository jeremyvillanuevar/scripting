#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "soundboard",
    author = "",
    description = "",
    version = "0.0.1",
    url = "none"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("sounds.phrases");
        RegConsoleCmd("sm_chocolate", Cmd_chocolate, "Give chocolate to player." );
	RegConsoleCmd("sm_ds", Cmd_ds, "Refuse to disable ds." );
	RegConsoleCmd("sm_vodka", Cmd_vodka, "You Gin" );
	RegConsoleCmd("sm_gin", Cmd_gin, "I Vodka" );
	RegConsoleCmd("sm_socks", Cmd_socks, "socks" );
	RegConsoleCmd("sm_cry", Cmd_cry, "cry" );
	RegConsoleCmd("sm_hax", Cmd_hax, "HAX" );
	RegConsoleCmd("sm_parade", Cmd_parade, "parade" );
	RegConsoleCmd("sm_tickle", Cmd_tickle, "Tickle me" );
	//RegConsoleCmd("sm_fuckoff", Cmd_fuckoff, "Ban Hammer" );
	RegConsoleCmd("sm_banhammer", Cmd_banhammer, "Ban Hammer" );
	RegConsoleCmd("sm_banhammer2", Cmd_banhammer2, "Ban Hammer2" );
	RegConsoleCmd("sm_save", Cmd_save, "save" );
	RegConsoleCmd("sm_save2", Cmd_save2, "save2" );
	RegConsoleCmd("sm_lasagna", Cmd_lasagna, "I hate mondays" );
	//RegConsoleCmd("sm_fart", Cmd_fart, "Farting aha" );
	RegConsoleCmd("sm_pidor", Cmd_pidor, "pidor" );
	RegConsoleCmd("sm_steam", Cmd_steam, "I love Steam" );
	RegConsoleCmd("sm_pee", Cmd_pee, "Have to pee" );
	//RegConsoleCmd("sm_sex", Cmd_sex, "Let's do it" );
	//RegConsoleCmd("sm_sex2", Cmd_sex2, "Let's do it" );
	RegConsoleCmd("sm_license", Cmd_license, "license" );
	RegConsoleCmd("sm_license2", Cmd_license2, "license2" );
	//RegConsoleCmd("sm_bitch", Cmd_bitch, "bitch" );
	//RegConsoleCmd("sm_bitch2", Cmd_bitch2, "bitch2" );
	RegConsoleCmd("sm_easy", Cmd_easy, "easy" );
	//RegConsoleCmd("sm_orgasm", Cmd_orgasm, "mmmmh" );
	RegConsoleCmd("sm_love", Cmd_love, "Oh good morning" );
	//RegConsoleCmd("sm_anal", Cmd_anal, "Cannot believe" );
	//RegConsoleCmd("sm_anus", Cmd_anus, "shit" );
	//RegConsoleCmd("sm_bad", Cmd_bad, "bad" );
	RegConsoleCmd("sm_sugar", Cmd_sugar, "sugar" );
	RegConsoleCmd("sm_ride", Cmd_ride, "ride" );
	RegConsoleCmd("sm_sexy", Cmd_sexy, "sexy" );
	RegConsoleCmd("sm_dada", Cmd_dada, "dada" );
	RegConsoleCmd("sm_nut", Cmd_nut, "nut" );
	RegConsoleCmd("sm_nob", Cmd_nob, "nob" );
	RegConsoleCmd("sm_coconut", Cmd_coconut, "coconut" );
	//RegConsoleCmd("sm_ass", Cmd_ass, "ass" );
	RegConsoleCmd("sm_lotion", Cmd_lotion, "lotion" );
	RegConsoleCmd("sm_lotion2", Cmd_lotion2, "lotion2" );
	RegConsoleCmd("sm_smoker", Cmd_smoker, "smoker" );
	RegConsoleCmd("sm_gal", Cmd_gal, "gal" ); 
	RegConsoleCmd("sm_chicken", Cmd_chicken, "chicken" );  
	RegConsoleCmd("sm_brb", Cmd_brb, "brb" ); 
	RegConsoleCmd("sm_autobahn", Cmd_autobahn, "autobahn" ); 
	//RegConsoleCmd("sm_cheese", Cmd_cheese, "cheese" );
	RegConsoleCmd("sm_order", Cmd_order, "order" );
	//RegConsoleCmd("sm_cheese2", Cmd_cheese2, "cheese2" );
	//RegConsoleCmd("sm_cheese3", Cmd_cheese3, "cheese3" );
	//RegConsoleCmd("sm_hate", Cmd_hate, "hate" );
	//RegConsoleCmd("sm_tards", Cmd_tards, "tards" );
	RegConsoleCmd("sm_feet", Cmd_feet, "feet" );
	RegConsoleCmd("sm_gabe", Cmd_gabe, "gabe" );
	RegConsoleCmd("sm_smac", Cmd_smac, "smac" );
	RegConsoleCmd("sm_corona", Cmd_corona, "corona" );
	RegConsoleCmd("sm_corona2", Cmd_corona2, "corona2" );
	RegConsoleCmd("sm_vip", Cmd_vip, "vip" );
	RegConsoleCmd("sm_canadians", Cmd_canadians, "canadians" );
	RegConsoleCmd("sm_canada", Cmd_canada, "canada" );
	RegConsoleCmd("sm_canada2", Cmd_canada2, "canada2" );
	RegConsoleCmd("sm_canada3", Cmd_canada3, "canada3" );
	RegConsoleCmd("sm_canada4", Cmd_canada4, "canada4" );
	RegConsoleCmd("sm_charming", Cmd_charming, "charming" );
	RegConsoleCmd("sm_nice", Cmd_nice, "nice" );
	//RegConsoleCmd("sm_penis", Cmd_penis, "penis" );
	RegConsoleCmd("sm_door", Cmd_door, "door" );
	RegConsoleCmd("sm_beer", Cmd_beer, "beer" );
	RegConsoleCmd("sm_beer2", Cmd_beer2, "beer2" );
	RegConsoleCmd("sm_beer3", Cmd_beer3, "beer3" );
	RegConsoleCmd("sm_hersch", Cmd_hersch, "hersch" );
	//RegConsoleCmd("sm_moron", Cmd_moron, "moron" );
	//RegConsoleCmd("sm_moron2", Cmd_moron2, "moron2" );
	RegConsoleCmd("sm_peace", Cmd_peace, "peace" );
	RegConsoleCmd("sm_tanks", Cmd_tanks, "tanks" );
	RegConsoleCmd("sm_greta", Cmd_greta, "greta" );
	RegConsoleCmd("sm_greta2", Cmd_greta2, "greta2" );
	RegConsoleCmd("sm_aye", Cmd_aye, "aye" );
	RegConsoleCmd("sm_louis", Cmd_louis, "louis" );
	RegConsoleCmd("sm_tied", Cmd_tied, "tied" );
	RegConsoleCmd("sm_move", Cmd_move, "move" );
	RegConsoleCmd("sm_bastids", Cmd_bastids, "bastids" );
	RegConsoleCmd("sm_anything", Cmd_anything, "anything" );
	RegConsoleCmd("sm_hlp", Cmd_hlp, "hlp" );
	RegConsoleCmd("sm_poop", Cmd_poop, "poop" );
	RegConsoleCmd("sm_lasagna2", Cmd_lasagna2, "lasagna2" );
	RegConsoleCmd("sm_it", Cmd_it, "it" );
	RegConsoleCmd("sm_zombie", Cmd_zombie, "zombie" );
	RegConsoleCmd("sm_saints", Cmd_saints, "saints" );
	RegConsoleCmd("sm_xmas", Cmd_xmas, "xmas" );
	RegConsoleCmd("sm_triumph", Cmd_triumph, "triumph" );
	RegConsoleCmd("sm_firewall", Cmd_firewall, "firewall" );
	RegConsoleCmd("sm_gb", Cmd_gb, "gb" );
	RegConsoleCmd("sm_eww", Cmd_eww, "eww" );
	RegConsoleCmd("sm_fullauto", Cmd_fullauto, "fullauto" );
	RegConsoleCmd("sm_witch", Cmd_witch, "witch" );
	RegConsoleCmd("sm_niet", Cmd_niet, "niet" );
	RegConsoleCmd("sm_monkey", Cmd_monkey, "monkey" );
	RegConsoleCmd("sm_help", Cmd_help, "help" );
	RegConsoleCmd("sm_ayuda", Cmd_help, "help" );
	RegConsoleCmd("sm_hello", Cmd_hello, "hello" );
	RegConsoleCmd("sm_hola", Cmd_hello, "hello" );
	RegConsoleCmd("sm_tank", Cmd_tank, "tank" );

	RegConsoleCmd("sm_hb", Cmd_hb, "hb" );
	RegConsoleCmd("sm_sb", Cmd_soundboard, "print all commands" );
	RegConsoleCmd("sm_soundboard", Cmd_soundboard, "print all commands" );

	PrecacheSound("common\\null.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\deathscream04.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\grabbedbysmoker03a.wav");
	PrecacheSound("music\\flu\\jukebox\\all_i_want_for_xmas.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3intanktraincar07.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3firstsaferoom01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2m2finalebuttonpressgen202.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\witchgettingangry07.wav");
	PrecacheSound("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	PrecacheSound("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	PrecacheSound("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	PrecacheSound("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3intanktraincar01.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\takesubmachinegun03.wav");
	PrecacheSound("music\\flu\\jukebox\\re_your_brains.wav");
	PrecacheSound("music\\flu\\jukebox\\badman.wav");
	PrecacheSound("music\\flu\\jukebox\\midnightride.wav");
	PrecacheSound("music\\flu\\jukebox\\save_me_some_sugar_mono.wav");
	PrecacheSound("music\\flu\\jukebox\\thesaintswillnevercome.wav");
	PrecacheSound("music\\flu\\jukebox\\portal_still_alive.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\goingtodielight13.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\closethedoor07.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2hersch01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2gastanks03.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\c6dlc3intro25.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\c6dlc3billdies01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\exertioncritical01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2canadahate01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2canadahate02.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\dlc2swearcoupdegrace17.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2canadaspecial01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2canadaspecial02.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2bulletinboard02.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3secondsaferoom08.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\dlc2intro09.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3secondsaferoom09.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3jumpingoffbridge19.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\alertgiveitem09.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\youarewelcome39.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\nicejob07.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\reactionpositive27.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2riverside03.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\taunt29.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\taunt34.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom03.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\killthatlight13.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\laughter16.wav");
	PrecacheSound("ui\\pickup_secret01.wav");
	PrecacheSound("player\\tank\\voice\\yell\\hulk_yell_4.wav");
	PrecacheSound("player\\tank\\voice\\yell\\hulk_yell_7.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2bulletinboard02.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2gastanks01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2steam01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\sorry12.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\answerready05.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2m2finalebuttonpresslift01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2pilotcomment01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2pilotcomment02.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\deathscream03.wav");
	PrecacheSound("buttons\\bell1.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3intanktraincar03.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3intro14.wav");
	PrecacheSound("npc\\churchguy\\radiobutton1extended35.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3openingdoor05.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2bulletinboard01.wav");
	PrecacheSound("npc\\witch\\voice\\idle\\female_cry_2.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\hurrah18.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom13.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom11.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\heardsmoker06.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2magazinerack01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3tankintrainyard10.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3openingdoor06.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3jumpingoffbridge17.wav");
	PrecacheSound("animation\\van_inside_start.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\exertionmajor01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\exertioncritical03.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\takepipebomb04.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2misc01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\nervoushumming07.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\nervoushumming01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\nervoushumming06.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2recycling01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2recycling02.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\c6dlc3intro23.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\worldsmalltownnpcbellman07.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3communitylines04.wav");
	PrecacheSound("commentary\\com-intro.wav");
	PrecacheSound("npc\\churchguy\\radiocombatcolor02.wav");
	PrecacheSound("npc\\churchguy\\radiobutton1extended40.wav");
	PrecacheSound("npc\\churchguy\\radiobutton1extended21.wav");
	PrecacheSound("npc\\churchguy\\radiobutton1extended28.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3movieline10.wav");
	PrecacheSound("common\\bugreporter_failed.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3movieline05.wav");
	
	PrecacheSound("player\\survivor\\voice\\teengirl\\warnwitch02.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\nicejob58.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\help15.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\warntank01.wav");




}



public Action Cmd_monkey(int client,int args)
{
	Command_Play("player\\survivor\\voice\\manager\\deathscream04.wav");
	Command_Play("player\\survivor\\voice\\manager\\deathscream04.wav");
	PrintToChatAll("Excuse me?");
	return Plugin_Handled;
}

public Action Cmd_niet(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("No no no no nooooo!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\grabbedbysmoker03a.wav");
	Command_Play("player\\survivor\\voice\\teengirl\\grabbedbysmoker03a.wav");
	return Plugin_Handled;
}

public Action Cmd_xmas(int client,int args)
{

	Command_Play("music\\flu\\jukebox\\all_i_want_for_xmas.wav");
	PrintToChatAll("******************************************************");
	PrintToChatAll("HO HO HO MERRY ASSMAS!!!!");
	PrintToChatAll("******************************************************");

	return Plugin_Handled;
}
public Action Cmd_eww(int client,int args)
{

	Command_Play("player\\survivor\\voice\\manager\\c6dlc3intanktraincar07.wav");
	PrintToChatAll("******************************************************");
	PrintToChatAll("Ewww, that's some gross ass shit!!!!");
	PrintToChatAll("******************************************************");

	return Plugin_Handled;
}
public Action Cmd_gb(int client,int args)
{

	Command_Play("player\\survivor\\voice\\manager\\c6dlc3firstsaferoom01.wav");
	PrintToChatAll("******************************************************");
	PrintToChatAll("Good night!!!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}

public Action Cmd_move(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Move already you stupid ******!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2m2finalebuttonpressgen202.wav");
	return Plugin_Handled;
}
public Action Cmd_witch(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("DON'T PISS OFF THE WITCH!");
	PrintToChatAll("******************************************************");
	//Command_Play("player\\survivor\\voice\\teengirl\\witchgettingangry07.wav");
	Command_Play("player\\survivor\\voice\\teengirl\\warnwitch02.wav");
	return Plugin_Handled;
}

public Action Cmd_bastids(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("niet cry here plz");
	PrintToChatAll("******************************************************");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	return Plugin_Handled;
}

public Action Cmd_fullauto(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("S FUCKING MG!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\takesubmachinegun03.wav");
	return Plugin_Handled;
}


public Action Cmd_zombie(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("They are Zombies, Francis. ZOMBIES!");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\re_your_brains.wav");
	return Plugin_Handled;
}

public Action Cmd_bad(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("BAD MAN TG!");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\badman.wav");
	return Plugin_Handled;
}
public Action Cmd_ride(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Niet survive that ride, dude.");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\midnightride.wav");
	return Plugin_Handled;
}
public Action Cmd_sugar(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Give me some sugar, baby.");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\save_me_some_sugar_mono.wav");
	return Plugin_Handled;
}
public Action Cmd_saints(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("What's not to like?");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\thesaintswillnevercome.wav");
	return Plugin_Handled;
}

public Action Cmd_triumph(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("This was a triumph!");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\portal_still_alive.wav");
	return Plugin_Handled;
}


public Action Cmd_poop(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Taking a dump.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\goingtodielight13.wav");
	return Plugin_Handled;
}
public Action Cmd_door(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Close the FUCKING door.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\closethedoor07.wav");
	return Plugin_Handled;
}
public Action Cmd_hersch(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("o0");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2hersch01.wav");
	return Plugin_Handled;
}
public Action Cmd_vip(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("VIP = very important pidor");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2gastanks03.wav");
	return Plugin_Handled;
}
public Action Cmd_help(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("HELP = AIUDAAAA");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\help15.wav");
	return Plugin_Handled;
}

public Action Cmd_hello(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("HELLO = HOLA");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\nicejob58.wav");
	return Plugin_Handled;
}

public Action Cmd_aye(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Aye Aye Captain!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\c6dlc3intro25.wav");
	return Plugin_Handled;
}
public Action Cmd_louis(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll(":D");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\c6dlc3billdies01.wav");
	return Plugin_Handled;
}

public Action Cmd_cheese2(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("o0");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\exertioncritical01.wav");
	return Plugin_Handled;
}
public Action Cmd_canada(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I hate Canada!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2canadahate01.wav");
	return Plugin_Handled;
}
public Action Cmd_canada2(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I hate Canada!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2canadahate02.wav");
	return Plugin_Handled;
}
public Action Cmd_bitch(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("*** *** Troll ****!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\dlc2swearcoupdegrace17.wav");
	return Plugin_Handled;
}
public Action Cmd_canada3(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I hate Canada!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2canadaspecial01.wav");
	return Plugin_Handled;
}

public Action Cmd_canada4(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I hate Canada!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2canadaspecial02.wav");
	return Plugin_Handled;
}


public Action Cmd_lasagna2(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I love lasagna!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2bulletinboard02.wav");
	return Plugin_Handled;
}
public Action Cmd_it(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I know how you feel!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\c6dlc3secondsaferoom08.wav");
	return Plugin_Handled;
}
public Action Cmd_parade(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("yeah and join Francis.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\dlc2intro09.wav");
	return Plugin_Handled;
}


public Action Cmd_firewall(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("*shakes head sadly*");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\c6dlc3secondsaferoom09.wav");
	return Plugin_Handled;
}
public Action Cmd_hlp(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Help the ADMIN! HELP!!!!!!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\c6dlc3jumpingoffbridge19.wav");
	return Plugin_Handled;
}
public Action Cmd_chocolate(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Here my friend, chocolate for you! But beware, chocolate candy has plenty of saturated fat and sugar, so only enjoy small portions of it as part of a healthy diet." );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\alertgiveitem09.wav");
	return Plugin_Handled;
}
public Action Cmd_anything(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Anything?" );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\youarewelcome39.wav");
	return Plugin_Handled;
}

public Action Cmd_nice(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("THAT WAS GREAT!" );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\nicejob07.wav");
	return Plugin_Handled;
}
public Action Cmd_charming(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("0o" );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\reactionpositive27.wav ");
	return Plugin_Handled;
}
public Action Cmd_canadians(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Canadians are dicks!" );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\dlc2riverside03.wav");
	return Plugin_Handled;
}
public Action Cmd_ds(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("We LOVE ds, sorry!" );
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_vodka(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("You Gin? I Vodka!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\taunt29.wav");
	return Plugin_Handled;
}

public Action Cmd_gin(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I Vodka! You Gin?" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\taunt34.wav");
	return Plugin_Handled;
}

public Action Cmd_socks(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("... oh and how to knit socks!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom03.wav");
	return Plugin_Handled;
}

public Action Cmd_hax(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("TURN IT OFF!!!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\killthatlight13.wav");
	return Plugin_Handled;
}
public Action Cmd_tickle(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("hahaha STOP THAT!!!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\laughter16.wav");
	return Plugin_Handled;
}
public Action Cmd_fuckoff(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("The Banhammer Has Spoken!" );
	PrintToChatAll("******************************************************");
	Command_Play("ui\\pickup_secret01.wav");
	Command_Play("player\\tank\\voice\\yell\\hulk_yell_4.wav");
	return Plugin_Handled;
}
public Action Cmd_banhammer(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("STOP NOW OR FEEL THE BANHAMMER!" );
	PrintToChatAll("******************************************************");
	Command_Play("ui\\pickup_secret01.wav");
	Command_Play("player\\tank\\voice\\yell\\hulk_yell_7.wav");
	return Plugin_Handled;
}

public Action Cmd_lasagna(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I hate mondays!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2bulletinboard02.wav");
	return Plugin_Handled;
}
public Action Cmd_fart(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I fart in your general direction!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2gastanks01.wav");
	return Plugin_Handled;
}
public Action Cmd_steam(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Man I love Steam!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2steam01.wav");
	return Plugin_Handled;
}
public Action Cmd_pee(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Sorry, have to pee, brb" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\sorry12.wav");
	return Plugin_Handled;
}
public Action Cmd_sex(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\answerready05.wav");
	return Plugin_Handled;
}
public Action Cmd_sex2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2m2finalebuttonpresslift01.wav");
	return Plugin_Handled;
}
public Action Cmd_license(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2pilotcomment01.wav");
	return Plugin_Handled;
}
public Action Cmd_license2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2pilotcomment02.wav");
	return Plugin_Handled;
}
public Action Cmd_orgasm(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Oo" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\deathscream03.wav");
	return Plugin_Handled;
}
public Action Cmd_love(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Oh, good morning, going down?");
	PrintToChatAll("******************************************************");
	Command_Play("buttons\\bell1.wav");
	return Plugin_Handled;
}
public Action Cmd_anus(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("plz, clean yourself. plz");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\c6dlc3intanktraincar03.wav");
	return Plugin_Handled;
}
public Action Cmd_corona(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Sure, it's the rest of the world we can just let die");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3intro14.wav");
	return Plugin_Handled;
}
public Action Cmd_corona2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("CORONA!!!!!!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiobutton1extended35.wav");
	return Plugin_Handled;
}

public Action Cmd_anal(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I cannot believe I'm doing this!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3openingdoor05.wav");
	return Plugin_Handled;
}
public Action Cmd_sexy(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("It was my first and only visit to an allgirl's camp.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2bulletinboard01.wav");

	return Plugin_Handled;
}
public Action Cmd_cry(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("niet cry here plz");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\witch\\voice\\idle\\female_cry_2.wav");
	return Plugin_Handled;
}


public Action Cmd_dada(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Dada Spasibo!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_nut(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Don't make me get the nut-cracker!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_pidor(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("ro pidors");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_nob(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("You're a cheating doorknob!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_ass(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("It's time to kick ass and chew bubble gum and I'm all out of gum.");
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\hurrah18.wav");
	return Plugin_Handled;
}
public Action Cmd_lotion(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I hate puttin' the lotion in the basket!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom13.wav");
	return Plugin_Handled;
}
public Action Cmd_lotion2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I hate puttin' the lotion in the basket!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom11.wav");
	return Plugin_Handled;
}
public Action Cmd_smoker(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Smoker damage; Best russian invention EVER.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\heardsmoker06.wav");
	return Plugin_Handled;
}
public Action Cmd_hate(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Hate Magazine 1 - I hate DDOS.");	
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2magazinerack01.wav");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}

public Action Cmd_gal(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("No BANFUCKING way I'm doing this.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3tankintrainyard10.wav");
	return Plugin_Handled;
}
public Action Cmd_chicken(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("unFUCKING believable");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3openingdoor06.wav");
	return Plugin_Handled;
}
public Action Cmd_brb(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("1 sec. I'll be back.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3jumpingoffbridge17.wav");
	return Plugin_Handled;
}
public Action Cmd_autobahn(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("AUTOBAAAAAAAAAAAAAAAAAAHN!");
	PrintToChatAll("******************************************************");
	Command_Play("animation\\van_inside_start.wav");
	return Plugin_Handled;
}
public Action Cmd_cheese(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I'm in dire need of melted cheese!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\exertionmajor01.wav");
	return Plugin_Handled;
}
public Action Cmd_cheese3(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I'm in dire need of melted cheese!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\exertioncritical03.wav");
	return Plugin_Handled;
}
public Action Cmd_penis(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\takepipebomb04.wav");
	return Plugin_Handled;
}
public Action Cmd_easy(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("... when you're on easy street" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2misc01.wav");
	return Plugin_Handled;
}

public Action Cmd_tards(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Cards with the tards. Who could beat a night of cards, chips, dips and dorks?" );
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_smac(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("SMAC -> super moist ass crack!" );
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_hb(int client,int args)
{
        PrintToChatAll("\x04[\x03HB\x04] Placebo heartbeat sent from all clients.. but not really." );
	return Plugin_Handled;
}
public Action Cmd_beer(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("More beer!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\nervoushumming07.wav");

	return Plugin_Handled;
}
public Action Cmd_beer2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("More beer!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\nervoushumming01.wav");


	return Plugin_Handled;
}
public Action Cmd_beer3(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("More beer!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\nervoushumming06.wav");

	return Plugin_Handled;
}
public Action Cmd_greta(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("You are the Greta Thunberg of Left4Dead!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2recycling01.wav");
	return Plugin_Handled;
}
public Action Cmd_greta2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("You are the Greta Thunberg of Left4Dead!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2recycling02.wav");
	return Plugin_Handled;
}
public Action Cmd_coconut(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I hate islands!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\c6dlc3intro23.wav");
	return Plugin_Handled;
}
public Action Cmd_moron(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Don't bother talking to me. thx");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\worldsmalltownnpcbellman07.wav");
	return Plugin_Handled;
}
public Action Cmd_feet(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Tell me more bro!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\c6dlc3communitylines04.wav");
	return Plugin_Handled;
}
public Action Cmd_gabe(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I won't fix this game!");
	PrintToChatAll("******************************************************");
	Command_Play("commentary\\com-intro.wav");
	return Plugin_Handled;
}

public Action Cmd_save(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Better save than sorry!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiocombatcolor02.wav");
	return Plugin_Handled;
}
public Action Cmd_save2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Ding Dong!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiobutton1extended40.wav");
	return Plugin_Handled;
}
public Action Cmd_moron2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll(" Don't bother talking to me. thx!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiobutton1extended21.wav");
	return Plugin_Handled;
}
public Action Cmd_bitch2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("S*** Up Troll B***!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiobutton1extended28.wav");
	return Plugin_Handled;
}
public Action Cmd_order(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("ORDER! ORDEEER! OOOORDER!!!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_banhammer2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("BAAAANHAAMMMMMMERRRRRRR!!");
	PrintToChatAll("******************************************************");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	return Plugin_Handled;
}

public Action Cmd_peace(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Don't bother talking to me. thx");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\c6dlc3movieline10.wav");
	return Plugin_Handled;
}
public Action Cmd_tied(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("We LOVE tied teams message!");
	PrintToChatAll("******************************************************");
	Command_Play("common\\bugreporter_failed.wav");
	Command_Play("common\\bugreporter_failed.wav");
	Command_Play("common\\bugreporter_failed.wav");
	return Plugin_Handled;
}

public Action Cmd_tanks(int client,int args)
{
    PrintToChatAll("******************************************************");
	PrintToChatAll("Now that was one shitty tank. Punk.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\c6dlc3movieline05.wav");
	return Plugin_Handled;
}

public Action Cmd_tank(int client,int args)
{
    PrintToChatAll("******************************************************");
	PrintToChatAll("Tank.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\warntank01.wav");
	return Plugin_Handled;
}


public Action Cmd_soundboard(int client,int args)
{
        PrintToChatAll("!chocolate !lasagna !lasagna2 !vodka !gin !nut");
        //PrintToChatAll("!cheese !cheese2 !cheese3 !anal !sex !sex2 !penis !orgasm !love !tickle");
        //PrintToChatAll("!eww !cry !monkey !niet !pee !brb !poop !ass !fart");
        //PrintToChatAll("!anus !corona !corona2 !fullauto !witch !greta !greta2 !bastids");
        //PrintToChatAll("!smoker !smac !coconut !gal !bitch !bitch2");
        //PrintToChatAll("!ds !socks !hax !steam !nob !tards !smac !hate !tanks");
        PrintToChatAll("!dada !pidor !nice !charming !lotion !lotion2 !chicken !parade");
        //PrintToChatAll("!it !firewall !autobahn !beer !beer2 !beer3 !moron !moron2 !peace");
        PrintToChatAll("!canadians !canada !canada2 !canada3 !canada4 ");
	PrintToChatAll("!license !license2 !sexy !aye !louis !hlp !tied !door !gb ");
	PrintToChatAll("!save !save2 !easy !order !feet !anything !vip !move !hersch");
	//PrintToChatAll("!sugar !ride !bad !zombie !saints !triumph !xmas !gabe");
        //PrintToChatAll("!fuckoff !banhammer !banhammer2 !soundboard");
	PrintToChatAll("!help !hello !tank !hola !ayuda");
	return Plugin_Handled;
}



public Action Command_Play(const char[] arguments)
{

	for(int i=1; i<=MaxClients; i++)
	{
		if( !IsClientInGame(i) )
		continue;
     	  	ClientCommand(i, "playgamesound %s", arguments);
		//PrintToChatAll("*************************2*****************************");

	}  
	//return Plugin_Handled;
}


