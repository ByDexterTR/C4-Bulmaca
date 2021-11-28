#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <warden>

#pragma semicolon 1
#pragma newdecls required

bool GameStart = false;
bool Buldu[65] = { false, ... };
int C4 = 0;

public Plugin myinfo = 
{
	name = "C4 Bulmaca", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	PrecacheModel("models/weapons/w_c4_planted.mdl");
	RegConsoleCmd("sm_c4", Command_C4Bulmaca, "");
	RegConsoleCmd("sm_c4bulmaca", Command_C4Bulmaca, "");
	RegConsoleCmd("sm_c4bul", Command_C4Bulmaca, "");
	RegConsoleCmd("sm_c4sakla", Command_C4Bulmaca, "");
	RegAdminCmd("c4bulmaca_flag", Check_flag, ADMFLAG_ROOT, "");
}

public void OnPluginEnd()
{
	GameStart = false;
	C4 = 0;
	char modelname[16];
	for (int i = MaxClients; i < GetMaxEntities(); i++)if (IsValidEdict(i) && IsValidEntity(i))
	{
		GetEntPropString(i, Prop_Data, "m_iName", modelname, 16);
		if (strcmp(modelname, "saklanbac_c4") == 0)
			RemoveEntity(i);
	}
}

public void OnMapStart()
{
	GameStart = false;
	C4 = 0;
	char modelname[16];
	for (int i = MaxClients; i < GetMaxEntities(); i++)if (IsValidEdict(i) && IsValidEntity(i))
	{
		GetEntPropString(i, Prop_Data, "m_iName", modelname, 16);
		if (strcmp(modelname, "saklanbac_c4") == 0)
			RemoveEntity(i);
	}
}

public Action Check_flag(int client, int args)
{
	ReplyToCommand(client, "[SM] !c4bul komutuna erişiminiz var.");
	return Plugin_Handled;
}

