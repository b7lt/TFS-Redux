/*
	Team Fortress Sandbox Redux (TFS Redux)
	Coded by bolt

	CREDITS:
	- KTM: He coded the original TFS Plugin that was developed for the {SuN} and {SuN} Revived servers.
	- chundo: His 'Help Menu' plugin helped me learn how to use config files to create menus.
	- Xeon: Owner of Neogenesis Network. Although he didn't help me in this project, he's helped me in the past with my development adventures. This guy is awesome.
	- The {SuN} Community and Staff: For being part of the best gaming community I've ever been in. ALL of you are awesome!

	Improvements upon the origin:
	- No more hardcoded prop lists. Now, you can add and remove props via proplist.cfg
	- TFS Admin Menu (WIP)
	- Now public
	- More coming soon.
*/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.1"

//Defines for sounds
#define SOUND_SPAWN "buttons/lightswitch2.wav"
#define SOUND_DELETE "physics/plaster/drywall_impact_hard1.wav"
#define SOUND_MANIPSAVE "physics/plaster/ceiling_tile_impact_bullet2.wav"
#define SOUND_MANIPDISCARD "physics/plaster/ceiling_tile_impact_bullet3.wav"
#define SOUND_PAINT "physics/flesh/flesh_squishy_impact_hard2.wav"
#define SOUND_EDIT "items/flashlight1.wav"

enum ChatCommand {
	String:command[32],
	String:description[255]
}

enum PropMenuType {
	PropMenuType_List,
	PropMenuType_Text
}

enum PropMenu {
	String:name[32],
	String:title[128],
	PropMenuType:type,
	Handle:items,
	itemct
}

public Plugin:myinfo = 
{
	name = "TFS Redux",
	author = "bolt",
	description = "Rewritten and improved Team Fortress Sandbox",
	version = PLUGIN_VERSION,
	url = "https://bolts.dev/"
}
//Defines for sounds
#define SOUND_SPAWN "buttons/lightswitch2.wav"
// CVars
//new Handle:g_cvarWelcome = INVALID_HANDLE;

// Prop menus
new Handle:g_PropMenus = INVALID_HANDLE;

//prop states
new g_iOwner[4096];
new bool:g_bKillProp[4096];
new g_iPropCount[MAXPLAYERS+1];
new g_iLastProp[MAXPLAYERS+1];
new g_iSelectedProp[MAXPLAYERS+1];

//manipulate
new Float:g_vecLockedAng[MAXPLAYERS+1][3];
new Float:g_vecSelectedPropPrevPos[MAXPLAYERS+1][3];
new Float:g_vecSelectedPropPrevAng[MAXPLAYERS+1][3];

// Config parsing
new g_configLevel = -1;

// Textures
new g_iBeamIndex;
new g_BeamSprite;
new g_HaloSprite;

