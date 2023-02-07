global function InitGameModeSelectPublicPanel

global function GamemodeSelect_UpdateSelectButton
global function UpdateOpenModeSelectDialog
global function GamemodeSelect_PlayVideo
global function GamemodeSelect_SetFeaturedSlot

#if DEV
global function ShippingPlaylistCheck
#endif


struct
{
	var panel
	var craftingPreview
	var arenasPreview
	var craftingSlideout
	var disabledCover
	var gameModeButtonBackground
	var header
	var headerWelcome
	var closeButton

	bool hasLTM = false

	int   videoChannel = -1
	asset currentVideoAsset = $""
	bool showVideo
	bool craftingOpen = false

	string featuredSlot = ""
	string featuredSlotString = "#HEADER_NEW_MODE"

	float lastCrossFadeGameTime = -1
	bool isTrainingCompleted = false

	array<var> modeSelectButtonList
	table<var, string> selectButtonPlaylistNameMap
	var rankedRUIToUpdate = null

	table<string, var > slotToButtonMap
	table<string, var > slotToColorMap

} file

const int DRAW_NONE = 0
const int DRAW_IMAGE = 1
const int DRAW_RANK = 2

const int FEATURED_NONE = 0
const int FEATURED_ACTIVE = 1
const int FEATURED_INACTIVE = 2

void function InitGameModeSelectPublicPanel( var panel )
{
	file.panel = panel

	RegisterSignal( "GamemodeSelect_EndVideoStopThread" )

	file.closeButton = Hud_GetChild( panel, "CloseButton" )
	file.gameModeButtonBackground = Hud_GetChild( panel, "GameModeButtonBg" )
	file.headerWelcome = Hud_GetChild(panel,"HeaderWelcome" )
	file.header = Hud_GetChild(panel,"Header" )
	file.craftingPreview = Hud_GetChild(panel,"CraftingPreview" )
	file.arenasPreview = Hud_GetChild(panel,"ArenasPreview" )
	file.disabledCover = Hud_GetChild( panel, "DisabledCover" )


	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, OnShowModePublicPanel )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, OnHidePublicPanel )

	file.slotToButtonMap = {
		training = Hud_GetChild( panel, "GamemodeButton0" ),
		firing_range = Hud_GetChild( panel, "GamemodeButton1" ),
		regular_1 = Hud_GetChild( panel, "GamemodeButton2" ),
		regular_2 = Hud_GetChild( panel, "GamemodeButton3" ),
		regular_3 = Hud_GetChild( panel, "GamemodeButton4" ),
		ranked = Hud_GetChild( panel, "GamemodeButton5" ),
		arenas = Hud_GetChild( panel, "GamemodeButton6" ),
		arenas_ranked = Hud_GetChild( panel, "GamemodeButton7" ),
		ltm = Hud_GetChild( panel, "GamemodeButton8" ),
		event = Hud_GetChild( panel, "GamemodeButton9" )
	}

	RuiSetString( Hud_GetRui( Hud_GetChild( panel, "SurvivalCategory" ) ), "header", "#GAMEMODE_CATEGORY_SURVIVAL" )
	RuiSetString( Hud_GetRui( Hud_GetChild( panel, "ArenasCategory" ) ), "header", "#GAMEMODE_CATEGORY_ARENAS" )
	RuiSetString( Hud_GetRui( Hud_GetChild( panel, "LTMCategory" ) ), "header", "#GAMEMODE_CATEGORY_LTM" )
	                                                                                                                  

	Hud_AddEventHandler( file.closeButton, UIE_CLICK, OnCloseButton_Activate )

	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#B_BUTTON_CLOSE" )
	AddPanelFooterOption( panel, LEFT, BUTTON_A, true, "#A_BUTTON_SELECT" )
}


  
 	           
  
void function OnShowModePublicPanel( var panel )
{
	SetModeSelectMenuOpen( true )
	file.isTrainingCompleted = IsTrainingCompleted() || IsExemptFromTraining()
	UpdateOpenModeSelectDialog()

	if(file.isTrainingCompleted)
	{
		ToggleCraftingTooltip(true)
	}
	AddCallbackAndCallNow_UserInfoUpdated( Ranked_OnUserInfoUpdatedInGameModeSelect )

	RuiSetString(Hud_GetRui( file.header ), "header", "")
	RuiSetString(Hud_GetRui( file.header ), "description", "#GAMEMODE_SELECT_HEADER")
	RuiSetString(Hud_GetRui( file.headerWelcome ), "header", "#PL_WELCOME_TO_APEX")
	RuiSetString(Hud_GetRui( file.headerWelcome ), "description", "#GAMEMODE_SELECT_HEADER_WELCOME")

	for ( int buttonIdx = 0; buttonIdx < file.slotToButtonMap.len(); buttonIdx++ )
	{
		var button = Hud_GetChild( panel, format( "GamemodeButton%d", buttonIdx ) )
		Hud_AddEventHandler( button, UIE_CLICK, GamemodeButton_Activate )
		Hud_AddEventHandler( button, UIE_GET_FOCUS, GamemodeButton_OnGetFocus )
		Hud_AddEventHandler( button, UIE_LOSE_FOCUS, GamemodeButton_OnLoseFocus )
		file.modeSelectButtonList.append( button )
	}

	AnimateIn()
}

