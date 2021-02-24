#pragma semicolon 1
#include <sourcemod>

bool bStop, bCannotDie[MAXPLAYERS+1];

public void OnPluginStart()
{
    HookEvent("round_start", OnRoundStart);
    
    HookEvent("round_end", OnRoundEvents);
    HookEvent("finale_win", OnRoundEvents);
    HookEvent("mission_lost", OnRoundEvents);
    HookEvent("map_transition", OnRoundEvents);
}

public void OnPluginEnd()
{
    UnhookEvent("round_start", OnRoundStart);
    
    UnhookEvent("round_end", OnRoundEvents);
    UnhookEvent("finale_win", OnRoundEvents);
    UnhookEvent("mission_lost", OnRoundEvents);
    UnhookEvent("map_transition", OnRoundEvents);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i))
        {
            if (!bCannotDie[i])
            {
                continue;
            }
            
            bCannotDie[i] = false;
            
            SetEntProp(i, Prop_Data, "m_fFlags", GetEntProp(i, Prop_Data, "m_fFlags") & ~FL_GODMODE);
            SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
        }
    }
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    bStop = false;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            bCannotDie[i] = false;
        }
    }
    
    CreateTimer(1.0, CheckForHumanPlayers, _, TIMER_REPEAT);
}

public Action CheckForHumanPlayers(Handle timer)
{
    if (bStop)
    {
        return Plugin_Stop;
    }
    
    if (GetHumanCount() < 1)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i))
            {
                if (bCannotDie[i])
                {
                    continue;
                }
                
                bCannotDie[i] = true;
                
                SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
                SetEntProp(i, Prop_Data, "m_fFlags", GetEntProp(i, Prop_Data, "m_fFlags") | FL_GODMODE);
            }
        }
    }
    else
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i))
            {
                if (!bCannotDie[i])
                {
                    continue;
                }
                
                bCannotDie[i] = false;
                
                SetEntProp(i, Prop_Data, "m_fFlags", GetEntProp(i, Prop_Data, "m_fFlags") & ~FL_GODMODE);
                SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
            }
        }
    }
    return Plugin_Continue;
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
    if (!bStop)
    {
        bStop = true;
    }
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i))
        {
            if (!bCannotDie[i])
            {
                continue;
            }
            
            bCannotDie[i] = false;
            
            SetEntProp(i, Prop_Data, "m_fFlags", GetEntProp(i, Prop_Data, "m_fFlags") & ~FL_GODMODE);
            SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
        }
    }
}

int GetHumanCount()
{
    int iCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            iCount += 1;
        }
    }
    return iCount;
} 