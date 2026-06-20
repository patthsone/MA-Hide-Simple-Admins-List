#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <materialadmin>
#include <vip_core>
#include <ma_hide.inc>

new bool:g_bHide[MAXPLAYERS + 1];
new bool:g_bChangingTeam[MAXPLAYERS + 1];
new bool:g_bVipCoreLoaded;

new bool:g_bHasTeamProp;
new bool:g_bHasConnectedProp;
new g_iResourceEntity = -1;

public Plugin:myinfo =
{
    name = "[MA] Hide",
    author = "PattHs",
    description = "MA Hide",
    version = "1.0.3",
    url = "https://discord.gg/r9xZUwxjh6"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("MA_IsClientHidden", Native_IsClientHidden);
    MarkNativeAsOptional("VIP_IsClientVIP");
    MarkNativeAsOptional("VIP_GetClientVIPGroup");
    MarkNativeAsOptional("VIP_GetClientAccessTime");
    RegPluginLibrary("ma_hide");
    return APLRes_Success;
}

public int Native_IsClientHidden(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 1 || client > MaxClients)
        return false;
    return g_bHide[client];
}

public OnPluginStart()
{
    LoadTranslations("ma_hide.phrases");

    RegConsoleCmd("sm_hide", Command_Hide);
    AddCommandListener(Command_JoinTeam, "jointeam");
    AddCommandListener(Command_Vips, "sm_vips");
    AddCommandListener(Command_Vips, "sm_viplist");
    AddCommandListener(Command_Vips, "sm_випс");

    CreateTimer(0.1, Timer_UpdateHidden, _, TIMER_REPEAT);
    UpdateVipCoreStatus();
}

public OnAllPluginsLoaded()
{
    UpdateVipCoreStatus();
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "vip_core"))
    {
        UpdateVipCoreStatus();
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "vip_core"))
    {
        g_bVipCoreLoaded = false;
    }
}

public OnEntityCreated(entity, const String:classname[])
{
    if (!StrEqual(classname, "cs_player_manager"))
        return;

    g_iResourceEntity = entity;

    SDKHook(entity, SDKHook_ThinkPost, ResourceThinkPost);

    g_bHasTeamProp =
    (
        GetEntSendPropOffs(entity, "m_iTeam") != -1 ||
        GetEntSendPropOffs(entity, "m_iTeamNum") != -1
    );

    g_bHasConnectedProp =
    (
        GetEntSendPropOffs(entity, "m_bConnected") != -1
    );

    PrintToServer(
        "[MA Hide] cs_player_manager created (%d). Team: %s | Connected: %s",
        entity,
        g_bHasTeamProp ? "YES" : "NO",
        g_bHasConnectedProp ? "YES" : "NO"
    );
}

public OnEntityDestroyed(entity)
{
    if (entity == g_iResourceEntity)
    {
        g_iResourceEntity = -1;
        PrintToServer("[MA Hide] cs_player_manager destroyed.");
    }
}

public ResourceThinkPost(entity)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        if (!g_bHide[i])
            continue;

        SetHiddenProps(i, true);
    }
}

public Action:Timer_UpdateHidden(Handle:timer)
{
    if (g_iResourceEntity == -1 || !IsValidEntity(g_iResourceEntity))
        return Plugin_Continue;

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && g_bHide[i])
        {
            SetHiddenProps(i, true);
        }
    }

    return Plugin_Continue;
}

SetHiddenProps(client, bool:hide)
{
    if (g_iResourceEntity == -1 || !IsValidEntity(g_iResourceEntity))
        return;

    new team = hide ? 0 : GetClientTeam(client);
    new connected = hide ? 0 : 1;

    if (g_bHasTeamProp)
    {
        new offs = GetEntSendPropOffs(g_iResourceEntity, "m_iTeam");

        if (offs != -1)
        {
            SetEntProp(g_iResourceEntity, Prop_Send, "m_iTeam", team, 4, client);
        }
        else
        {
            offs = GetEntSendPropOffs(g_iResourceEntity, "m_iTeamNum");

            if (offs != -1)
            {
                SetEntProp(g_iResourceEntity, Prop_Send, "m_iTeamNum", team, 4, client);
            }
        }
    }

    if (g_bHasConnectedProp)
    {
        SetEntProp(g_iResourceEntity, Prop_Send, "m_bConnected", connected, 1, client);
    }
}

public OnClientDisconnect(client)
{
    if (g_bHide[client])
    {
        StopHide(client);
    }

    g_bHide[client] = false;
    g_bChangingTeam[client] = false;
}

public OnClientPutInServer(client)
{
    g_bHide[client] = false;
    g_bChangingTeam[client] = false;
}

public Action:Command_JoinTeam(client, const String:command[], argc)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Continue;

    if (g_bChangingTeam[client])
        return Plugin_Continue;

    if (g_bHide[client])
    {
        StopHide(client);

        ChangeClientTeam(client, CS_TEAM_SPECTATOR);

        PrintToChat(client, "[MA] Hide disabled.");

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action:Command_Hide(client, args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;

    if (GetUserAdmin(client) == INVALID_ADMIN_ID)
        return Plugin_Handled;

    if (g_bHide[client])
    {
        StopHide(client);

        ChangeClientTeam(client, CS_TEAM_SPECTATOR);

        PrintToChat(client, "[MA] Hide disabled.");
    }
    else
    {
        g_bHide[client] = true;

        new Handle:pack = CreateDataPack();

        WritePackCell(pack, GetClientUserId(client));

        CreateTimer(0.1, Timer_HideOn, pack);

        PrintToChat(client, "[MA] Hide enabled.");
    }

    return Plugin_Handled;
}

public Action:Command_Vips(client, const String:command[], argc)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Continue;

    UpdateVipCoreStatus();

    if (!g_bVipCoreLoaded)
        return Plugin_Continue;

    ShowVipsMenu(client);
    return Plugin_Handled;
}