void function OnHidePublicPanel( var panel )
{
	printt( "Clearing rui to update in game mode select" )
	                                                  
	var craftingRui = Hud_GetRui( file.craftingPreview )
	RuiSetWallTimeBad( craftingRui, "animateStartTime" )
	var arenasRui = Hud_GetRui( file.arenasPreview )
	RuiSetWallTimeBad( arenasRui, "animateStartTime" )
	Hud_SetVisible(file.arenasPreview, false)

	file.rankedRUIToUpdate = null
	RemoveCallback_UserInfoUpdated( Ranked_OnUserInfoUpdatedInGameModeSelect )

	for ( int buttonIdx = 0; buttonIdx < file.slotToButtonMap.len(); buttonIdx++ )
	{
		var button = Hud_GetChild( panel, format( "GamemodeButton%d", buttonIdx ) )
		Hud_RemoveEventHandler( button, UIE_CLICK, GamemodeButton_Activate )
		Hud_RemoveEventHandler( button, UIE_GET_FOCUS, GamemodeButton_OnGetFocus )
		Hud_RemoveEventHandler( button, UIE_LOSE_FOCUS, GamemodeButton_OnLoseFocus )
	}
}


void function ToggleCraftingTooltip ( bool turnOn )
{
	if(turnOn && file.isTrainingCompleted)
	{
		ToolTipData td
		td.tooltipStyle = eTooltipStyle.CRAFTING_INFO
		td.titleText = "#CRAFTING_FLOW"
		td.descText = "#CRAFTING_FEATURE_DESC"

		Hud_SetToolTipData( file.craftingPreview, td )
	}
	else
	{
		Hud_ClearToolTipData( file.craftingPreview )
	}
}


  
 	                       
  
void function GamemodeButton_Activate( var button )
{
	if ( Hud_IsLocked( button ) )
	{
		EmitUISound( "menu_deny" )
		return
	}

	string playlistName = file.selectButtonPlaylistNameMap[button]
	if ( IsPrivateMatchLobby() )
		PrivateMatch_SetSelectedPlaylist( playlistName )
	else
		Lobby_SetSelectedPlaylist( playlistName )

	CloseAllDialogs()
}

void function GamemodeButton_OnGetFocus( var button )
{
	CrossFadeCraftingArenas(button, true)
	ToggleCraftingTooltip(false)
}

