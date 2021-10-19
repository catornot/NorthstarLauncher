#include "pch.h"
#include "scriptserverbrowser.h"
#include "squirrel.h"
#include "masterserver.h"
#include "gameutils.h"
#include "serverauthentication.h"
#include "dedicated.h"

// functions for viewing server browser

// void NSRequestServerList()
SQInteger SQ_RequestServerList(void* sqvm)
{
	g_MasterServerManager->RequestServerList();
	return 0;
}

// bool function NSIsRequestingServerList()
SQInteger SQ_IsRequestingServerList(void* sqvm)
{
	ClientSq_pushbool(sqvm, g_MasterServerManager->m_scriptRequestingServerList);
	return 1;
}

// bool function NSMasterServerConnectionSuccessful()
SQInteger SQ_MasterServerConnectionSuccessful(void* sqvm)
{
	ClientSq_pushbool(sqvm, g_MasterServerManager->m_successfullyConnected);
	return 1;
}

// int function NSGetServerCount()
SQInteger SQ_GetServerCount(void* sqvm)
{
	ClientSq_pushinteger(sqvm, g_MasterServerManager->m_remoteServers.size());
	return 1;
}

// string function NSGetServerName( int serverIndex )
SQInteger SQ_GetServerName(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get name of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	ClientSq_pushstring(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].name, -1);
	return 1;
}

// string function NSGetServerDescription( int serverIndex )
SQInteger SQ_GetServerDescription(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get description of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	ClientSq_pushstring(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].description.c_str(), -1);
	return 1;
}

// string function NSGetServerMap( int serverIndex )
SQInteger SQ_GetServerMap(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get map of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	ClientSq_pushstring(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].map, -1);
	return 1;
}

// string function NSGetServerPlaylist( int serverIndex )
SQInteger SQ_GetServerPlaylist(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get playlist of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	ClientSq_pushstring(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].playlist, -1);
	return 1;
}

// int function NSGetServerPlayerCount( int serverIndex )
SQInteger SQ_GetServerPlayerCount(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get playercount of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	ClientSq_pushinteger(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].playerCount);
	return 1;
}

// int function NSGetServerMaxPlayerCount( int serverIndex )
SQInteger SQ_GetServerMaxPlayerCount(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get max playercount of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	ClientSq_pushinteger(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].maxPlayers);
	return 1;
}

// string function NSGetServerID( int serverIndex )
SQInteger SQ_GetServerID(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get id of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	ClientSq_pushstring(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].id, -1);
	return 1;
}

// bool function NSServerRequiresPassword( int serverIndex )
SQInteger SQ_ServerRequiresPassword(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get hasPassword of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	ClientSq_pushbool(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].requiresPassword);
	return 1;
}

// int function NSGetServerRequiredModsCount( int serverIndex )
SQInteger SQ_GetServerRequiredModsCount(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get required mods count of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	ClientSq_pushinteger(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].requiredMods.size());
	return 1;
}

// string function NSGetServerRequiredModName( int serverIndex, int modIndex )
SQInteger SQ_GetServerRequiredModName(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);
	SQInteger modIndex = ClientSq_getinteger(sqvm, 2);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get hasPassword of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	if (modIndex >= g_MasterServerManager->m_remoteServers[serverIndex].requiredMods.size())
	{
		spdlog::warn("Tried to get required mod name of mod index {} when only {} mod are available", modIndex, g_MasterServerManager->m_remoteServers[serverIndex].requiredMods.size());
		return 0;
	}

	ClientSq_pushstring(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].requiredMods[modIndex].Name.c_str(), -1);
	return 1;
}