public OnPluginStart() {
	CreateConVar("sm_propmenu_version", PLUGIN_VERSION, "Prop menu version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
//	g_cvarWelcome = CreateConVar("sm_propmenu_welcome", "1", "Show welcome message to newly connected users.", FCVAR_PLUGIN);
	RegConsoleCmd("sm_tfs", Command_TFSMenu, "Open the TFS Menu", FCVAR_PLUGIN);

	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/TFS/proplist.cfg");
	ParseConfigFile(hc);

	AutoExecConfig(false);
}

public OnMapStart() {
	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/TFS/proplist.cfg");
	ParseConfigFile(hc);
	g_BeamSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_iBeamIndex = PrecacheModel("materials/sprites/purplelaser1.vmt");

	PrecacheSound(SOUND_SPAWN);
	PrecacheSound(SOUND_DELETE);
	PrecacheSound(SOUND_MANIPSAVE);
	PrecacheSound(SOUND_MANIPDISCARD);
	PrecacheSound(SOUND_PAINT);
	PrecacheSound(SOUND_EDIT);
}

/*
public OnClientPutInServer(client) {
	if (GetConVarBool(g_cvarWelcome))
		CreateTimer(30.0, Timer_WelcomeMessage, client);
}


public Action:Timer_WelcomeMessage(Handle:timer, any:client) {
	if (GetConVarBool(g_cvarWelcome) && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "\x01[SM] For Prop, type \x04!PropMenu\x01 in chat");
}
*/

bool:ParseConfigFile(const String:file[]) {
	if (g_PropMenus != INVALID_HANDLE) {
		ClearArray(g_PropMenus);
		CloseHandle(g_PropMenus);
		g_PropMenus = INVALID_HANDLE;
	}

	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	new line = 0;
	new col = 0;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if (result != SMCError_Okay) {
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) {
	g_configLevel++;
	if (g_configLevel == 1) {
		new hmenu[PropMenu];
		strcopy(hmenu[name], sizeof(hmenu[name]), section);
		hmenu[items] = CreateDataPack();
		hmenu[itemct] = 0;
		if (g_PropMenus == INVALID_HANDLE)
			g_PropMenus = CreateArray(sizeof(hmenu));
		PushArrayArray(g_PropMenus, hmenu[0]);
	}
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) {
	new msize = GetArraySize(g_PropMenus);
	new hmenu[PropMenu];
	GetArrayArray(g_PropMenus, msize-1, hmenu[0]);
	switch (g_configLevel) {
		case 1: {
			if(strcmp(key, "title", false) == 0)
				strcopy(hmenu[title], sizeof(hmenu[title]), value);
			if(strcmp(key, "type", false) == 0) {
				if(strcmp(value, "text", false) == 0)
					hmenu[type] = PropMenuType_Text;
				else
					hmenu[type] = PropMenuType_List;
			}
		}
		case 2: {
			WritePackString(hmenu[items], key);
			WritePackString(hmenu[items], value);
			hmenu[itemct]++;
		}
	}
	SetArrayArray(g_PropMenus, msize-1, hmenu[0]);
	return SMCParse_Continue;
}
public SMCResult:Config_EndSection(Handle:parser) {
	g_configLevel--;
	if (g_configLevel == 1) {
		new hmenu[PropMenu];
		new msize = GetArraySize(g_PropMenus);
		GetArrayArray(g_PropMenus, msize-1, hmenu[0]);
		ResetPack(hmenu[items]);
	}
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {
	if (failed)
		SetFailState("Plugin configuration error");
}

public Action:Command_TFSMenu(client, args) {
	TFS_ShowMainMenu(client);
	return Plugin_Handled;
}

TFS_ShowMainMenu(client)
{
	new Handle:menu = CreateMenu(TFS_MainMenuHandler);
	SetMenuExitBackButton(menu, false);
	SetMenuTitle(menu, "TFS Redux V0.1 ALPHA\n ");
	AddMenuItem(menu, "props", "Prop Spawner");
	AddMenuItem(menu, "manip", "Manipulate Menu")
	DisplayMenu(menu, client, 30);
}

public TFS_MainMenuHandler(Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	} 
	else if (action == MenuAction_Select) 
	{
		new String:item[64];
		GetMenuItem(menu, param2, item, sizeof(item));
		if (StrEqual(item, "props"))
		{
			TFS_ShowPropMenu(param1);
		}
		else if (StrEqual(item, "manip"))
		{
			TFS_ManipMenu(param1);
		}
	}
}

TFS_ShowPropMenu(client) {
	new Handle:menu = CreateMenu(TFS_PropMenuHandler);
	SetMenuTitle(menu, "TFS Redux - Prop Spawn Menu (Your Count: %i)", g_iPropCount[client]);
	new msize = GetArraySize(g_PropMenus);
	new hmenu[PropMenu];
	new String:menuid[10];
	for (new i = 0; i < msize; ++i) {
		Format(menuid, sizeof(menuid), "PropMenu_%d", i);
		GetArrayArray(g_PropMenus, i, hmenu[0]);
		AddMenuItem(menu, menuid, hmenu[name]);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public TFS_PropMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu); }
	else if(action == MenuAction_Cancel) {
		TFS_ShowMainMenu(param1); }
	else if (action == MenuAction_Select) {
		new String:buf[64];
		new msize = GetArraySize(g_PropMenus);
		// Menu from config file
		if (param2 <= msize) {
				new hmenu[PropMenu];
				GetArrayArray(g_PropMenus, param2, hmenu[0]);
				new String:mtitle[512];
				Format(mtitle, sizeof(mtitle), "%s\n ", hmenu[title]);
				if (hmenu[type] == PropMenuType_Text) {
					new Handle:cpanel = CreatePanel();
					SetPanelTitle(cpanel, mtitle);
					new String:text[128];
					new String:junk[128];
					for (new i = 0; i < hmenu[itemct]; ++i) {
						ReadPackString(hmenu[items], junk, sizeof(junk));
						ReadPackString(hmenu[items], text, sizeof(text));
						DrawPanelText(cpanel, text);
					}
					for (new j = 0; j < 7; ++j)
					DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					DrawPanelText(cpanel, " ");
					DrawPanelItem(cpanel, "Back", ITEMDRAW_CONTROL);
					DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					DrawPanelText(cpanel, " ");
					DrawPanelItem(cpanel, "Exit", ITEMDRAW_CONTROL);
					ResetPack(hmenu[items]);
					SendPanelToClient(cpanel, param1, TFS_MenuHandler, 30);
					CloseHandle(cpanel);
				} else {
					new Handle:cmenu = CreateMenu(TFS_CustomMenuHandler);
					SetMenuExitBackButton(cmenu, true);
					SetMenuTitle(cmenu, mtitle);
					new String:cmd[128];
					new String:desc[128];
					for (new i = 0; i < hmenu[itemct]; ++i) {
						ReadPackString(hmenu[items], cmd, sizeof(cmd));
						ReadPackString(hmenu[items], desc, sizeof(desc));
						new drawstyle = ITEMDRAW_DEFAULT;
						if (strlen(cmd) == 0)
							drawstyle = ITEMDRAW_DISABLED;
						AddMenuItem(cmenu, cmd, desc, drawstyle);
					}
					ResetPack(hmenu[items]);
					DisplayMenu(cmenu, param1, 30);
			}
		}
	}
}


public TFS_MenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (menu == INVALID_HANDLE && action == MenuAction_Select && param2 == 8) {
		TFS_ShowPropMenu(param1);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack)
			TFS_ShowPropMenu(param1);
	}
}