void function GamemodeButton_OnLoseFocus( var button )
{
	CrossFadeCraftingArenas(button, false)
	ToggleCraftingTooltip(true)
}


  
 	              
  
void function UpdateOpenModeSelectDialog()
{
	file.showVideo = GetCurrentPlaylistVarBool( "lobby_gamemode_video", false )
	Hud_SetAboveBlur( GetMenu( "LobbyMenu" ), false )

	if ( file.featuredSlot != "" )
		thread ClearFeaturedSlotAfterDelay()


	file.selectButtonPlaylistNameMap.clear()

	UpdateGameModes()
	UpdateCrafting()
	#if DEV
		ShippingPlaylistCheck()
	#endif
}
void function UpdateGameModes()
{
	table<string, string> slotToPlaylistNameMap = GameModeSelect_GetPlaylists();

	string mainPlaylist = "defaults"

	foreach ( string slotKey, string playlistName in slotToPlaylistNameMap )
	{
		printf( "GameModesDebug: %s(): Slot: %s, Game Mode: %s", FUNC_NAME(), slotKey, playlistName )
	}

	foreach ( string slotKey, button in file.slotToButtonMap )
	{
		string playlistName = slotToPlaylistNameMap[slotKey]
		var rui = Hud_GetRui( button )
		bool isLtm = button == file.slotToButtonMap["ltm"]
		bool isEvent = button == file.slotToButtonMap["event"]
		bool isRankedArenas = button == file.slotToButtonMap["arenas_ranked"]
		bool isRankedBR = button == file.slotToButtonMap["ranked"]
		if ( playlistName == "" )
		{
			Hud_SetEnabled( button, false )
			if(isLtm)
			{
				Hud_Hide( button )
				Hud_Hide( Hud_GetChild(file.panel,"LTMCategory" ) )
				file.hasLTM = false
			}
			else if(isEvent)
			{
				Hud_Hide( button )
			}

			RuiSetString( rui, "modeNameText", "")
			RuiSetImage( rui, "modeImage", $"rui/menu/gamemode/playlist_bg_none" )

			if( isRankedArenas || isRankedBR )
			{
				RuiSetString( rui, "modeLockedReason", "#PLAYLIST_STATE_RANKED_SPLIT_ROLLOVER" )
				RuiSetGameTime( rui, "expireTime", RUI_BADGAMETIME )
			}
			else
			{
				RuiSetString( rui, "modeLockedReason", "" )
			}
			RuiSetBool( rui, "showLockedIcon", true )
			RuiSetBool( rui, "isLocked", true )
		}
		else
		{
			Hud_Show( button )
			if(isLtm)
			{
				Hud_Show( Hud_GetChild(file.panel,"LTMCategory" ) )
				file.hasLTM = true
			}

			                                                          
			if ( slotKey.find( "regular" ) == 0 )
			{
				if ( slotToPlaylistNameMap[ slotKey ] != "" )
					Hud_SetHeight( button, Hud_GetBaseHeight( button ) )
				else
					Hud_SetHeight( button, 0 )
			}

			if(!file.isTrainingCompleted && button != file.slotToButtonMap["training"])
				Hud_SetEnabled( button, false )
			else
				Hud_SetEnabled( button, true )

			if ( slotKey == "regular_1" )
				mainPlaylist = playlistName

			GamemodeSelect_UpdateSelectButton( button, playlistName, slotKey )
		}
	}
	                          
	var backgroundRui = Hud_GetRui( file.gameModeButtonBackground )

	                                       
	string panelImageKey   = GetPanelImageKeyForUISlot( "regular_1" )
	string rotationMapName = GetMapDisplayNameForUISlot( "regular_1" )

	asset panelImageAsset = GetImageFromImageMap( panelImageKey )

	int remainingTimeSeconds = GetPlaylistRotationNextTime() - GetUnixTimestamp()

	RuiSetImage( backgroundRui, "modeImage", panelImageAsset )
	RuiSetString( backgroundRui, "modeNameText", GetPlaylistVarString( mainPlaylist, "survival_takeover_name", "#PL_PLAY_APEX" ) )                               
	RuiSetString( backgroundRui, "mapDisplayName", rotationMapName )      
	RuiSetGameTime( backgroundRui, "rotationGroupNextTime", ClientTime() + remainingTimeSeconds )       
	if ( file.featuredSlot == "" )
		RuiSetInt( backgroundRui, "featuredState", FEATURED_NONE )
	else
		RuiSetInt( backgroundRui, "featuredState", FEATURED_INACTIVE )

}

void function OnCloseButton_Activate( var button )
{
	CloseAllDialogs()
}


                                                                                 
#if DEV
void function ShippingPlaylistCheck()
{
                   
      
		if ( GetCurrentPlaylistVarBool( "this_is_a_dev_playlist", false ) )
			Hud_SetText( Hud_GetChild( file.panel, "PlaylistWarning" ), "Warning: this is not a shipping playlist" )
       
}
#endif