// string function NSGetServerRequiredModVersion( int serverIndex, int modIndex )
SQInteger SQ_GetServerRequiredModVersion(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);
	SQInteger modIndex = ClientSq_getinteger(sqvm, 2);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to get required mod version of server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	if (modIndex >= g_MasterServerManager->m_remoteServers[serverIndex].requiredMods.size())
	{
		spdlog::warn("Tried to get required mod version of mod index {} when only {} mod are available", modIndex, g_MasterServerManager->m_remoteServers[serverIndex].requiredMods.size());
		return 0;
	}

	ClientSq_pushstring(sqvm, g_MasterServerManager->m_remoteServers[serverIndex].requiredMods[modIndex].Version.c_str(), -1);
	return 1;
}

// void function NSClearRecievedServerList()
SQInteger SQ_ClearRecievedServerList(void* sqvm)
{
	g_MasterServerManager->ClearServerList();
	return 0;
}


// functions for authenticating with servers

// void function NSTryAuthWithServer( int serverIndex, string password = "" )
SQInteger SQ_TryAuthWithServer(void* sqvm)
{
	SQInteger serverIndex = ClientSq_getinteger(sqvm, 1);
	const SQChar* password = ClientSq_getstring(sqvm, 2);

	if (serverIndex >= g_MasterServerManager->m_remoteServers.size())
	{
		spdlog::warn("Tried to auth with server index {} when only {} servers are available", serverIndex, g_MasterServerManager->m_remoteServers.size());
		return 0;
	}

	// send off persistent data first, don't worry about server/client stuff, since m_additionalPlayerData should only have entries when we're a local server
	// note: this seems like it could create a race condition, test later
	for (auto& pair : g_ServerAuthenticationManager->m_additionalPlayerData)
		g_ServerAuthenticationManager->WritePersistentData(pair.first);

	// do auth
	g_MasterServerManager->AuthenticateWithServer(g_LocalPlayerUserID, (char*)"", g_MasterServerManager->m_remoteServers[serverIndex].id, (char*)password);

	return 0;
}

// bool function NSIsAuthenticatingWithServer()
SQInteger SQ_IsAuthComplete(void* sqvm)
{
	ClientSq_pushbool(sqvm, g_MasterServerManager->m_scriptAuthenticatingWithGameServer);
	return 1;
}

// bool function NSWasAuthSuccessful()
SQInteger SQ_WasAuthSuccessful(void* sqvm)
{
	ClientSq_pushbool(sqvm, g_MasterServerManager->m_successfullyAuthenticatedWithGameServer);
	return 1;
}

// void function NSConnectToAuthedServer()
SQInteger SQ_ConnectToAuthedServer(void* sqvm)
{
	if (!g_MasterServerManager->m_hasPendingConnectionInfo)
	{
		spdlog::error("Tried to connect to authed server before any pending connection info was available");
		return 0;
	}

	RemoteServerConnectionInfo info = g_MasterServerManager->m_pendingConnectionInfo;

	// set auth token, then try to connect
	// i'm honestly not entirely sure how silentconnect works regarding ports and encryption so using connect for now
	Cbuf_AddText(Cbuf_GetCurrentPlayer(), fmt::format("serverfilter {}", info.authToken).c_str(), cmd_source_t::kCommandSrcCode);
	Cbuf_AddText(Cbuf_GetCurrentPlayer(), fmt::format("connect {}.{}.{}.{}:{}", info.ip.S_un.S_un_b.s_b1, info.ip.S_un.S_un_b.s_b2, info.ip.S_un.S_un_b.s_b3, info.ip.S_un.S_un_b.s_b4, info.port).c_str(), cmd_source_t::kCommandSrcCode);

	g_MasterServerManager->m_hasPendingConnectionInfo = false;
	return 0;
}

// void function NSTryAuthWithLocalServer()
SQInteger SQ_TryAuthWithLocalServer(void* sqvm)
{
	// do auth request
	g_MasterServerManager->AuthenticateWithOwnServer(g_LocalPlayerUserID, (char*)"");

	return 0;
}

