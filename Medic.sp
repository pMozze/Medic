#include <sdktools>

public Plugin myinfo = {
	name = "Medic",
	author = "Mozze",
	description = "",
	version = "1.2",
	url = "t.me/pMozze"
};

ConVar
	g_cvHealth,
	g_cvMinimumHealth,
	g_cvCount,
	g_cvSound;

int
	g_iHealth,
	g_iMinimumHealth,
	g_iCount,
	g_iCalledMedicCount[66];

char
	g_szSound[PLATFORM_MAX_PATH];

public void OnPluginStart() {
	g_cvHealth = CreateConVar("sm_medic_health", "80");
	g_cvMinimumHealth = CreateConVar("sm_medic_minimumhealth", "40");
	g_cvCount = CreateConVar("sm_medic_count", "1");
	g_cvSound = CreateConVar("sm_medic_sound", "");

	g_cvHealth.AddChangeHook(onConVarChanged);
	g_cvMinimumHealth.AddChangeHook(onConVarChanged);
	g_cvCount.AddChangeHook(onConVarChanged);

	AutoExecConfig(true, "Medic");
	LoadTranslations("medic.phrases");
	HookEvent("round_start", onRoundStart, EventHookMode_PostNoCopy);

	RegConsoleCmd("say", medicCommand);
	RegConsoleCmd("say_team", medicCommand);
}

public void OnConfigsExecuted() {
	g_iHealth = g_cvHealth.IntValue;
	g_iMinimumHealth = g_cvMinimumHealth.IntValue;
	g_iCount = g_cvCount.IntValue;
	g_cvSound.GetString(g_szSound, sizeof(g_szSound));
	precacheSound(g_szSound);
}

public void onConVarChanged(ConVar hConVar, const char[] szOldValue, const char[] szNewValue) {
	if (hConVar == g_cvHealth)
		g_iHealth = hConVar.IntValue;

	if (hConVar == g_cvMinimumHealth)
		g_iMinimumHealth = hConVar.IntValue;

	if (hConVar == g_cvCount)
		g_iCount = hConVar.IntValue;

	if (hConVar == g_cvSound) {
		hConVar.GetString(g_szSound, sizeof(g_szSound));
		precacheSound(g_szSound);
	}
}

public void onRoundStart(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	for (int iClientIndex = 1; iClientIndex <= MaxClients; iClientIndex++)
		g_iCalledMedicCount[iClientIndex] = 0;
}

public void OnClientPutInServer(int iClient) {
	g_iCalledMedicCount[iClient] = 0;
}

public Action medicCommand(int iClient, int iArgs) {
	char szMessage[256];
	GetCmdArgString(szMessage, sizeof(szMessage));
	StripQuotes(szMessage);
	TrimString(szMessage);
	
	if (
		StrEqual(szMessage, "!medic", false)
		|| StrEqual(szMessage, "!ьувшс", false)
		|| StrEqual(szMessage, "!медик", false)
	) {
		if (!IsPlayerAlive(iClient)) {
			PrintToChat(iClient, "%t%t", "Prefix", "Not alive");
			return Plugin_Handled;
		}
				
		if (GetClientHealth(iClient) > g_iMinimumHealth) {
			PrintToChat(iClient, "%t%t", "Prefix", "Minimum health", g_iMinimumHealth);
			return Plugin_Handled;
		}
		
		if (g_iCalledMedicCount[iClient] == g_iCount) {
			PrintToChat(iClient, "%t%t", "Prefix", "Max count calling", g_iCount);
			return Plugin_Handled;
		}
		
		if (g_szSound[0])
			EmitSoundToAll(g_szSound, iClient, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.75);

		SetEntityHealth(iClient, g_iHealth);
		g_iCalledMedicCount[iClient]++;

		PrintToChatAll("%t%t", "Prefix", "Medic has been called", iClient);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void showRadioIcon(int iClient) {
	TE_Start("RadioIcon");
	TE_WriteNum("m_iAttachToClient", iClient);
	TE_SendToAll();
}

public void precacheSound(const char[] szSound) {
	char szSoundPath[PLATFORM_MAX_PATH];
	Format(szSoundPath, sizeof(szSoundPath), "sound/%s", szSound);

	if (FileExists(szSoundPath)) {
		PrecacheSound(szSound);
		AddFileToDownloadsTable(szSoundPath);
	}
}
