-- CONSTANTS
GOLD_MULTIPLIER = 2
XP_MULTIPLIER = 2
RESPAWN_SCALE = .5

if GameSetup == nil then
    GameSetup = class({})
  end

  --nil will not force a hero selection
local forceHero = nil



function GameSetup:init()
  if IsInToolsMode() then  --debug build
    local GameMode = GameRules:GetGameModeEntity()
    --skip all the starting game mode stages e.g picking screen, showcase, etc
    GameRules:EnableCustomGameSetupAutoLaunch(false)
    GameRules:SetCustomGameSetupAutoLaunchDelay(15)
    GameRules:SetHeroSelectionTime(10)
    GameRules:SetStrategyTime(0)
    GameRules:SetPreGameTime(0)
    GameRules:SetShowcaseTime(0)
    GameRules:SetPostGameTime(5)
    GameMode:SetDraftingBanningTimeOverride(1)

    --disable some setting which are annoying then testing
    
    GameMode:SetAnnouncerDisabled(true)
    GameMode:SetKillingSpreeAnnouncerDisabled(true)
    GameMode:SetDaynightCycleDisabled(false)
    GameMode:DisableHudFlip(true)
    GameMode:SetDeathOverlayDisabled(true)
    GameMode:SetWeatherEffectsDisabled(true)

    --disable music events
    GameRules:SetCustomGameAllowHeroPickMusic(false)
    GameRules:SetCustomGameAllowMusicAtGameStart(false)
    GameRules:SetCustomGameAllowBattleMusic(false)

    --multiple players can pick the same hero
    GameRules:SetSameHeroSelectionEnabled(true)

    --force single hero selection (optional)
    if forceHero ~= nil then
      GameMode:SetCustomGameForceHero(forceHero)
    end

    --listen to game state event
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(self, "OnStateChange"), self)

  else --release build
    local GameMode = GameRules:GetGameModeEntity()
    --put your rules here
    GameMode:SetDraftingBanningTimeOverride(15)

  end
  local GameMode = GameRules:GetGameModeEntity()
  GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)
  GameRules:SetFilterMoreGold(true)
  
  GameMode:SetRespawnTimeScale(RESPAWN_SCALE)
  GameMode:SetModifyGoldFilter( Dynamic_Wrap( wwoods, "FilterGold" ), self )
  GameMode:SetModifyExperienceFilter( Dynamic_Wrap( wwoods, "FilterXP" ), self )
  GameMode:SetBountyRunePickupFilter( Dynamic_Wrap( wwoods, "FilterBounty" ), self )

  GameMode:SetUseDefaultDOTARuneSpawnLogic(true)
  -- why don't these 2 work?
  --GameMode:SetBountyRuneSpawnInterval(45)
end

function GameSetup:OnStateChange()
  --random hero once we reach strategy phase
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_STRATEGY_TIME then
    GameSetup:RandomForNoHeroSelected()
  end
end


function GameSetup:RandomForNoHeroSelected()
    --NOTE: GameRules state must be in HERO_SELECTION or STRATEGY_TIME to pick heroes
    --loop through each player on every team and random a hero if they haven't picked
  local maxPlayers = 5
  for teamNum = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS do
    for i=1, maxPlayers do
      local playerID = PlayerResource:GetNthPlayerIDOnTeam(teamNum, i)
      if playerID ~= nil then
        if not PlayerResource:HasSelectedHero(playerID) then
          local hPlayer = PlayerResource:GetPlayer(playerID)
          if hPlayer ~= nil then
            hPlayer:MakeRandomHeroSelection()
          end
        end
      end
    end
  end
end

function wwoods:FilterGold(filterTable)
  local gold = filterTable["gold"]
  local playerID = filterTable["player_id_const"]
  local reason = filterTable["reason_const"]
  local reliable = filterTable["reliable"] == 1

  if reason < 10 then
    return true
  end
  filterTable["gold"] = gold * GOLD_MULTIPLIER
  print("gold modified to "..filterTable["gold"].." from"..gold)
  return true
end

function wwoods:FilterXP(filterTable)
  local xp = filterTable["experience"]
  local playerID = filterTable["player_id_const"]
  local reason = filterTable["reason_const"]
  local reliable = filterTable["reliable"] == 1

  filterTable["experience"] = xp * XP_MULTIPLIER
  print(playerID.." recieved "..filterTable["experience"].." xp")
  return true
end

function wwoods:FilterBounty(filterTable)
  local playerID = filterTable["player_id_const"]
  local xp = filterTable["xp_bounty"]
  local gold = filterTable["gold_bounty"]

  filterTable["gold_bounty"] = gold * GOLD_MULTIPLIER
  print("Bounty rune picked up for"..filterTable["gold_bounty"].." gold (Originially:) "..gold)
  return true
end