void function UpdateCrafting()
{
                 
		                        
		if ( GetCurrentPlaylistVarBool( "crafting_enabled", true ) )
		{
			         
			RunClientScript( "UICallback_PopulateCraftingPanel", file.craftingPreview )
		}
       
}

const float startBuffer = 0.05

void function AnimateIn()
{
	if( !file.isTrainingCompleted )
	{
		Hud_SetVisible(file.disabledCover, true)
		SetElementAnimations(file.disabledCover, 0, 0.07)
	}else{
		Hud_SetVisible(file.disabledCover, false)
	}
	          
	SetElementAnimations(file.gameModeButtonBackground, 0, 0.07)
	SetElementAnimations(file.slotToButtonMap["ranked"], 0.07, 0.07)
	SetElementAnimations(Hud_GetChild(file.panel,"SurvivalCategory" ), 0.07, 0.07)
	                            
	SetElementAnimations(file.slotToButtonMap["regular_1"], 0.14, 0.07)
	SetElementAnimations(file.slotToButtonMap["regular_2"], 0.17, 0.07)
	        
	SetElementAnimations(file.slotToButtonMap["arenas"], 0.14, 0.07)
	SetElementAnimations(file.slotToButtonMap["arenas_ranked"], 0.21, 0.07)
	SetElementAnimations(Hud_GetChild(file.panel,"ArenasCategory" ), 0.21, 0.07)
	if(file.hasLTM)
	{
		SetElementAnimations(file.slotToButtonMap["ltm"], 0.28, 0.07)
		SetElementAnimations(Hud_GetChild(file.panel,"LTMCategory" ), 0.28, 0.07)
	}
	else
	{
                         
			SetElementAnimations(Hud_GetChild(file.panel,"ArenasExplaination" ), 0.28, 0.07)
        
	}
	                                                     
	SetElementAnimations(file.slotToButtonMap["training"], 0.35,  0.07)
	SetElementAnimations(file.slotToButtonMap["firing_range"], 0.35, 0.07)
	SetElementAnimations(file.slotToButtonMap["event"], 0.35, 0.07)
	SetElementAnimations(file.craftingPreview, 0.35, 0.07)
	RuiSetInt( Hud_GetRui(file.craftingPreview), "animationDirection", 1 )

	        
	if(file.isTrainingCompleted)
	{
		Hud_SetVisible(file.header, true)
		Hud_SetVisible(file.headerWelcome, false)
		SetElementAnimations(file.header, 0.35, 0.07)
	}
	else
	{
		Hud_SetVisible(file.header, false)
		Hud_SetVisible(file.headerWelcome, true)
		SetElementAnimations(file.headerWelcome, 0.35, 0.07)
	}
}

void function SetElementAnimations( var element, float delay, float duration )
{
	RuiSetWallTimeWithOffset( Hud_GetRui( element ), "animateStartTime", startBuffer + delay )
	RuiSetFloat( Hud_GetRui( element ), "animateDuration", duration )
}