// void function NSCompleteAuthWithLocalServer()
SQInteger SQ_CompleteAuthWithLocalServer(void* sqvm)
{
	// literally just set serverfilter
	// note: this assumes we have no authdata other than our own
	Cbuf_AddText(Cbuf_GetCurrentPlayer(), fmt::format("serverfilter {}", g_ServerAuthenticationManager->m_authData.begin()->first).c_str(), cmd_source_t::kCommandSrcCode);

	return 0;
}

void InitialiseScriptServerBrowser(HMODULE baseAddress)
{
	if (IsDedicated())
		return;

	g_UISquirrelManager->AddFuncRegistration("void", "NSRequestServerList", "", "", SQ_RequestServerList);
	g_UISquirrelManager->AddFuncRegistration("bool", "NSIsRequestingServerList", "", "", SQ_IsRequestingServerList);
	g_UISquirrelManager->AddFuncRegistration("bool", "NSMasterServerConnectionSuccessful", "", "", SQ_MasterServerConnectionSuccessful);
	g_UISquirrelManager->AddFuncRegistration("int", "NSGetServerCount", "", "", SQ_GetServerCount);
	g_UISquirrelManager->AddFuncRegistration("void", "NSClearRecievedServerList", "", "", SQ_ClearRecievedServerList);

	g_UISquirrelManager->AddFuncRegistration("string", "NSGetServerName", "int serverIndex", "", SQ_GetServerName);
	g_UISquirrelManager->AddFuncRegistration("string", "NSGetServerDescription", "int serverIndex", "", SQ_GetServerDescription);
	g_UISquirrelManager->AddFuncRegistration("string", "NSGetServerMap", "int serverIndex", "", SQ_GetServerMap);
	g_UISquirrelManager->AddFuncRegistration("string", "NSGetServerPlaylist", "int serverIndex", "", SQ_GetServerPlaylist);
	g_UISquirrelManager->AddFuncRegistration("int", "NSGetServerPlayerCount", "int serverIndex", "", SQ_GetServerPlayerCount);
	g_UISquirrelManager->AddFuncRegistration("int", "NSGetServerMaxPlayerCount", "int serverIndex", "", SQ_GetServerMaxPlayerCount);
	g_UISquirrelManager->AddFuncRegistration("string", "NSGetServerID", "int serverIndex", "", SQ_GetServerID);
	g_UISquirrelManager->AddFuncRegistration("bool", "NSServerRequiresPassword", "int serverIndex", "", SQ_ServerRequiresPassword);
	g_UISquirrelManager->AddFuncRegistration("int", "NSGetServerRequiredModsCount", "int serverIndex", "", SQ_GetServerRequiredModsCount);
	g_UISquirrelManager->AddFuncRegistration("string", "NSGetServerRequiredModName", "int serverIndex, int modIndex", "", SQ_GetServerRequiredModName);
	g_UISquirrelManager->AddFuncRegistration("string", "NSGetServerRequiredModVersion", "int serverIndex, int modIndex", "", SQ_GetServerRequiredModVersion);

	g_UISquirrelManager->AddFuncRegistration("void", "NSTryAuthWithServer", "int serverIndex, string password = \"\"", "", SQ_TryAuthWithServer);
	g_UISquirrelManager->AddFuncRegistration("bool", "NSIsAuthenticatingWithServer", "", "", SQ_IsAuthComplete);
	g_UISquirrelManager->AddFuncRegistration("bool", "NSWasAuthSuccessful", "", "", SQ_WasAuthSuccessful);
	g_UISquirrelManager->AddFuncRegistration("void", "NSConnectToAuthedServer", "", "", SQ_ConnectToAuthedServer);

	g_UISquirrelManager->AddFuncRegistration("void", "NSTryAuthWithLocalServer", "", "", SQ_TryAuthWithLocalServer);
	g_UISquirrelManager->AddFuncRegistration("void", "NSCompleteAuthWithLocalServer", "", "", SQ_CompleteAuthWithLocalServer);
}