public TFS_CustomMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		new String:itemval[512];
		GetMenuItem(menu, param2, itemval, sizeof(itemval));
		if (strlen(itemval) > 0)
		{
			if((g_iPropCount[param1] >= 100) && !(GetUserFlagBits(param1) & ADMFLAG_ROOT))
				{
					PrintToChat(param1, "You can't spawn any more props. Delete Some to spawn more!");
					TFS_ShowMainMenu(param1);
					return;
				}
			PrintToChatAll(itemval)
			//FakeClientCommand(param1, itemval);
			decl ent;
			new Float:AbsAngles[3], Float:ClientOrigin[3], Float:Origin[3], Float:pos[3], Float:beampos[3], Float:PropOrigin[3], Float:EyeAngles[3];
						
			GetClientAbsOrigin(param1, ClientOrigin);
			GetClientEyeAngles(param1, EyeAngles);
			GetClientAbsAngles(param1, AbsAngles);
				
			GetCollisionPoint(param1, pos);
				
			PropOrigin[0] = pos[0];
			PropOrigin[1] = pos[1];
			PropOrigin[2] = (pos[2] + 0);
				
			beampos[0] = pos[0];
			beampos[1] = pos[1];
			beampos[2] = (PropOrigin[2] + 10);
				
			//Spawn ent:
			ent = CreateEntityByName("prop_dynamic_override");
			TeleportEntity(ent, PropOrigin, AbsAngles, NULL_VECTOR);
			DispatchKeyValue(ent, "model", itemval);
			DispatchKeyValue(ent, "solid","6");
			DispatchSpawn(ent);
			SetEntityRenderMode(ent, RENDER_TRANSALPHA);
			ActivateEntity(ent);
			g_iOwner[ent] = param1;
			g_iPropCount[param1]++;
			g_iLastProp[param1] = ent;
				
			//Send BeamRingPoint:
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", Origin);
			TE_SetupBeamRingPoint(PropOrigin, 10.0, 150.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, {236, 150, 55, 200}, 20, 0);
			TE_SendToAll();
			EmitSoundToClient(param1, SOUND_SPAWN, _, _, _, _, _, 50);

			//anti-stuck protection
/*			for (new i=1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i))
					if (IsStuckInEnt(i, ent))
					{
						PrintToChat(client, "\x01You cannot build on \x04Players!");
						DeleteProp(ent);
						break;
					} */
			TFS_ShowPropMenu(param1);
		}
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack)
			TFS_ShowPropMenu(param1);
	}
}

stock GetCollisionPoint(client, Float:pos[3])
{
	decl Float:vOrigin[3], Float:vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return;
	}
	CloseHandle(trace);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients;
}

///////////////////
/*Manipulate Menu*/
///////////////////