void function CrossFadeCraftingArenas(var button, bool showArenas = false)
{
	foreach ( string slotKey, slotButton in file.slotToButtonMap )
	{
		                             
		bool isArenas = slotButton == button && (slotKey == "arenas" || slotKey == "arenas_ranked")
		if(isArenas)
		{
			                                                                
			var craftingRui = Hud_GetRui( file.craftingPreview )
			var arenasRui = Hud_GetRui( file.arenasPreview )
			if(slotKey == "arenas")
			{
				GamemodeSelect_UpdateArenasPreview("survival_arenas")
				RuiSetBool( arenasRui, "isRanked", false )
			}
			else if(slotKey == "arenas_ranked")
			{
				GamemodeSelect_UpdateArenasPreview("survival_arenas_ranked")
				RuiSetBool( arenasRui, "isRanked", true )
			}

			float delayTime = startBuffer

			Hud_SetVisible(file.craftingPreview, true)
			if(showArenas)
				Hud_SetVisible(file.arenasPreview, true)

			float buffer = (showArenas)? 0.0: 0.2                                                                              
			float startOffset = delayTime + buffer

			RuiSetInt( craftingRui, "animationDirection", (showArenas)? -1: 1 )
			RuiSetWallTimeWithOffset( craftingRui, "animateStartTime", startOffset )
			RuiSetFloat( craftingRui, "animateDuration", 0.1 )

			RuiSetInt( arenasRui, "animationDirection", (showArenas)? 1: -1 )
			RuiSetWallTimeWithOffset( arenasRui, "animateStartTime", startOffset )
			RuiSetFloat( craftingRui, "animateDuration", 0.1 )

			break
		}
	}
}

  
 	                                        
  
table<string, string> function GameModeSelect_GetPlaylists()
{
	table<string, string> slotToPlaylistNameMap
	foreach ( slotKey, button  in file.slotToButtonMap )
		slotToPlaylistNameMap[ slotKey ] <- ""

	array<string> playlistNames = GetVisiblePlaylistNames( IsPrivateMatchLobby() )
	foreach ( string plName in playlistNames )
	{
		string uiSlot = GetPlaylistVarString( plName, "ui_slot", "" )
		if ( uiSlot == "" )
			continue

                          
                          
           
        

		if ( uiSlot == "story" )
			continue

		                                                
		if ( uiSlot == "mixtape" )
			uiSlot = "arenas"

		slotToPlaylistNameMap[uiSlot] = plName
	}
	return slotToPlaylistNameMap
}
  
 	                           
  