public Action Command_C4Bulmaca(int client, int args)
{
	if (warden_iswarden(client) || CheckCommandAccess(client, "c4bulmaca_flag", ADMFLAG_ROOT))
	{
		C4BulmacaMenu().Display(client, 0);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

Menu C4BulmacaMenu()
{
	Menu menu = new Menu(Menu_CallBack);
	menu.SetTitle("★ C4 Bulmaca ★\n★ C4: %d ★\n ", C4);
	if (!GameStart)
		menu.AddItem("1", "> Oyunu başlat");
	else
		menu.AddItem("1", "> Oyunu durdur");
	
	if (!GameStart)
	{
		menu.AddItem("2", "> C4'ü Yerleştir");
		menu.AddItem("3", "> C4'ü Sil");
	}
	else
	{
		menu.AddItem("2", "> C4'ü Yerleştir", ITEMDRAW_DISABLED);
		menu.AddItem("3", "> C4'ü Sil", ITEMDRAW_DISABLED);
	}
	return menu;
}

public int Menu_CallBack(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[8];
		menu.GetItem(position, item, sizeof(item));
		int dize = StringToInt(item);
		if (dize == 1)
		{
			if (C4 == 0)
			{
				PrintToChat(client, "[SM] \x07Hiç C4 saklanmamış.");
			}
			else if (GameStart)
			{
				char modelname[16];
				for (int i = MaxClients; i < GetMaxEntities(); i++)if (IsValidEdict(i) && IsValidEntity(i))
				{
					GetEntPropString(i, Prop_Data, "m_iName", modelname, 16);
					if (strcmp(modelname, "saklanbac_c4") == 0)
						RemoveEntity(i);
				}
				C4 = 0;
				GameStart = false;
				PrintToChatAll("[SM] \x04%N\x01 C4 bulmacayı \x07durdurdu.", client);
				for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
				{
					Buldu[i] = false;
				}
			}
			else
			{
				PrintToChatAll("[SM] \x04%N\x01 C4 bulmacayı \x05başlattı.", client);
				PrintToChatAll("[SM] Toplam \x04%d\x01 C4 saklanmış", C4);
				for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
				{
					Buldu[i] = false;
					if (IsPlayerAlive(i) && GetClientTeam(i) == 2)
						CS_RespawnPlayer(i);
				}
				GameStart = true;
			}
		}
		else if (dize == 2)
		{
			if (!GameStart)
			{
				float location[3];
				GetAimCoords(client, location);
				location[2] += 24.0;
				int c4 = CreateEntityByName("prop_physics_multiplayer");
				DispatchKeyValue(c4, "model", "models/weapons/w_c4_planted.mdl");
				DispatchKeyValue(c4, "physicsmode", "1");
				DispatchKeyValue(c4, "nodamageforces", "1");
				DispatchKeyValue(c4, "spawnflags", "2");
				SetEntProp(c4, Prop_Send, "m_CollisionGroup", 0);
				SetEntPropString(c4, Prop_Data, "m_iName", "saklanbac_c4");
				DispatchSpawn(c4);
				SDKHook(c4, SDKHook_SetTransmit, SetTransmit);
				TeleportEntity(c4, location, NULL_VECTOR, NULL_VECTOR);
				C4++;
				if (warden_iswarden(client) || CheckCommandAccess(client, "c4bulmaca_flag", ADMFLAG_ROOT))
				{
					C4BulmacaMenu().Display(client, 0);
				}
			}
			else
			{
				PrintToChat(client, "[SM] \x07Oyun başladığı için ayarları yapamadım.");
			}
		}
		else if (dize == 3)
		{
			if (!GameStart)
			{
				int ent = GetClientAimTarget(client, false);
				if (IsValidEntity(ent))
				{
					char modelname[16];
					GetEntPropString(ent, Prop_Data, "m_iName", modelname, 16);
					if (strcmp(modelname, "saklanbac_c4") == 0)
					{
						RemoveEntity(ent);
						C4--;
					}
				}
				if (warden_iswarden(client) || CheckCommandAccess(client, "c4bulmaca_flag", ADMFLAG_ROOT))
				{
					C4BulmacaMenu().Display(client, 0);
				}
			}
			else
			{
				PrintToChat(client, "[SM] \x07Oyun başladığı için ayarları yapamadım.");
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action SetTransmit(int entity, int client)
{
	if (IsValidEntity(entity) && Buldu[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &button)
{
	if (GameStart && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !Buldu[client] && button & IN_USE)
	{
		int ent = GetClientAimTarget(client, false);
		if (IsValidEntity(ent))
		{
			char modelname[16];
			GetEntPropString(ent, Prop_Data, "m_iName", modelname, 16);
			if (strcmp(modelname, "saklanbac_c4") == 0)
			{
				if (GetEntitiesDistance(client, ent) < 100.0)
				{
					RemoveEntity(ent);
					Buldu[client] = true;
					char sname[128];
					GetClientName(client, sname, 128);
					C4--;
					if (C4 != 0)
					{
						PrintToChat(client, "[SM] \x10C4 Bulduğun için artık diğer C4leri göremezsin.");
						PrintToChatAll("[SM] \x04%s\x01, C4 buldu ve \x04%d \x01C4 kaldı.", sname, C4);
					}
					else
					{
						PrintToChatAll("[SM] \x04%s\x01, Son C4'ü buldu ve \x05oyun bitti.", sname);
						for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
						{
							if (IsPlayerAlive(i) && GetClientTeam(i) == 2 && !Buldu[i])
								ForcePlayerSuicide(i);
							
							if (Buldu[i])
								Buldu[i] = false;
						}
						GameStart = false; C4 = 0;
					}
				}
			}
		}
	}
	else if (!GameStart && IsPlayerAlive(client) && button & IN_USE)
	{
		int ent = GetClientAimTarget(client, false);
		if (IsValidEntity(ent))
		{
			char modelname[16];
			GetEntPropString(ent, Prop_Data, "m_iName", modelname, 16);
			if (strcmp(modelname, "saklanbac_c4") == 0)
			{
				button &= ~IN_USE;
			}
		}
	}
}

bool IsValidClient(int client, bool nobots = true)
{
	return client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && IsClientConnected(client) && (nobots && !IsFakeClient(client));
}

float GetEntitiesDistance(int ent1, int ent2)
{
	float orig1[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	
	float orig2[3];
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);
	
	return GetVectorDistance(orig1, orig2);
}

public void GetAimCoords(int client, float vector[3])
{
	float vAngles[3];
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace))
		TR_GetEndPosition(vector, trace);
	trace.Close();
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
} 