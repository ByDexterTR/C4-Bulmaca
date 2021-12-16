#include <sourcemod>
#include <emitsoundany>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <warden>

#pragma semicolon 1
#pragma newdecls required

bool GameStart = false;
bool Buldu[65] = { false, ... };
bool g_OnceStopped[65] = { false, ... };
bool Muzik = true;
Handle client_timer[65] = { null, ... };
int g_iPlayerPrevButtons[65] = { 0, ... };
int client_checkc4[65] = { -1, ... };
int C4 = 0, FakeC4 = 0;

int m_flSimulationTime = 0;
int m_flProgressBarStartTime = 0;
int m_iProgressBarDuration = 0;
int m_iBlockingUseActionInProgress = 0;


public Plugin myinfo = 
{
	name = "C4 Bulmaca", 
	author = "ByDexter", 
	description = "", 
	version = "1.2", 
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
	
	m_flSimulationTime = FindSendPropInfo("CBaseEntity", "m_flSimulationTime");
	m_flProgressBarStartTime = FindSendPropInfo("CCSPlayer", "m_flProgressBarStartTime");
	m_iProgressBarDuration = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration");
	m_iBlockingUseActionInProgress = FindSendPropInfo("CCSPlayer", "m_iBlockingUseActionInProgress");
}

public void OnPluginEnd()
{
	GameStart = false;
	C4 = 0, FakeC4 = 0;
	char modelname[16];
	for (int i = MaxClients; i < GetMaxEntities(); i++)if (IsValidEdict(i) && IsValidEntity(i))
	{
		GetEntPropString(i, Prop_Data, "m_iName", modelname, 16);
		if (StrContains(modelname, "saklanbac_c4") != -1)
			RemoveEntity(i);
	}
}