void function GamemodeSelect_UpdateSelectButton( var button, string playlistName, string slot = "" )
{
	var rui = Hud_GetRui( button )

	if ( playlistName == "" )
		Warning( FUNC_NAME() + ": Function called with empty playlistName!" )
	                                                                                           

	int mapIdx = playlistName != "" ? GetPlaylistActiveMapRotationIndex( playlistName ) : -1

	bool doDebug = (InputIsButtonDown( KEY_LSHIFT ) && InputIsButtonDown( KEY_LCONTROL )) || (InputIsButtonDown( BUTTON_TRIGGER_LEFT_FULL ) && InputIsButtonDown( BUTTON_B ))
	RuiSetString( rui, "modeNameText", GetPlaylistMapVarString( playlistName, mapIdx, "name", "#PLAYLIST_UNAVAILABLE" ) )
	RuiSetString( rui, "playlistName", playlistName )

	RuiSetBool( rui, "doDebug", doDebug )

	string descText = GetPlaylistMapVarString( playlistName, mapIdx, "description", "#HUD_UNKNOWN" )
	RuiSetString( rui, "modeDescText", descText )
	RuiSetString( rui, "modeLockedReason", "" )
	RuiSetBool( rui, "alwaysShowDesc", false )
	RuiSetBool( rui, "isPartyLeader", false )
	RuiSetBool( rui, "showLockedIcon", true )

	string imageKey  = GetPlaylistMapVarString( playlistName, mapIdx, "image", "" )
	asset imageAsset = GetImageFromImageMap( imageKey )
	asset thumbnailAsset = GetThumbnailImageFromImageMap( imageKey )
	string iconKey = GetPlaylistMapVarString( playlistName, mapIdx, "lobby_mini_icon", "" )
	asset iconAsset = GetImageFromMiniIconMap( iconKey )
	RuiSetImage( Hud_GetRui( button ), "modeImage", imageAsset )
	RuiSetImage( Hud_GetRui( button ), "thumbnailImage", thumbnailAsset )
	RuiSetImage( Hud_GetRui( button ), "expandArrowImage", iconAsset )

	bool isPlaylistAvailable = Lobby_IsPlaylistAvailable( playlistName )
	Hud_SetLocked( button, !isPlaylistAvailable )
	int playlistState = Lobby_GetPlaylistState( playlistName )
	string playlistStateString = Lobby_GetPlaylistStateString( Lobby_GetPlaylistState( playlistName ) )

	if ( playlistState == ePlaylistState.ACCOUNT_LEVEL_REQUIRED )
	{
		int level = GetPlaylistVarInt( playlistName, "account_level_required", 0 )
		playlistStateString = Localize( playlistStateString, level )
	}

	RuiSetString( rui, "modeLockedReason", playlistStateString )

	                                    
	RuiSetGameTime( rui, "expireTime", RUI_BADGAMETIME )

	bool hideCountDown = GetPlaylistVarBool( playlistName, "force_hide_schedule_block_countdown", false )
	if (!hideCountDown)
	{
		PlaylistScheduleData scheduleData = Playlist_GetScheduleData( playlistName )
		if ( scheduleData.currentBlock != null )
		{
			TimestampRange currentBlock = expect TimestampRange(scheduleData.currentBlock)
			int remainingDuration       = currentBlock.endUnixTime - GetUnixTimestamp()
			RuiSetGameTime( rui, "expireTime", ClientTime() + remainingDuration )
		}
	}

	int emblemMode = DRAW_NONE
	if ( IsRankedPlaylist( playlistName ) )
	{
		emblemMode = DRAW_RANK
		int rankScore      = GetPlayerRankScore( GetLocalClientPlayer() )
		int ladderPosition = Ranked_GetLadderPosition( GetLocalClientPlayer() )

		if ( Ranked_ShouldUpdateWithComnunityUserInfo( rankScore, ladderPosition ) )                                  
			file.rankedRUIToUpdate = rui


		PopulateRuiWithRankedBadgeDetails( rui, rankScore, ladderPosition )
	}
                       
	else if ( IsArenasRankedPlaylist( playlistName ) )
	{
		emblemMode = DRAW_RANK
		int rankScore      = GetPlayerArenasRankScore( GetLocalClientPlayer() )
		int ladderPosition = ArenasRanked_GetLadderPosition( GetLocalClientPlayer() )
		if ( ArenasRanked_ShouldUpdateWithComnunityUserInfo( rankScore, ladderPosition ) )                                  
			file.rankedRUIToUpdate = rui
		PopulateRuiWithArenasRankedBadgeDetails( rui, rankScore, ladderPosition )
	}
      
	else
	{
		asset emblemImage = GetModeEmblemImage( playlistName )
		if ( emblemImage != $"" )
		{
			emblemMode = DRAW_IMAGE
			RuiSetImage( rui, "emblemImage", emblemImage )
		}
	}
	RuiSetInt( rui, "emblemMode", emblemMode )

	file.selectButtonPlaylistNameMap[button] <- playlistName

	if ( file.featuredSlot == "" || slot == "" )
	{
		RuiSetInt( rui, "featuredState", FEATURED_NONE )
	}
	else
	{
		if ( slot == file.featuredSlot )
		{
			RuiSetInt( rui, "featuredState", FEATURED_ACTIVE )
			RuiSetString( rui, "featuredString", file.featuredSlotString )
		}
		else
			RuiSetInt( rui, "featuredState", FEATURED_INACTIVE )
	}
	int RotationTimeLeft = GetPlaylistActiveMapRotationTimeLeft( playlistName )

	string mapName =  GetPlaylistMapVarString( playlistName, mapIdx, "map_name", "" )
	RuiSetString( rui, "mapDisplayName", mapName )

	if(RotationTimeLeft > 0)
	{
		RuiSetGameTime( rui, "rotationGroupNextTime", ClientTime() + RotationTimeLeft - 1)                            
	}

}
                       