ShowVipsMenu(client)
{
    new Handle:menu = CreateMenu(Handler_VipsMenu);
    new String:name[MAX_NAME_LENGTH];
    new String:userId[16];
    new bool:hasItems = false;

    SetMenuTitle(menu, "VIP-игроки онлайн:\n \n");

    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;

        if (g_bHide[i])
            continue;

        if (!VIP_IsClientVIP(i))
            continue;

        if (!GetClientName(i, name, sizeof(name)))
            continue;

        IntToString(GetClientUserId(i), userId, sizeof(userId));
        AddMenuItem(menu, userId, name);
        hasItems = true;
    }

    if (!hasItems)
    {
        AddMenuItem(menu, "", "VIP-игроков онлайн нет", ITEMDRAW_DISABLED);
    }

    DisplayMenu(menu, client, 30);
}

public Handler_VipsMenu(Handle:menu, MenuAction:action, client, item)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Select)
    {
        new String:userId[16];
        GetMenuItem(menu, item, userId, sizeof(userId));

        new target = GetClientOfUserId(StringToInt(userId));

        if (!target || !IsClientInGame(target) || g_bHide[target] || !g_bVipCoreLoaded || !VIP_IsClientVIP(target))
        {
            ShowVipsMenu(client);
            return;
        }

        ShowVipInfoPanel(client, target);
    }
}

ShowVipInfoPanel(client, target)
{
    new Handle:panel = CreatePanel();
    new String:buffer[128];

    SetPanelTitle(panel, "Информация\n \n");

    DrawPanelText(panel, "Группа:");

    if (VIP_GetClientVIPGroup(target, buffer, sizeof(buffer)) && buffer[0])
    {
        DrawPanelText(panel, buffer);
    }
    else
    {
        DrawPanelText(panel, "Неизвестно");
    }

    DrawPanelText(panel, " \n");
    DrawPanelText(panel, "Истекает:");

    new expire = VIP_GetClientAccessTime(target);

    if (expire == -1)
    {
        DrawPanelText(panel, "Временно");
    }
    else if (expire == 0)
    {
        DrawPanelText(panel, "Никогда");
    }
    else
    {
        FormatVipTime(expire - GetTime(), buffer, sizeof(buffer));
        DrawPanelText(panel, buffer);
    }

    DrawPanelText(panel, " \n");

    SetPanelCurrentKey(panel, 8);
    DrawPanelItem(panel, "Назад", ITEMDRAW_CONTROL);

    DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

    SetPanelCurrentKey(panel, 10);
    DrawPanelItem(panel, "Выход", ITEMDRAW_CONTROL);

    SendPanelToClient(panel, client, Handler_VipInfoPanel, 30);
    CloseHandle(panel);
}

public Handler_VipInfoPanel(Handle:panel, MenuAction:action, client, item)
{
    if (action == MenuAction_Select && item == 8)
    {
        ShowVipsMenu(client);
    }
}

FormatVipTime(seconds, String:buffer[], maxlen)
{
    if (seconds <= 0)
    {
        FormatEx(buffer, maxlen, "Истекло");
        return;
    }

    new days = seconds / 86400;
    new hours = (seconds % 86400) / 3600;
    new minutes = (seconds % 3600) / 60;

    if (days > 0)
    {
        FormatEx(buffer, maxlen, "%d д. %d ч.", days, hours);
    }
    else if (hours > 0)
    {
        FormatEx(buffer, maxlen, "%d ч. %d мин.", hours, minutes);
    }
    else
    {
        FormatEx(buffer, maxlen, "%d мин.", minutes);
    }
}

UpdateVipCoreStatus()
{
    g_bVipCoreLoaded = LibraryExists("vip_core") && GetFeatureStatus(FeatureType_Native, "VIP_IsClientVIP") == FeatureStatus_Available;
}

public Action:Timer_HideOn(Handle:timer, Handle:pack)
{
    ResetPack(pack);

    new userid = ReadPackCell(pack);

    new client = GetClientOfUserId(userid);

    if (!client || !IsClientInGame(client))
        return Plugin_Stop;

    if (IsPlayerAlive(client))
    {
        ForcePlayerSuicide(client);
    }

    g_bChangingTeam[client] = true;

    ChangeClientTeam(client, CS_TEAM_SPECTATOR);

    g_bChangingTeam[client] = false;

    SetHiddenProps(client, true);

    SDKHook(client, SDKHook_SetTransmit, OnSetTransmit);

    return Plugin_Stop;
}

public Action:OnSetTransmit(entity, client)
{
    if (entity == client)
        return Plugin_Continue;

    if (entity >= 1 &&
        entity <= MaxClients &&
        IsClientInGame(entity) &&
        g_bHide[entity])
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

StopHide(client)
{
    g_bHide[client] = false;

    SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmit);

    SetHiddenProps(client, false);
}
