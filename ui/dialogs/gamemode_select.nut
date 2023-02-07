global function InitGamemodeSelectDialog
global function GamemodeSelect_IsEnabled

global function GamemodeSelect_PlaylistIsDefaultSlot


struct {
	var menu

	var background
} file

  
 	    
  
void function InitGamemodeSelectDialog( var menu )
{
	file.menu = menu

	file.background = Hud_GetChild( menu, "ScreenFrame" )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, GamemodeSelect_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, GamemodeSelect_Close )

	SetDialog( menu, true )
	SetClearBlur( menu, false )

#if DEV
	AddMenuThinkFunc( menu, GameModeAutomationThink )
#endif       
}

void function GamemodeSelect_Open()
{
	{
		TabDef tabDef = AddTab( file.menu, Hud_GetChild( file.menu, "GamemodeSelectDialogPublicPanel" ), "#GAMEMODE_CATEGORY_PUBLIC_MATCH" )
		tabDef.width = 300
	}
                           
		if ( GetPartySize() <= PRIVATE_MATCH_MAX_PARTY_SIZE )
		{
			TabDef tabDef = AddTab( file.menu, Hud_GetChild( file.menu, "GamemodeSelectDialogPrivatePanel" ), "#GAMEMODE_CATEGORY_PRIVATE_MATCH" )
			tabDef.width = 300
		}
       

	TabData tabData = GetTabDataForPanel( file.menu )
	tabData.centerTabs = true
	SetTabDefsToSeasonal(tabData)
	SetTabBackground( tabData, Hud_GetChild( file.menu, "TabsBackground" ), eTabBackground.STANDARD )

	if ( GetLastMenuNavDirection() == MENU_NAV_FORWARD )
	{
		ActivateTab( tabData, 0 )
	}

	AnimateIn()

}
void function GamemodeSelect_Close()
{
	ClearTabs( file.menu )
	Hud_SetAboveBlur( GetMenu( "LobbyMenu" ), true )

	var modeSelectButton = GetModeSelectButton()
	Hud_SetSelected( modeSelectButton, false )
	Hud_SetFocused( modeSelectButton )

	SetModeSelectMenuOpen( false )

	Lobby_OnGamemodeSelectClose()

}
#if DEV
void function GameModeAutomationThink( var menu )
{
	if (AutomateUi())
	{
		printt("GameModeAutomationThink OnCloseButton_Activate()")
		CloseAllDialogs()
	}
}
#endif       

void function AnimateIn()
{
	SetElementAnimations(file.background, 0, 0.14)
}

void function SetElementAnimations( var element, float delay, float duration )
{
	RuiSetWallTimeWithOffset( Hud_GetRui( element ), "animateStartTime", delay )
	RuiSetFloat( Hud_GetRui( element ), "animateDuration", duration )
}

  
 	                       
  
bool function GamemodeSelect_IsEnabled()
{
	if ( !IsConnectedServerInfo() )
		return false
	     
	return GetCurrentPlaylistVarBool( "gamemode_select_v3_enable", true )
}

const string DEFAULT_PLAYLIST_UI_SLOT_NAME = "regular_1"
bool function GamemodeSelect_PlaylistIsDefaultSlot( string playlist )
{
	string uiSlot = GetPlaylistVarString( playlist, "ui_slot", "" )
	return (uiSlot == DEFAULT_PLAYLIST_UI_SLOT_NAME)
}
