/*
	NOTE:
	Do not install the original UCP files onto the server. Use this plugin only
	Only the players are required to use UCP, not the server."
*/

#include <amxmodx>
#include <amxmisc>

#define PLUGIN_VERSION "1.0"

new ucp_field[] = "*ucp_id";
new iCvar[2];
new filename[128];

new Trie:g_tGlobalSteam;
new Trie:g_tGlobalIP;

new filename_message[][] = {
	"; Cvars",
	"; ucp_client",
	"; 0 - Removes UCP",
	"; 1 - All players must use UCP",
	"; 2 - Custom players can play without UCP",
	"",
	"; This file contains all players that when ucp_client is 2",
	"; it will bypass and still connect to the servers",
	"",
	"; Shembull",
	"; ^"steam^" ^"STEAM_1:0:5928903^"",
	"; ^"ip^" ^"127.0.0.1^""
}

public plugin_init(){
	register_plugin("UCP Modification", "1.0", "CrXane");	
	register_cvar("ucp_modification", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);

	get_configsdir(filename, charsmax(filename));
	add(filename, charsmax(filename), "/users_ucp.ini");
	
	if (!file_exists(filename)){
		for (new i = 0; i < sizeof(filename_message); i++){
			write_file(filename, filename_message[i]);
		}
	}	
	
	iCvar[0] = register_cvar("ucp_client", "3");
	/*
	1 = All UCP Clients
	2 = Specific Players
	3 = No UCP
	*/
	
	g_tGlobalSteam = TrieCreate();
	g_tGlobalIP = TrieCreate();
	
	new Line[64], str_break_type[10], str_break_data[32];
	new f = fopen(filename, "rt");
	while (!feof(f)){
		fgets(f, Line, charsmax(Line));
		trim(Line);
		
		if (Line[0] == ';' || !Line[0] || Line[0] == '^n'){
			continue;
		}
		
		else {
			parse(Line, str_break_type, charsmax(str_break_type), str_break_data, charsmax(str_break_data));
			remove_quotes(str_break_type);
			remove_quotes(str_break_data);
			
			if (equali(str_break_type, "steam")){
				TrieSetCell(g_tGlobalSteam, str_break_data, 1);
			}
			
			else if (equali(str_break_type, "ip")){
				TrieSetCell(g_tGlobalIP, str_break_data, 1);
			}
		}
	}
	fclose(f);
}

public plugin_end(){
	TrieDestroy(g_tGlobalSteam);
	TrieDestroy(g_tGlobalIP);
}

public client_connect(id){
	iCvar[1] = get_pcvar_num(iCvar[0]);
	
	switch (iCvar[1]){
		case 1: {
			if (!is_user_ucp(id)){
				server_cmd("kick #%d ^"UCP Protected Server^"", get_user_userid(id));
			}
		}
		
		case 2: {
			if (!is_user_ucp(id) && !is_user_ucp_admin(id)){
				server_cmd("kick #%d ^"UCP Protected Server^"", get_user_userid(id));
			}
		}
	}
}

bool:is_user_ucp_admin(id){
	new steamid[32], ip[20];
	get_user_authid(id, steamid, charsmax(steamid));
	get_user_ip(id, ip, charsmax(ip));
	
	if (TrieKeyExists(g_tGlobalSteam, steamid)){
		return true;
	}
	
	if (TrieKeyExists(g_tGlobalIP, ip)){
		return true;
	}
	
	return false;
}

bool:is_user_ucp(id){
	new ucp_id[15];
	get_user_info(id, ucp_field, ucp_id, charsmax(ucp_id));
	if (ucp_id[0]){
		return true;
	}
	
	return false;
}