//Manipulate Menu
TFS_ManipMenu(client)
{
	new target = GetClientAimTarget(client, false);
	if(CanModifyProp(client, target))
	{
		//menu chunk
		g_iSelectedProp[client] = target;
		GetEntPropVector(g_iSelectedProp[client], Prop_Data, "m_angRotation", g_vecSelectedPropPrevAng[client]);
		GetEntPropVector(g_iSelectedProp[client], Prop_Data, "m_vecOrigin", g_vecSelectedPropPrevPos[client]);
		GetClientEyeAngles(client, g_vecLockedAng[client]);
		SDKHook(client, SDKHook_PreThink, PropManip);
		SetEntityMoveType(client, MOVETYPE_NONE);
		
		//prevents unable to re-grab prop after grab. 
		SetEntProp(target, Prop_Send, "m_nSolidType", 6);
		
		//draw menu
		new Handle:menu = CreateMenu(Menu_Manip);
		SetMenuTitle(menu, "WASD Moves The Prop | Jump or Duck moves Up or Down | Alt-Fire Rotates");
		
		AddMenuItem(menu, "1", "Save Your Changes");
		AddMenuItem(menu, "2", "Discard Your Changes");
		
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, client, 720);
	}
}

//Manipulate Menu options
public Menu_Manip(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		SDKUnhook(client, SDKHook_PreThink, PropManip);
		SetEntityMoveType(client, MOVETYPE_WALK);
		EmitSoundToClient(client, SOUND_MANIPSAVE, _, _, _, _, _, 50);
		TFS_ShowMainMenu(client);
		
		if(option == 1)
		TeleportEntity(g_iSelectedProp[client], g_vecSelectedPropPrevPos[client], g_vecSelectedPropPrevAng[client], NULL_VECTOR);
		EmitSoundToClient(client, SOUND_MANIPDISCARD, _, _, _, _, _, 50);
	}
	else if(action == MenuAction_Cancel)
		TFS_ShowMainMenu(client);
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

//Manipulate Funcitonality
public PropManip(client)
{
	decl Float:pos[3], Float:ang[3], Float:pAng[3], Float:pPos[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);
	//g_iSelectedProp[client] = target;
	GetEntPropVector(g_iSelectedProp[client], Prop_Data, "m_angRotation", pAng);
	GetEntPropVector(g_iSelectedProp[client], Prop_Data, "m_vecOrigin", pPos);
	new btns = GetClientButtons(client);
	
	pos[2] -= 32.0;
	
	//Beam for manipulation
	TE_SetupBeamPoints(pos, pPos, g_iBeamIndex, 0, 0, 0, 0.1, 4.0, 8.0, 0, 0.0, {236, 150, 55, 200}, 0);
	TE_SendToAll(0.0);

	//up + down
	if(btns & IN_JUMP)
	{
		pPos[2] += 1.0;
	}
	else if(btns & IN_DUCK)
	{
		pPos[2] -= 1.0;
	}	
	// left + right
	if(btns & IN_MOVELEFT)
	{
		pPos[0] -= 1.0;
	}
	else if(btns & IN_MOVERIGHT)
	{
		pPos[0] += 1.0;
	}
	
	// forward + backward
	if(btns & IN_FORWARD)
	{
		pPos[1] += 1.0;
	}
	else if(btns & IN_BACK)
	{
		pPos[1] -= 1.0;
	}
	
	//Rotation
	if(btns & IN_ATTACK2)
	{
		for(new i=0; i<=2; i++)
		{
			new change = RoundToNearest(g_vecLockedAng[client][i] - ang[i]);
			pAng[i] += float(change);
		}
		TeleportEntity(client, NULL_VECTOR, g_vecLockedAng[client], NULL_VECTOR);
	}
	else
	{
		GetClientEyeAngles(client, g_vecLockedAng[client]);
	}
	
	//apply modifications
	TeleportEntity(g_iSelectedProp[client], pPos, pAng, NULL_VECTOR);	
}

///////////////////
/*Gameplay Basics*/
///////////////////

//checks if in spec
stock bool:g_bIsClientSpec(client)
{
	return GetClientTeam(client)<2;
}

//ownership checker
bool:CanModifyProp(client, prop)
{
	if(prop <= GetMaxClients())
	{
		PrintToChat(client, "Not a valid prop!");
		return false;
	}
	if(g_iOwner[prop] != client)
	{
		PrintToChat(client, "You don't own this prop!");
		return false;
	}
	return true;
}