void function GamemodeSelect_UpdateArenasPreview( string playlistName )
{
	int mapsCount = GetPlaylistMapsCount( playlistName )
	int maxMapsToShow = 5
	var rui = Hud_GetRui( file.arenasPreview )

	                
	for( int i = 1; i <= maxMapsToShow; i++ )
	{
		RuiSetString( rui, "arena" + i + "Name", "" )
		RuiSetImage( rui, "arenaThumbnailImage" + i, $"" )
	}

	int mapNumber = maxMapsToShow - ( mapsCount - 1 )
	if( mapNumber < 1 )
		mapNumber = 1

	int activeMapIdx = GetPlaylistActiveMapRotationIndex( playlistName )

	RuiSetInt( rui, "totalMaps", mapsCount )

	while ( mapNumber <= maxMapsToShow )
	{
		string mapName = GetPlaylistMapVarString( playlistName, activeMapIdx, "map_name", "bug this!" )
		string imageKey  = GetPlaylistMapVarString( playlistName, activeMapIdx, "image", "" )
		asset thumbnailAsset = GetThumbnailImageFromImageMap( imageKey )

		RuiSetString( rui, "arena" + mapNumber + "Name", mapName )
		RuiSetImage( rui, "arenaThumbnailImage" + mapNumber, thumbnailAsset )

		mapNumber++
		activeMapIdx++
		if( activeMapIdx > ( mapsCount - 1 ) )
			activeMapIdx = 0
	}
}
      


  
 	                         
  
void function GamemodeSelect_PlayVideo( var button, string playlistName )
{
	string videoKey         = GetPlaylistVarString( playlistName, "video", "" )
	asset desiredVideoAsset = GetBinkFromBinkMap( videoKey )

	if ( desiredVideoAsset != $"" )
		file.currentVideoAsset = $""                                                                                             
	Signal( uiGlobal.signalDummy, "GamemodeSelect_EndVideoStopThread" )
	Assert( file.currentVideoAsset == $"" )

	if ( desiredVideoAsset != $"" )
	{
		if ( file.videoChannel == -1 )
			file.videoChannel = ReserveVideoChannel()

		StartVideoOnChannel( file.videoChannel, desiredVideoAsset, true, 0.0 )
		file.currentVideoAsset = desiredVideoAsset
	}

	var rui = Hud_GetRui( button )
	RuiSetBool( rui, "hasVideo", videoKey != "" )
	RuiSetInt( rui, "channel", file.videoChannel )
	if ( file.currentVideoAsset != $"" )
		thread VideoStopThread( button )
}

void function VideoStopThread( var button )
{
	EndSignal( uiGlobal.signalDummy, "GamemodeSelect_EndVideoStopThread" )

	OnThreadEnd( function() : ( button ) {
		if ( IsValid( button ) )
		{
			var rui = Hud_GetRui( button )
			RuiSetInt( rui, "channel", -1 )
		}
		if ( file.currentVideoAsset != $"" )
		{
			StopVideoOnChannel( file.videoChannel )
			file.currentVideoAsset = $""
		}
	} )

	while ( GetFocus() == button )
		WaitFrame()

	wait 0.3
}


  
 	                
  
void function ClearFeaturedSlotAfterDelay()
{
	float startTime = UITime()
	while ( UITime() - startTime < 3.0 && GetActiveMenu() == file.panel )
	{
		WaitFrame()
	}

	GamemodeSelect_SetFeaturedSlot( "" )
	if ( GetActiveMenu() == GetParentMenu( file.panel ) )
		UpdateOpenModeSelectDialog()
}

void function Ranked_OnUserInfoUpdatedInGameModeSelect( string hardware, string id )
{
	if ( !IsConnected() )
		return

	if ( !IsLobby() )
		return

	if ( hardware == "" && id == "" )
		return

	CommunityUserInfo ornull cui = GetUserInfo( hardware, id )

	if ( cui == null )
		return

	expect CommunityUserInfo( cui )

	if ( cui.hardware == GetUnspoofedPlayerHardware() && cui.uid == GetPlayerUID() )                                      
	{
		if ( file.rankedRUIToUpdate != null  )                                                                                                                                
		{
			PopulateRuiWithRankedBadgeDetails( file.rankedRUIToUpdate, cui.rankScore, cui.rankedLadderPos )
		}

	}
}

array<string> function GetPlaylistsInRegularSlots()
{
	array<string> playlistNames = GetVisiblePlaylistNames( IsPrivateMatchLobby() )
	array<string> regularList
	foreach ( string plName in playlistNames )
	{
		string uiSlot = GetPlaylistVarString( plName, "ui_slot", "" )

		if ( uiSlot.find( "regular" ) == 0 )
			regularList.append( plName )
	}

	return regularList
}

  
 	                       
  
void function GamemodeSelect_SetFeaturedSlot( string slot, string modeString = "#HEADER_NEW_MODE" )
{
	file.featuredSlot = slot
	file.featuredSlotString = modeString
}