public void OnMapStart()
{
	GameStart = false;
	C4 = 0, FakeC4 = 0;
	char modelname[16];
	for (int i = MaxClients; i < GetMaxEntities(); i++)if (IsValidEdict(i) && IsValidEntity(i))
	{
		GetEntPropString(i, Prop_Data, "m_iName", modelname, 16);
		if (StrContains(modelname, "saklanbac_c4") != -1)
			RemoveEntity(i);
	}
	
	PrecacheSoundAny("weapons/party_horn_01.wav");
	
	AddFileToDownloadsTable("sound/bydexter/thanos/bbnos_01/mainmenu.mp3");
	PrecacheSoundAny("bydexter/thanos/bbnos_01/mainmenu.mp3");
	AddFileToDownloadsTable("sound/bydexter/thanos/neckdeep_02/mainmenu.mp3");
	PrecacheSoundAny("bydexter/thanos/neckdeep_02/mainmenu.mp3");
	AddFileToDownloadsTable("sound/bydexter/thanos/sarahschachner_01/mainmenu.mp3");
	PrecacheSoundAny("bydexter/thanos/sarahschachner_01/mainmenu.mp3");
	AddFileToDownloadsTable("sound/bydexter/thanos/scarlxrd_01/mainmenu.mp3");
	PrecacheSoundAny("bydexter/thanos/scarlxrd_01/mainmenu.mp3");
	AddFileToDownloadsTable("sound/bydexter/thanos/scarlxrd_02/mainmenu.mp3");
	PrecacheSoundAny("bydexter/thanos/scarlxrd_02/mainmenu.mp3");
	AddFileToDownloadsTable("sound/bydexter/thanos/theverkkars_01/mainmenu.mp3");
	PrecacheSoundAny("bydexter/thanos/theverkkars_01/mainmenu.mp3");
	
	AddFileToDownloadsTable("sound/bydexter/thanos/stone_sound/xp_rankdown_02.wav");
	PrecacheSoundAny("bydexter/thanos/stone_sound/xp_rankdown_02.wav");
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
	menu.SetTitle("★ C4 Bulmaca ★\n★ C4: %d ★\n★ Sahte C4: %d ★\n ", C4, FakeC4);
	if (!GameStart)
		menu.AddItem("1", "> Oyunu başlat");
	else
		menu.AddItem("1", "> Oyunu durdur");
	
	if (!GameStart)
	{
		menu.AddItem("2", "> C4 Yerleştir");
		menu.AddItem("3", "> Sahte C4 Yerleştir");
		menu.AddItem("4", "> C4 Sil");
		if (Muzik)
			menu.AddItem("5", "> Müzik: Açık");
		else
			menu.AddItem("5", "> Müzik: Kapalı");
	}
	else
	{
		menu.AddItem("2", "> C4'ü Yerleştir", ITEMDRAW_DISABLED);
		menu.AddItem("3", "> Sahte C4 Yerleştir", ITEMDRAW_DISABLED);
		menu.AddItem("4", "> C4'ü Sil", ITEMDRAW_DISABLED);
		
		if (Muzik)
			menu.AddItem("5", "> Müzik: Açık", ITEMDRAW_DISABLED);
		else
			menu.AddItem("5", "> Müzik: Kapalı", ITEMDRAW_DISABLED);
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
					if (StrContains(modelname, "saklanbac_c4") != -1)
						RemoveEntity(i);
				}
				C4 = 0;
				FakeC4 = 0;
				GameStart = false;
				PrintToChatAll("[SM] \x04%N\x01 C4 bulmacayı \x07durdurdu.", client);
				for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
				{
					Buldu[i] = false;
				}
				EmitSoundToAllAny("bydexter/thanos/stone_sound/xp_rankdown_02.wav", SOUND_FROM_PLAYER, 1, 50);
			}
			else
			{
				if (Muzik)
				{
					int Sarki = GetRandomInt(1, 6);
					if (Sarki == 1)
						EmitSoundToAllAny("bydexter/thanos/bbnos_01/mainmenu.mp3", SOUND_FROM_PLAYER, 1, 30);
					else if (Sarki == 2)
						EmitSoundToAllAny("bydexter/thanos/sarahschachner_01/mainmenu.mp3", SOUND_FROM_PLAYER, 1, 30);
					else if (Sarki == 3)
						EmitSoundToAllAny("bydexter/thanos/scarlxrd_01/mainmenu.mp3", SOUND_FROM_PLAYER, 1, 30);
					else if (Sarki == 4)
						EmitSoundToAllAny("bydexter/thanos/scarlxrd_02/mainmenu.mp3", SOUND_FROM_PLAYER, 1, 30);
					else if (Sarki == 5)
						EmitSoundToAllAny("bydexter/thanos/theverkkars_01/mainmenu.mp3", SOUND_FROM_PLAYER, 1, 30);
					else if (Sarki == 6)
						EmitSoundToAllAny("bydexter/thanos/neckdeep_02/mainmenu.mp3", SOUND_FROM_PLAYER, 1, 30);
				}
				
				PrintToChatAll("[SM] \x04%N\x01 C4 bulmacayı \x05başlattı.", client);
				PrintToChatAll("[SM] \x04C4\x01: %d \x10| \x04Sahte C4\x01: %d", C4, FakeC4);
				for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
				{
					Buldu[i] = false;
					if (IsPlayerAlive(i) && GetClientTeam(i) == 2)
					{
						SetEntityRenderColor(i, 255, 0, 0, 255);
						CS_RespawnPlayer(i);
					}
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
				location[2] += 1.0;
				int c4 = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(c4, "model", "models/weapons/w_c4_planted.mdl");
				DispatchKeyValue(c4, "physicsmode", "1");
				DispatchKeyValue(c4, "nodamageforces", "1");
				DispatchKeyValue(c4, "spawnflags", "2");
				SetEntProp(c4, Prop_Send, "m_CollisionGroup", 0);
				SetEntPropString(c4, Prop_Data, "m_iName", "saklanbac_c4");
				DispatchSpawn(c4);
				SetEntityMoveType(c4, MOVETYPE_NONE);
				SDKHook(c4, SDKHook_SetTransmit, SetTransmit);
				float angle[3];
				GetEntPropVector(c4, Prop_Data, "m_angRotation", angle);
				GetClientEyeAngles(client, angle);
				angle[2] = 0.0; angle[0] = 0.0;
				TeleportEntity(c4, location, angle, NULL_VECTOR);
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
				float location[3];
				GetAimCoords(client, location);
				location[2] += 1.0;
				int c4 = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(c4, "model", "models/weapons/w_c4_planted.mdl");
				DispatchKeyValue(c4, "physicsmode", "1");
				DispatchKeyValue(c4, "nodamageforces", "1");
				DispatchKeyValue(c4, "spawnflags", "2");
				SetEntProp(c4, Prop_Send, "m_CollisionGroup", 0);
				SetEntPropString(c4, Prop_Data, "m_iName", "saklanbac_c4_f");
				DispatchSpawn(c4);
				SetEntityMoveType(c4, MOVETYPE_NONE);
				SDKHook(c4, SDKHook_SetTransmit, SetTransmit);
				float angle[3];
				GetEntPropVector(c4, Prop_Data, "m_angRotation", angle);
				GetClientEyeAngles(client, angle);
				angle[2] = 0.0; angle[0] = 0.0;
				TeleportEntity(c4, location, angle, NULL_VECTOR);
				FakeC4++;
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
		else if (dize == 4)
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
					else if (StrContains(modelname, "saklanbac_c4_f") == 0)
					{
						RemoveEntity(ent);
						FakeC4--;
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
		else if (dize == 5)
		{
			Muzik = !Muzik;
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

public Action OnPlayerRunCmd(int client, int &iButtons)
{
	if (GameStart && !Buldu[client])
	{
		if (!(g_iPlayerPrevButtons[client] & IN_USE) && iButtons & IN_USE)
		{
			int ent = GetClientAimTarget(client, false);
			if (IsValidEntity(ent))
			{
				if (GetEntitiesDistance(client, ent) < 82.0)
				{
					char modelname[16];
					GetEntPropString(ent, Prop_Data, "m_iName", modelname, 16);
					if (StrContains(modelname, "saklanbac_c4") != -1)
					{
						SetProgressBar(client, 3);
						client_checkc4[client] = ent;
						client_timer[client] = CreateTimer(3.0, c4kontrol, client, TIMER_FLAG_NO_MAPCHANGE);
						g_OnceStopped[client] = true;
					}
				}
			}
		}
		else if (iButtons & IN_USE)
		{
			if (client_checkc4[client] != -1)
			{
				int ent = GetClientAimTarget(client, false);
				if (ent != client_checkc4[client])
				{
					client_checkc4[client] = -1;
					ResetProgressBar(client);
				}
			}
		}
		else if (g_OnceStopped[client])
		{
			g_iPlayerPrevButtons[client] = 0;
			g_OnceStopped[client] = false;
			if (client_timer[client] != null)
			{
				CloseHandle(client_timer[client]);
				client_timer[client] = null;
			}
			ResetProgressBar(client);
		}
		g_iPlayerPrevButtons[client] = iButtons;
	}
}

public Action c4kontrol(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		if (client_checkc4[client] && IsValidEdict(client_checkc4[client]))
		{
			ScreenColor(client, { 255, 0, 0, 150 } );
			ResetProgressBar(client);
			char modelname[16];
			GetEntPropString(client_checkc4[client], Prop_Data, "m_iName", modelname, 16);
			if (strcmp(modelname, "saklanbac_c4_f") == 0)
			{
				RemoveEntity(client_checkc4[client]);
				FakeC4--;
				PrintToChat(client, "[SM] Bu \x10C4\x01 sahte :D \x04Seni kandırdım \x07asla bulamazsın gerçeği.");
				if (FakeC4 == 0)
				{
					PrintToChatAll("[SM] \x10%N\x01, Sahte C4 buldu. sahte C4 kalmadı.", client);
				}
				else
				{
					PrintToChatAll("[SM] \x10%N\x01, Sahte C4 buldu. \x07Kalan Sahte C4: \x01%d", client, FakeC4);
				}
			}
			else if (strcmp(modelname, "saklanbac_c4") == 0)
			{
				ScreenColor(client, { 0, 255, 0, 150 } );
				CreateParticle(client, "weapon_confetti_balloons", 5.0);
				RemoveEntity(client_checkc4[client]);
				C4--;
				Buldu[client] = true;
				if (C4 == 0)
				{
					PrintToChatAll("[SM] \x10%N\x01, Son C4'ü buldu ve \x10oyun sona erdi bulamayanlar öldü!", client);
					for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && GetClientTeam(i) == 2)
					{
						if (!Buldu[i])
						{
							ForcePlayerSuicide(i);
						}
						else
						{
							SetEntityRenderColor(i, 255, 255, 255, 255);
							PrintToChat(i, "[SM] \x05Tebrikler oyunu kazandınız!");
							Buldu[i] = false;
						}
					}
					GameStart = false;
					C4 = 0, FakeC4 = 0;
					for (int i = MaxClients; i < GetMaxEntities(); i++)if (IsValidEdict(i) && IsValidEntity(i))
					{
						GetEntPropString(i, Prop_Data, "m_iName", modelname, 16);
						if (StrContains(modelname, "saklanbac_c4") != -1)
							RemoveEntity(i);
					}
					EmitSoundToAllAny("bydexter/thanos/stone_sound/xp_rankdown_02.wav", SOUND_FROM_PLAYER, 1, 50);
				}
				else
				{
					SetEntityRenderColor(client, 0, 255, 0, 255);
					PrintToChat(client, "[SM] \x05Doğru C4'ü buldun. \x10Artık diğer C4'leri göremezsin.");
					PrintToChatAll("[SM] \x10%N\x01, C4 buldu. \x04Kalan C4: \x01%d", client, C4);
				}
			}
		}
		client_checkc4[client] = -1;
		client_timer[client] = null;
	}
	return Plugin_Stop;
}

void ScreenColor(int client, int Color[4])
{
	int clients[1];
	clients[0] = client;
	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1, 0);
	Protobuf pb = UserMessageToProtobuf(message);
	pb.SetInt("duration", 200);
	pb.SetInt("hold_time", 40);
	pb.SetInt("flags", 17);
	pb.SetColor("clr", Color);
	EndMessage();
}

void SetProgressBar(int iClient, int iProgressTime)
{
	float flGameTime = GetGameTime();
	
	SetEntDataFloat(iClient, m_flSimulationTime, flGameTime + float(iProgressTime), true);
	SetEntData(iClient, m_iProgressBarDuration, iProgressTime, 4, true);
	SetEntDataFloat(iClient, m_flProgressBarStartTime, flGameTime, true);
	
	SetEntData(iClient, m_iBlockingUseActionInProgress, 2, 4, true);
}

void ResetProgressBar(int iClient)
{
	SetEntDataFloat(iClient, m_flProgressBarStartTime, 0.0, true);
	SetEntData(iClient, m_iProgressBarDuration, 0, 1, true);
}

bool IsValidClient(int client, bool nobots = true)
{
	return client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && IsClientConnected(client) && (nobots && !IsFakeClient(client));
}

public void CreateParticle(int ent, char[] particleType, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	char name[64];
	if (IsValidEdict(particle))
	{
		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", name);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(name);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticle, particle);
	}
	EmitSoundToAllAny("weapons/party_horn_01.wav", SOUND_FROM_PLAYER, 2, 20);
}

public Action DeleteParticle(Handle timer, any particle)
{
	if (IsValidEntity(particle))
	{
		char classN[64];
		GetEdictClassname(particle, classN, sizeof(classN));
		if (StrEqual(classN, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
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