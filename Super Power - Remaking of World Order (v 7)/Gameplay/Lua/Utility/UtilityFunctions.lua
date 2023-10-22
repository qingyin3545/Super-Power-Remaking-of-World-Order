-- UtilityFunctions
-- Author: linco
-- DateCreated: 2/13/2016 11:16:01 AM
--------------------------------------------------------------


-------------If two players are AT WAR?

function PlayersAtWar(iPlayer, ePlayer)
	local iTeam = Teams[iPlayer:GetTeam()];
	local eTeamIndex = ePlayer:GetTeam();
	if iTeam:IsAtWar(eTeamIndex) then
		return true;
	else
		return false;
	end
end

---------If the AI player is at war with Human?

function PlayerAtWarWithHuman(player)
	local CurrentPlayerTeam = Teams[player:GetTeam()]
	local IsWarWithHuman = false;

	for playerID, HumanPlayer in pairs(Players) do
		if IsWarWithHuman then
			break;
		end
		if HumanPlayer:IsHuman() and CurrentPlayerTeam:IsAtWar(HumanPlayer:GetTeam()) then
			print("Human is at war with this AI!")
			IsWarWithHuman = true;
		end
	end
	return IsWarWithHuman;
end

---------If the AI has the chance to become the Boss?
function AICanBeBoss(player)
	local WorldCityTotal = Game.GetNumCities()
	local WorldPopTotal = Game.GetTotalPopulation()

	local AICityCount = player:GetNumCities()
	local AIPopCount = player:GetTotalPopulation()
	local MajorCivNum = 0
	for id, pPlayer in pairs(Players) do
		if pPlayer:IsEverAlive() then
			if not (pPlayer:IsMinorCiv() or pPlayer:IsBarbarian()) then
				MajorCivNum = MajorCivNum + 1
			end
		end
	end
	print("total civ is: " .. MajorCivNum)

	if player:IsHuman() or player:IsBarbarian() or player:IsMinorCiv() then
		return false
	end

	local CapitalDistance = 0;
	local WorldSizeLength = Map.GetGridSize();
	if Players[Game.GetActivePlayer()] ~= nil and Players[Game.GetActivePlayer()]:GetCapitalCity() ~= nil and player:GetCapitalCity() ~= nil then
		local HumanCapital  = Players[Game.GetActivePlayer()]:GetCapitalCity();
		local ThisAICapital = player:GetCapitalCity();
		CapitalDistance     = Map.PlotDistance(HumanCapital:GetX(), HumanCapital:GetY(), ThisAICapital:GetX(),
			ThisAICapital:GetY())
	end
	if AICityCount >= 15 or AICityCount >= WorldCityTotal / MajorCivNum or AIPopCount >= WorldPopTotal / MajorCivNum or CapitalDistance >= WorldSizeLength / 3 then
		print("This AI can become a Boss!")
		return true
	else
		return false
	end
end

-----------------------------------------------Plot Functions------------------------------------------------------
function PlotIsVisibleToHuman(plot) --------------------Is the plot can be seen by Human
	for playerID, HumanPlayer in pairs(Players) do
		if HumanPlayer:IsHuman() then
			local HumanPlayerTeamIndex = HumanPlayer:GetTeam()
			if plot:IsVisible(HumanPlayerTeamIndex) then
				--		   	    print ("Human can see this plot! So stop Cheating!")	
				return true
			else
				--				print ("Human CANNOT see this plot! Let's Cheat!")
				return false
			end

			break
		end
	end
end

function isFriendlyCity(pUnit, pCity) --------------Is the plot a Friendly City?
	local bFriendly = (pCity:GetTeam() == pUnit:GetTeam())
	--  bFriendly = (bFriendly and not pCity:IsPuppet())
	bFriendly = (bFriendly and not pCity:IsResistance())
	bFriendly = (bFriendly and not pCity:IsRazing())
	bFriendly = (bFriendly and not (pCity:IsOccupied() and not pCity:IsNoOccupiedUnhappiness()))
	return bFriendly
end

------------------------------------------------Military/Unit Functions------------------------------------------------------

function GetCivSpecificUnit(player, sUnitClass)
	local sUnitType = -1
	local sCivType = GameInfo.Civilizations[player:GetCivilizationType()].Type

	for pOverride in GameInfo.Civilization_UnitClassOverrides { CivilizationType = sCivType, UnitClassType = sUnitClass } do
		sUnitType = pOverride.UnitType
		break
	end

	if sUnitType == -1 or sUnitType == nil then
		sUnitType = GameInfo.UnitClasses[sUnitClass].DefaultUnit
	end

	return sUnitType
end

function GetUpgradeUnit(player, sUnitType)
	local sNewUnitClass = GameInfo.Units[sUnitType].GoodyHutUpgradeUnitClass

	if (sNewUnitClass ~= nil) then
		local sUpgradeUnitType = GetCivSpecificUnit(player, sNewUnitClass)

		if (sUpgradeUnitType ~= nil and Teams[player:GetTeam()]:IsHasTech(GameInfoTypes[GameInfo.Units[sUpgradeUnitType].PrereqTech])) then
			return sUpgradeUnitType
		end
	end

	return nil
end

function SatelliteLaunchEffects(unit, city, player)
	if unit == nil or city == nil or player == nil or player:GetNumCities() == 0
		or not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SATELLITE_UNIT"].ID)
	then
		return
	end

	if unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_SPUTNIK then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_SPUTNIK"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_RECONNAISSANCE then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_RECONNAISSANCE"], 1)
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_RECONNAISSANCE_SMALL"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_GPS then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_GPS"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_APOLLO11 then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_APOLLO11"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_HUBBLE then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_HUBBLE"], 1)
		player:InitUnit(GameInfoTypes.UNIT_SCIENTIST, city:GetX(), city:GetY(), UNITAI_SCIENTIST):JumpToNearestValidPlot()
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_WEATHER then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_WEATHER"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_TIANGONG then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_TIANGONG"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ECCM then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_ECCM"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ENVIRONMENT then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_ENVIRONMENT"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ANTIFALLOUT then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_ANTIFALLOUT"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_RESOURCEPLUS then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_RESOURCEPLUS"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_SPACE_ELEVATOR then
		city:SetNumRealBuilding(GameInfoTypes["BUILDING_SPACE_ELEVATOR"], 1)
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ORBITAL_STRIKE then
		player:InitUnit(GameInfo.Units.UNIT_ORBITAL_STRIKE.ID, city:GetX(), city:GetY(), UNITAI_MISSILE_AIR)
		print("Rods from God built!")
	end

	SatelliteEffectsGlobal(unit);

	print("Satellite unit's effect is ON!")
end -----------function END

function SatelliteEffectsGlobal(unit)
	if not unit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_SATELLITE_UNIT"].ID) then
		return
	end


	if unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_WEATHER then
		print("Satellite Effects Global:Weather Control!")
		for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
			local plot = Map.GetPlotByIndex(plotLoop)

			if plot:GetFeatureType() == FeatureTypes.NO_FEATURE and not plot:IsHills() and not plot:IsMountain() then
				if plot:GetTerrainType() == TerrainTypes.TERRAIN_DESERT then
					local pPlotX = plot:GetX()
					local pPlotY = plot:GetY()
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_FOOD, 2)
				end
			end
		end
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ENVIRONMENT then
		print("Satellite Effects Global:Environment Transform!")
		for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
			local plot = Map.GetPlotByIndex(plotLoop)


			if plot:GetTerrainType() == TerrainTypes.TERRAIN_TUNDRA then
				if plot:GetFeatureType() == FeatureTypes.NO_FEATURE and not plot:IsHills() and not plot:IsMountain() then
					local pPlotX = plot:GetX()
					local pPlotY = plot:GetY()
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_PRODUCTION, 1)
				end
			end

			if plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW and not plot:IsMountain() then
				local pPlotX = plot:GetX()
				local pPlotY = plot:GetY()
				if plot:IsHills() then
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_PRODUCTION, 2)
				else
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_PRODUCTION, 1)
					Game.SetPlotExtraYield(pPlotX, pPlotY, GameInfoTypes.YIELD_FOOD, 1)
				end
			end
		end
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_ANTIFALLOUT then
		print("Satellite Effects Global:Remove Fallout!")
		for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
			local plot = Map.GetPlotByIndex(plotLoop)

			if plot:GetFeatureType() == FeatureTypes.FEATURE_FALLOUT then
				plot:SetFeatureType(-1)
			end
		end
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_RESOURCEPLUS then
		print("Satellite Effects Global:Resource Bonus")
		for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
			local plot = Map.GetPlotByIndex(plotLoop)

			if plot:GetNumResource() >= 2 and not plot:IsCity() then
				-- If you only change the resource amount on the plot, the player's resource quantity will not change! You must remove then add the improvement to make the change!
				local iImprovement = plot:GetImprovementType()
				plot:SetImprovementType(-1)
				plot:ChangeNumResource(4)
				plot:SetImprovementType(iImprovement)
			end
		end
	elseif unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_GPS or unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_RECONNAISSANCE or unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_APOLLO11 or unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_HUBBLE or unit:GetUnitClassType() == GameInfoTypes.UNITCLASS_SATELLITE_TIANGONG then
		for playerID, player in pairs(Players) do
			if player:GetNumCities() > 0 and not player:IsMinorCiv() and not player:IsBarbarian() then
				print("Satellite Effects Global:Effects!")
				local CapitalCity = player:GetCapitalCity()
				print("Find Capital")
				if unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_SATELLITE_GPS.ID then
					CapitalCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_GPS_SMALL"], 1)
				elseif unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_SATELLITE_RECONNAISSANCE.ID then
					CapitalCity:SetNumRealBuilding(GameInfoTypes["BUILDING_SATELLITE_RECONNAISSANCE_SMALL"], 1)
				elseif unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_SATELLITE_APOLLO11.ID then
					print("Free Tech for everyone!")
					player:SetNumFreeTechs(1)
				elseif unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_SATELLITE_HUBBLE.ID then
					local pPlot = CapitalCity
					local NewUnit = player:InitUnit(GameInfoTypes.UNIT_SCIENTIST, pPlot:GetX(), pPlot:GetY(),
						UNITAI_SCIENTIST)
					NewUnit:JumpToNearestValidPlot()
				elseif unit:GetUnitClassType() == GameInfo.UnitClasses.UNITCLASS_SATELLITE_TIANGONG.ID then
					local pPlot = CapitalCity
					local NewUnit = player:InitUnit(GameInfoTypes.UNIT_ENGINEER, pPlot:GetX(), pPlot:GetY(),
						UNITAI_ENGINEER)
					NewUnit:JumpToNearestValidPlot()
				end
			end
		end
	end
end -----------function END

----------------------------------City Functions----------------------------

---------------------Policy Per Turn Effects
function SetPolicyPerTurnEffects(playerID)
end

if (PreGame.GetGameOption("GAMEOPTION_SP_IMMIGRATION_OFF") == 1) then
	print("International Immigration - OFF!");
else
	-----------International Immigration Counter Check
	function CheckMoveOutCounter(HumanPlayerID, AIPlayerID)
		local HumanPlayer = Players[HumanPlayerID];
		local AIPlayer = Players[AIPlayerID];

		if HumanPlayer == nil or AIPlayer == nil then
			print("No players");
			return;
		end

		print("Human Player: " .. tostring(HumanPlayer:GetName()));
		print("AI Player: " .. tostring(AIPlayer:GetName()));

		local iRegressand = 30;
		if Game.GetGameSpeedType() == 0 then -- GAMESPEED_MARATHON
			iRegressand = 60;
		elseif Game.GetGameSpeedType() == 1 then -- GAMESPEED_EPIC
			iRegressand = 40;
		elseif Game.GetGameSpeedType() == 2 then -- GAMESPEED_STANDARD
			iRegressand = 30;
		elseif Game.GetGameSpeedType() == 3 then -- GAMESPEED_QUICK
			iRegressand = 20;
		end

		iCount = AIPlayer:GetImmigrationCounter(HumanPlayerID);

		local MoveOutTeam, MoveInTeam;

		local MoveOutCounterBase = HumanPlayer:GetInfluenceLevel(AIPlayerID) - AIPlayer:GetInfluenceLevel(HumanPlayerID);
		local MoveOutCounterMod  = 1;

		print("Move Out Counter by the Influence Base: " .. MoveOutCounterBase);

		local MoveInPlayer  = nil;
		local MoveOutPlayer = nil;
		if MoveOutCounterBase > 0 then
			MoveOutPlayer = AIPlayer;
			MoveInPlayer  = HumanPlayer;
		elseif MoveOutCounterBase < 0 then
			MoveOutPlayer = HumanPlayer;
			MoveInPlayer  = AIPlayer
		end

		if MoveInPlayer == nil then
			return { MoveOutCounterBase, iRegressand, iCount };
		else
			MoveOutTeam = Teams[MoveOutPlayer:GetTeam()];
			MoveInTeam  = Teams[MoveInPlayer:GetTeam()];
		end

		------------------------------------------Player is not able to accept----------------------


		if MoveInPlayer:GetExcessHappiness() <= 0 or MoveInPlayer:GetNumResourceAvailable(GameInfoTypes["RESOURCE_CONSUMER"], true) <= 0 then
			MoveOutCounterBase = 0
			print("The Player is unhappy or No Resources! " .. MoveOutCounterBase)
		end

		if MoveInPlayer:GetCurrentEra() >= GameInfo.Eras["ERA_MODERN"].ID and MoveInPlayer:GetNumResourceAvailable(GameInfoTypes["RESOURCE_ELECTRICITY"], true) <= 0 then
			MoveOutCounterBase = 0
			print("The Player is lacking of ELECTRICITY! " .. MoveOutCounterBase)
		end


		------------------------------------------Diplomacy Modifier--------------------------------
		if PlayersAtWar(MoveOutPlayer, MoveInPlayer) then
			MoveOutCounterBase = 0
			print("At War! No Immigration: " .. MoveOutCounterBase)
		end

		if MoveInTeam:IsAllowsOpenBordersToTeam(MoveOutPlayer:GetTeam()) then
			MoveOutCounterMod = MoveOutCounterMod + 1
			print("Open Borders +100% " .. MoveOutCounterMod)
		end

		if MoveOutPlayer:IsDenouncedPlayer(MoveInPlayerID) or MoveInPlayer:IsDenouncedPlayer(MoveOutPlayerID) then
			MoveOutCounterMod = MoveOutCounterMod - 0.5
			print("Denouncing! -50% " .. MoveOutCounterMod)
		end

		if MoveOutPlayer:IsDoF(MoveInPlayerID) then
			MoveOutCounterMod = MoveOutCounterMod + 0.5
			print("Has Friendship! +50% " .. MoveOutCounterMod)
		end


		------------------------------------------Religion Modifier---------------------------------
		if MoveInPlayer:GetReligionCreatedByPlayer() ~= nil and MoveInPlayer:GetReligionCreatedByPlayer() > 0 then
			local MoveInPlayerReligion = MoveInPlayer:GetReligionCreatedByPlayer()
			if MoveOutPlayer:HasReligionInMostCities(MoveInPlayerReligion) then
				MoveOutCounterMod = MoveOutCounterMod + 1
				print("Same Religion +100%  " .. MoveOutCounterMod)
			end
		end


		------------------------------------------Happiness Modifier--------------------------------
		if MoveInPlayer:IsHuman() then
			if MoveInPlayer:GetExcessHappiness() >= 150 then
				MoveOutCounterMod = MoveOutCounterMod + 0.5
			elseif MoveInPlayer:GetExcessHappiness() < 150 and MoveInPlayer:GetExcessHappiness() >= 100 then
				MoveOutCounterMod = MoveOutCounterMod + 0.25
			elseif MoveInPlayer:GetExcessHappiness() < 50 and MoveInPlayer:GetExcessHappiness() >= 20 then
				MoveOutCounterMod = MoveOutCounterMod - 0.25
			elseif MoveInPlayer:GetExcessHappiness() < 20 and MoveInPlayer:GetExcessHappiness() >= 0 then
				MoveOutCounterMod = MoveOutCounterMod - 0.5
			elseif MoveInPlayer:GetExcessHappiness() < 0 then
				MoveOutCounterMod = 0
			end

			print("Human Move in Special Mod  " .. MoveOutCounterMod)
		end


		if MoveOutPlayer:IsHuman() then
			if MoveOutPlayer:GetExcessHappiness() >= 150 then
				MoveOutCounterMod = MoveOutCounterMod - 0.5
			elseif MoveOutPlayer:GetExcessHappiness() < 150 and MoveOutPlayer:GetExcessHappiness() >= 100 then
				MoveOutCounterMod = MoveOutCounterMod - 0.25
			elseif MoveOutPlayer:GetExcessHappiness() < 20 and MoveOutPlayer:GetExcessHappiness() >= 0 then
				MoveOutCounterMod = MoveOutCounterMod + 0.25
			elseif MoveOutPlayer:GetExcessHappiness() < 0 then
				MoveOutCounterMod = MoveOutCounterMod + 0.5
			end

			print("Human Move out Special Mod  " .. MoveOutCounterMod)
		end

		if MoveOutPlayer:HasPolicy(GameInfoTypes["POLICY_IRON_CURTAIN"]) then
			MoveOutCounterMod = MoveOutCounterMod - 0.5
			print("Internationalism -50%  " .. MoveOutCounterMod)
		end

		if MoveInPlayer:HasPolicy(GameInfoTypes["POLICY_TREATY_ORGANIZATION"]) then
			MoveOutCounterMod = MoveOutCounterMod + 1.0
			print("Beacon of Democracy +100%  " .. MoveOutCounterMod)
		end


		------------------------------------------Trait Modifier------------------------------------
		if MoveInPlayer:GetExcessHappiness() > MoveOutPlayer:GetExcessHappiness()
			and GameInfo.Leader_Traits { LeaderType = GameInfo.Leaders[MoveInPlayer:GetLeaderType()].Type, TraitType =
			"TRAIT_RIVER_EXPANSION" } ()
			and (GameInfo.Traits["TRAIT_RIVER_EXPANSION"].PrereqPolicy == nil or (GameInfo.Traits["TRAIT_RIVER_EXPANSION"].PrereqPolicy
				and MoveInPlayer:HasPolicy(GameInfoTypes[GameInfo.Traits["TRAIT_RIVER_EXPANSION"].PrereqPolicy])))
		then
			MoveOutCounterMod = MoveOutCounterMod + 0.5
			print("American UA to Civilizations with less Happiness +50%  " .. MoveOutCounterMod)
		end


		--------------------------------------------------------------------------------------------


		if MoveOutCounterMod < 0 then
			MoveOutCounterMod = 0
		end

		local MoveoutCounterFinal = math.floor(MoveOutCounterMod * MoveOutCounterBase)


		print("MoveoutCounterFinal:" .. MoveoutCounterFinal)

		return { MoveoutCounterFinal, iRegressand, iCount };
	end ---------function end
end

function SetCityLevelbyDistance(city)
  -- keep for compatibility
end -------------Function End

----------------------------------Misc----------------------------

----------Set up Citadel Units
function SetCitadelUnits(iPlayer, x, y)
	if iPlayer == nil then
		return
	end

	local pPlayer = Players[iPlayer]
	local pTeam = Teams[pPlayer:GetTeam()]
	local pPlot = Map.GetPlot(x, y)

	local CitadelUnitID = GameInfo.UnitPromotions["PROMOTION_CITADEL_DEFENSE"].ID

	local CitadelUnitEarly = GameInfoTypes.UNIT_CITADEL_EARLY
	local CitadelUnitMid = GameInfoTypes.UNIT_CITADEL_MID
	local CitadelUnitLate = GameInfoTypes.UNIT_CITADEL_LATE

	local unitCount = pPlot:GetNumUnits()
	local iCounter = 1

	---------------This Event will be triggered TWICE , so must delete one of them to stop it from creating two units
	for i = 0, unitCount - 1, 1 do
		local pFoundUnit = pPlot:GetUnit(i)
		if pFoundUnit ~= nil and pFoundUnit:IsHasPromotion(CitadelUnitID) then
			iCounter = 3
			print("Already there!")
		end
	end

	if iCounter < 2 then
		if pTeam:IsHasTech(GameInfoTypes["TECH_ADV_FLIGHT"]) then
			pPlayer:InitUnit(CitadelUnitLate, x, y, UNITAI_RANGED)
		elseif pTeam:IsHasTech(GameInfoTypes["TECH_MILITARY_LOGISTICS"]) then
			pPlayer:InitUnit(CitadelUnitMid, x, y, UNITAI_RANGED)
		elseif pTeam:IsHasTech(GameInfoTypes["TECH_GUNPOWDER"]) then
			pPlayer:InitUnit(CitadelUnitEarly, x, y, UNITAI_RANGED)
		end
	end
end

function RemoveConflictFeatures(plot)
	if plot == nil then
		return
	end

	if plot:GetFeatureType() == FeatureTypes.FEATURE_FOREST or plot:GetFeatureType() == FeatureTypes.FEATURE_MARSH or plot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE then
		plot:SetFeatureType(-1)
		print("ConflictFeatures Removed!")
	end
end

-------------------AI Force build units

----------------------Make AI build unit of different types so they can work together----------------------------------------------------

----------Oringinal Codes from William Howard's Policy - Free Warrior' mod

function AIForceBuildAirEscortUnits(unitX, unitY, player)
	if unitX == nil or unitY == nil or player == nil or player:IsLackingTroops() then
		return
	end


	if player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_ALUMINUM"], true) <= 3
		and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 15 then
		print("Not enough resources!")
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_TRIPLANE")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end

	local PlayerEra = player:GetCurrentEra()
	local NewUnitEXP = PlayerEra * 15
	if player:GetCapitalCity() ~= nil then
		NewUnitEXP = NewUnitEXP + player:GetCapitalCity():GetProductionExperience()
	end

	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_DEFENSE_AIR)

	AINewUnitSetUp(NewUnit, NewUnitEXP)
	NewUnit:PushMission(GameInfoTypes.MISSION_AIRPATROL)

	print("Stupid AI need more Fighters! Now they are set intercepting!")
end

function AIForceBuildNavalEscortUnits(unitX, unitY, player)
	if unitX == nil or unitY == nil or player == nil or player:IsLackingTroops() then
		return
	end

	if player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_IRON"], true) <= 3
		and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 6 then
		print("Not enough resources!")
		return
	end


	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_GALLEASS")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end


	local PlayerEra = player:GetCurrentEra()
	local NewUnitEXP = PlayerEra * 5
	if player:GetCapitalCity() ~= nil then
		NewUnitEXP = NewUnitEXP + player:GetCapitalCity():GetProductionExperience()
	end

	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_ATTACK_SEA)

	AINewUnitSetUp(NewUnit, NewUnitEXP)

	print("Stupid AI need more Naval Melee Ships!")
end

function AIForceBuildNavalHRUnits(unitX, unitY, player)
	if unitX == nil or unitY == nil or player == nil or player:IsLackingTroops() then
		return
	end

	if player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 4 then
		print("Not enough resources!")
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_FIRE_SHIP")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end

	local PlayerEra = player:GetCurrentEra()
	local NewUnitEXP = PlayerEra * 10
	if player:GetCapitalCity() ~= nil then
		NewUnitEXP = NewUnitEXP + player:GetCapitalCity():GetProductionExperience()
	end

	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_ASSAULT_SEA)

	AINewUnitSetUp(NewUnit, NewUnitEXP)
	print("Stupid AI need more Naval Hit and Run Ships!")
end

function AIForceBuildNavalRangedUnits(unitX, unitY, player)
	if unitX == nil or unitY == nil or player == nil or player:IsLackingTroops() then
		return
	end

	if player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_IRON"], true) <= 3
		and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 6 then
		print("Not enough resources!")
		return
	end

	if player:GetCurrentEra() >= 5 and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_COAL"], true) <= 4
		and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 15 then
		print("Not enough resources!")
		return
	end


	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_GREAT_GALLEASS")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end

	local PlayerEra = player:GetCurrentEra()
	local NewUnitEXP = PlayerEra * 10
	if player:GetCapitalCity() ~= nil then
		NewUnitEXP = NewUnitEXP + player:GetCapitalCity():GetProductionExperience()
	end

	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_ASSAULT_SEA)

	AINewUnitSetUp(NewUnit, NewUnitEXP)

	print("Stupid AI need more Naval Ranged Ships!")
end

function AIForceBuildInfantryUnits(unitX, unitY, player)
	if unitX == nil or unitY == nil or player == nil or player:IsLackingTroops() then
		return
	end

	if player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_IRON"], true) <= 3
		and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 4 then
		print("Not enough resources!")
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_SWORDSMAN")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end

	local PlayerEra = player:GetCurrentEra()
	local NewUnitEXP = PlayerEra * 5
	if player:GetCapitalCity() ~= nil then
		NewUnitEXP = NewUnitEXP + player:GetCapitalCity():GetProductionExperience()
	end


	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_ATTACK)


	AINewUnitSetUp(NewUnit, NewUnitEXP)

	print("Stupid AI need more Infantry!")
end

function AIForceBuildLandCounterUnits(unitX, unitY, player)
	if unitX == nil or unitY == nil or player == nil or player:IsLackingTroops() then
		return
	end
	if player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 4 then
		print("Not enough resources!")
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_SPEARMAN")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end

	local PlayerEra = player:GetCurrentEra()
	local NewUnitEXP = PlayerEra * 5
	if player:GetCapitalCity() ~= nil then
		NewUnitEXP = NewUnitEXP + player:GetCapitalCity():GetProductionExperience()
	end


	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_ATTACK)


	AINewUnitSetUp(NewUnit, NewUnitEXP)
	print("Stupid AI need more Counter Units!")
end

function AIForceBuildMobileUnits(unitX, unitY, player)
	if unitX == nil or unitY == nil or player == nil or player:IsLackingTroops() then
		return
	end

	if player:GetCurrentEra() < 5 and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_HORSE"], true) <= 3
		and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 5 then
		print("Not enough resources!")
		return
	end

	if player:GetCurrentEra() >= 5 and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_OIL"], true) <= 3
		and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 10 then
		print("Not enough resources!")
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_HORSEMAN")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end

	local PlayerEra = player:GetCurrentEra()
	local NewUnitEXP = PlayerEra * 10
	if player:GetCapitalCity() ~= nil then
		NewUnitEXP = NewUnitEXP + player:GetCapitalCity():GetProductionExperience()
	end

	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_FAST_ATTACK)

	AINewUnitSetUp(NewUnit, NewUnitEXP)
	print("Stupid AI need more Mobile Units!")
end

function AIForceBuildLandHRUnits(unitX, unitY, player)
	if unitX == nil or unitY == nil or player == nil or player:IsLackingTroops() then
		return
	end


	if player:GetCurrentEra() < 6 and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_HORSE"], true) <= 3
		and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 6 then
		print("Not enough resources!")
		return
	end

	if player:GetCurrentEra() >= 6 and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_ALUMINUM"], true) <= 3
		and player:GetNumResourceAvailable(GameInfoTypes["RESOURCE_MANPOWER"], true) <= 10 then
		print("Not enough resources!")
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_MEDIEVAL_CHARIOT")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end

	local PlayerEra = player:GetCurrentEra()
	local NewUnitEXP = PlayerEra * 20
	if player:GetCapitalCity() ~= nil then
		NewUnitEXP = NewUnitEXP + player:GetCapitalCity():GetProductionExperience()
	end

	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_FAST_ATTACK)

	NewUnit:SetExperience(NewUnitEXP)

	local plot = NewUnit:GetPlot()
	local unitCount = plot:GetNumUnits()

	if unitCount >= 3 then
		if NewUnit:GetDomainType() == DomainTypes.DOMAIN_LAND then
			NewUnit:JumpToNearestValidPlot()
			print("Jump out AI stacking units!")
		else
			NewUnit:Kill()
		end
	end
	print("Stupid AI need more Land Hit and Run Units!")
end

function AIConscriptMilitiaUnits(unitX, unitY, player)
	if player == nil or player:IsHuman() or player:IsLackingTroops() then
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_WARRIOR")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end

	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_DEFENSE)
	if player:GetCapitalCity() ~= nil then
		NewUnit:SetExperience(player:GetCapitalCity():GetProductionExperience())
	end
	NewUnit:JumpToNearestValidPlot()

	print("AI conscript Militia reporting! We fight to the last man!")
end

function AIConscriptMilitiaNavy(unitX, unitY, player)
	if player == nil or player:IsHuman() or player:IsLackingTroops() then
		return
	end

	local sUnitType = GetCivSpecificUnit(player, "UNITCLASS_NAVAL_MILITIA")
	local sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)

	while (sUpgradeUnitType ~= nil) do
		sUnitType = sUpgradeUnitType
		sUpgradeUnitType = GetUpgradeUnit(player, sUnitType)
	end

	local NewUnit = player:InitUnit(GameInfoTypes[sUnitType], unitX, unitY, UNITAI_ESCORT_SEA)
	if player:GetCapitalCity() ~= nil then
		NewUnit:SetExperience(player:GetCapitalCity():GetProductionExperience())
	end
	NewUnit:JumpToNearestValidPlot()

	print("AI conscript Militia Navy boadt! We fight to the last boat!")
end

function AINewUnitSetUp(NewUnit, NewUnitEXP)
	NewUnit:SetExperience(NewUnitEXP)

	if NewUnit == nil then
		return
	end

	local plot = NewUnit:GetPlot()
	local unitCount = plot:GetNumUnits()

	if unitCount >= 3 then
		if NewUnit:GetDomainType() == DomainTypes.DOMAIN_LAND or NewUnit:GetDomainType() == DomainTypes.DOMAIN_SEA then
			NewUnit:JumpToNearestValidPlot()
			print("Jump out AI stacking units!")
		end
	end
end

-- MOD Begin by CaptainCWB
-- Improve Tiles for Both Human & AI
function ImproveTiles(bIsHuman)
	for plotLoop = 0, Map.GetNumPlots() - 1, 1 do
		local plot = Map.GetPlotByIndex(plotLoop)
		if plot == nil or plot:GetOwner() == -1 or plot:IsCity() or Players[plot:GetOwner()]:IsMinorCiv() or Players[plot:GetOwner()]:IsBarbarian()
			or (bIsHuman and (not Players[plot:GetOwner()]:IsHuman() or not Teams[Players[plot:GetOwner()]:GetTeam()]:IsHasTech(GameInfoTypes["TECH_AUTOMATION_T"])))
			or (not bIsHuman and Players[plot:GetOwner()]:IsHuman())
		then
		else
			local player = Players[plot:GetOwner()];

			if plot:GetResourceType(player:GetTeam()) ~= -1
				and (plot:GetImprovementType() == -1
					or (not plot:CanHaveImprovement(plot:GetImprovementType(), player:GetTeam())
						and GameInfo.Resources[plot:GetResourceType(player:GetTeam())].ResourceClassType ~= "RESOURCECLASS_BONUS"))
			then
				if plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_FARM.ID, player:GetTeam()) then
					if GameInfo.Leader_Traits { LeaderType = GameInfo.Leaders[player:GetLeaderType()].Type, TraitType =
						"TRAIT_IGNORE_TERRAIN_IN_FOREST" } ()
						and (GameInfo.Traits["TRAIT_IGNORE_TERRAIN_IN_FOREST"].PrereqPolicy == nil or (GameInfo.Traits["TRAIT_IGNORE_TERRAIN_IN_FOREST"].PrereqPolicy
							and player:HasPolicy(GameInfoTypes[GameInfo.Traits["TRAIT_IGNORE_TERRAIN_IN_FOREST"].PrereqPolicy])))
					then
					else
						RemoveConflictFeatures(plot)
					end
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_FARM.ID)
				elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_MINE.ID, player:GetTeam()) then
					RemoveConflictFeatures(plot)
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_MINE.ID)
				elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_QUARRY.ID, player:GetTeam()) then
					RemoveConflictFeatures(plot)
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_QUARRY.ID)
				elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_PASTURE.ID, player:GetTeam()) then
					RemoveConflictFeatures(plot)
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_PASTURE.ID)
				elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_FISHING_BOATS.ID, player:GetTeam()) then
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_FISHING_BOATS.ID)
				elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_FISHFARM_MOD.ID, player:GetTeam()) then
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_FISHFARM_MOD.ID)
				elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_PLANTATION.ID, player:GetTeam()) then
					RemoveConflictFeatures(plot)
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_PLANTATION.ID)
				elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_CAMP.ID, player:GetTeam()) then
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_CAMP.ID)
				elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_WELL.ID, player:GetTeam()) then
					RemoveConflictFeatures(plot)
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_WELL.ID)
				elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_OFFSHORE_PLATFORM.ID, player:GetTeam()) then
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_OFFSHORE_PLATFORM.ID)
				end
				print("Improve Resource Automatically!")
			end
			if not plot:IsWater() or plot:GetResourceType(-1) ~= -1 or plot:GetImprovementType() ~= -1 or (plot:IsUnit() and player:IsHuman()) then
				if plot:GetFeatureType() == FeatureTypes.FEATURE_JUNGLE and plot:GetImprovementType() == -1
					and plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_TRADING_POST.ID, player:GetTeam())
					and (GameInfoTypes[GameInfo.Builds["BUILD_TRADING_POST"].PrereqTech] == nil
						or Teams[player:GetTeam()]:IsHasTech(GameInfoTypes[GameInfo.Builds["BUILD_TRADING_POST"].PrereqTech]))
				then
					plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_TRADING_POST.ID);
				end
			elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_FISHERY_MOD.ID, player:GetTeam()) and Teams[player:GetTeam()]:IsHasTech(GameInfoTypes[GameInfo.Builds["BUILD_FISHERY_MOD"].PrereqTech]) then
				plot:SetResourceType(GameInfoTypes.RESOURCE_FISH, 1)
				plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_FISHFARM_MOD.ID)
			elseif plot:CanHaveImprovement(GameInfo.Improvements.IMPROVEMENT_GAS_RIG_MOD.ID, player:GetTeam()) and Teams[player:GetTeam()]:IsHasTech(GameInfoTypes[GameInfo.Builds["BUILD_GAS_RIG_MOD"].PrereqTech]) then
				plot:SetResourceType(GameInfoTypes.RESOURCE_NATRUALGAS, 1)
				plot:SetImprovementType(GameInfo.Improvements.IMPROVEMENT_OFFSHORE_PLATFORM.ID)
			end
			if plot:IsImprovementPillaged() then
				plot:SetImprovementPillaged(false)
				print("pillaged plot repaired by Automation!")
			end
		end
	end
end

-- Carriers Restore Cargos
g_CargoSetList = {};
function SPCargoListSetup(iPlayerID)
	if Players[iPlayerID] == nil then return end
	if g_CargoSetList[iPlayerID] == nil then
		g_CargoSetList[iPlayerID] = {};
	end
	local pPlayer = Players[iPlayerID];

	local iCBARangedCombat = 0;
	local iASARangedCombat = 0;
	local iMisRangedCombat = 0;
	local pCBAcraftUnit = nil;
	local pASAcraftUnit = nil;
	local pMissile_Unit = nil;
	local iCBAcraft = -1
	local iASAcraft = -1
	local iMissileU = -1
	local overrideCBA = nil;
	local overrideASA = nil;
	local overrideMis = nil;
	local iCost = -1;
	for unit in GameInfo.Units() do
		if unit and unit.Special ~= nil and unit.Type == GameInfo.UnitClasses[unit.Class].DefaultUnit
			and (unit.PrereqTech == nil or (unit.PrereqTech and Teams[pPlayer:GetTeam()]:IsHasTech(GameInfoTypes[unit.PrereqTech]))) then
			if unit.Special == "SPECIALUNIT_FIGHTER" and unit.RangedCombat > iCBARangedCombat then
				iCBARangedCombat = unit.RangedCombat;
				pCBAcraftUnit = unit;
				iCBAcraft = unit.ID
			elseif unit.Special == "SPECIALUNIT_STEALTH" and unit.RangedCombat > iASARangedCombat and unit.RangeAttackOnlyInDomain then
				iASARangedCombat = unit.RangedCombat;
				pASAcraftUnit = unit;
				iASAcraft = unit.ID
			elseif unit.Special == "SPECIALUNIT_MISSILE" and unit.RangedCombat > iMisRangedCombat then
				iMisRangedCombat = unit.RangedCombat;
				pMissile_Unit = unit;
				iMissileU = unit.ID
			end
		end
	end
	if pCBAcraftUnit then
		overrideCBA = GameInfo.Civilization_UnitClassOverrides { UnitClassType = pCBAcraftUnit.Class, CivilizationType =
			GameInfo.Civilizations[pPlayer:GetCivilizationType()].Type } ();
	end
	if pASAcraftUnit then
		overrideASA = GameInfo.Civilization_UnitClassOverrides { UnitClassType = pASAcraftUnit.Class, CivilizationType =
			GameInfo.Civilizations[pPlayer:GetCivilizationType()].Type } ();
	end
	if pMissile_Unit then
		overrideMis = GameInfo.Civilization_UnitClassOverrides { UnitClassType = pMissile_Unit.Class, CivilizationType =
			GameInfo.Civilizations[pPlayer:GetCivilizationType()].Type } ();
	end

	if overrideCBA and GameInfo.Units[overrideCBA.UnitType].Special == "SPECIALUNIT_FIGHTER" then
		iCBAcraft = GameInfoTypes[overrideCBA.UnitType];
	elseif iCBAcraft == GameInfoTypes["UNIT_CARRIER_FIGHTER_ADV"]
		and GameInfo.Leader_Traits { LeaderType = GameInfo.Leaders[pPlayer:GetLeaderType()].Type, TraitType =
		"TRAIT_OCEAN_MOVEMENT" } ()
		and (GameInfo.Traits["TRAIT_OCEAN_MOVEMENT"].PrereqPolicy == nil or (GameInfo.Traits["TRAIT_OCEAN_MOVEMENT"].PrereqPolicy
			and pPlayer:HasPolicy(GameInfoTypes[GameInfo.Traits["TRAIT_OCEAN_MOVEMENT"].PrereqPolicy])))
	then
		iCBAcraft = GameInfoTypes["UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER_ADV"];
		print("English Unique Adv CF!")
	end
	if overrideASA and GameInfo.Units[overrideASA.UnitType].Special == "SPECIALUNIT_STEALTH" then
		iASAcraft = GameInfoTypes[overrideASA.UnitType];
	end
	if overrideMis and GameInfo.Units[overrideMis.UnitType].Special == "SPECIALUNIT_MISSILE" then
		iMissileU = GameInfoTypes[overrideMis.UnitType];
	end
	if iASAcraft and iASAcraft ~= -1 then
		for pCity in pPlayer:Cities() do
			if pCity and pCity:IsCanPurchase(false, false, iASAcraft, -1, -1, YieldTypes.YIELD_GOLD) then
				iCost = math.floor(pCity:GetUnitPurchaseCost(iASAcraft) / 5);
				break;
			end
		end
	end
	local sCBAcraft = "None";
	if iCBAcraft ~= -1 then
		sCBAcraft = Locale.ConvertTextKey(GameInfo.Units[iCBAcraft].Description);
	end
	print("Player " .. iPlayerID .. "'s Carriers can Purchase " .. sCBAcraft .. " in this turn, Cost: " .. iCost);

	if pPlayer:IsHuman() and iCBAcraft ~= -1 then
		CarrierRestoreButton.Title         = Locale.ConvertTextKey("TXT_KEY_BUILD_CARRIER_FIGHTER") ..
			Locale.ConvertTextKey(GameInfo.Units[iCBAcraft].Description);
		CarrierRestoreButton.IconAtlas     = GameInfo.Units[iCBAcraft].IconAtlas;
		CarrierRestoreButton.PortraitIndex = GameInfo.Units[iCBAcraft].PortraitIndex;
	end

	g_CargoSetList[iPlayerID] = { iCBAcraft, iMissileU, iCost, iASAcraft }
end

function CarrierRestore(iPlayerID, iUnitID, iCargoUnit)
	if Players[iPlayerID] == nil or not Players[iPlayerID]:IsAlive()
		or Players[iPlayerID]:GetUnitByID(iUnitID) == nil
		or Players[iPlayerID]:GetUnitByID(iUnitID):IsDead()
		or Players[iPlayerID]:GetUnitByID(iUnitID):IsDelayedDeath()
		or Players[iPlayerID]:GetUnitByID(iUnitID):GetPlot() == nil
		or Players[iPlayerID]:GetUnitByID(iUnitID):GetPlot():IsCity()
		or iCargoUnit == nil or iCargoUnit == -1
		or g_CargoSetList[iPlayerID] == nil
	then
		return;
	end
	local pPlayer = Players[iPlayerID];
	local pUnit   = pPlayer:GetUnitByID(iUnitID);
	local pPlot   = pUnit:GetPlot();
	local iCost   = g_CargoSetList[iPlayerID][3];

	-- Add New aircraft(s)!
	if pUnit:CargoSpace() > 0 and not pUnit:IsFull() then
		local sSpecialCargo = GameInfo.Units[pUnit:GetUnitType()].SpecialCargo;

		local SupplyDiscount = 0;
		if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CARRIER_SUPPLY_1"].ID) then
			SupplyDiscount = SupplyDiscount + 1
		end
		if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CARRIER_SUPPLY_2"].ID) then
			SupplyDiscount = SupplyDiscount + 1
		end
		if pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CARRIER_SUPPLY_3"].ID) then
			SupplyDiscount = SupplyDiscount + 1
		end
		if iCost and iCost > 0 then
			iCost = math.floor(iCost * (1 - 0.2 * SupplyDiscount));
		end

		if sSpecialCargo == "SPECIALUNIT_MISSILE" then
			if pUnit:GetUnitType() == GameInfoTypes.UNIT_FRANCE_MISTRAL and iCargoUnit == GameInfoTypes.UNIT_GUIDED_MISSILE then
				iCargoUnit = GameInfoTypes["UNIT_FRANCE_EUROCOPTER_TIGER"];
				print("French Eurotiger Unique!");
			end
			while not pUnit:IsFull() do
				pPlayer:InitUnit(iCargoUnit, pPlot:GetX(), pPlot:GetY(), UNITAI_MISSILE_AIR):SetMoves(0);
				print("Missile restored!");
			end
		elseif sSpecialCargo == "SPECIALUNIT_FIGHTER" and iCost and iCost >= 0 and iCost <= pPlayer:GetGold() then
			local pNewCargoUnit = pPlayer:InitUnit(iCargoUnit, pPlot:GetX(), pPlot:GetY(), UNITAI_ATTACK_AIR);
			print("New Aircraft restored on Carrier! Cost: " .. iCost);
			if not pPlayer:IsHuman() then
				pNewCargoUnit:PushMission(GameInfoTypes.MISSION_AIRPATROL);
			end
			pNewCargoUnit:SetMoves(0);
			if not pPlayer:IsHuman() and not pUnit:IsFull() and 2 * iCost <= pPlayer:GetGold() then
				iCost = 2 * iCost;
				pNewCargoUnit = pPlayer:InitUnit(iCargoUnit, pPlot:GetX(), pPlot:GetY(), UNITAI_ATTACK_AIR);
				pNewCargoUnit:PushMission(GameInfoTypes.MISSION_AIRPATROL);
				pNewCargoUnit:SetMoves(0);
				print("New Aircraft restored on Carrier twice for AI! Total Cost: " .. iCost);
			end
			return iCost
		end

		-- Upgrade Old aircraft!
	elseif pUnit:IsCargo() then
		local sSpecial = GameInfo.Units[pUnit:GetUnitType()].Special;
		if sSpecial == "SPECIALUNIT_FIGHTER" and iCost and iCost > 0 then
			iCost = math.floor(iCost / 2);
		elseif sSpecial == "SPECIALUNIT_STEALTH" then
			iCost = pUnit:UpgradePrice(iCargoUnit);
		elseif sSpecial == "SPECIALUNIT_MISSILE" then
			iCost = 0;
		end
		local SupplyDiscount = 0;
		if pUnit:GetTransportUnit():IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CARRIER_SUPPLY_1"].ID) then
			SupplyDiscount = SupplyDiscount + 1
		end
		if pUnit:GetTransportUnit():IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CARRIER_SUPPLY_2"].ID) then
			SupplyDiscount = SupplyDiscount + 1
		end
		if pUnit:GetTransportUnit():IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CARRIER_SUPPLY_3"].ID) then
			SupplyDiscount = SupplyDiscount + 1
		end
		if iCost and iCost > 0 then
			iCost = math.floor(iCost * (1 - 0.2 * SupplyDiscount));
		end
		-- Can't upgrade because lacking the Gold!
		if iCost == nil or iCost < 0 or iCost > pPlayer:GetGold() then
			return;
		end
		if (GameInfo.Leader_Traits { LeaderType = GameInfo.Leaders[pPlayer:GetLeaderType()].Type, TraitType =
				"TRAIT_OCEAN_MOVEMENT" } ()
				and (GameInfo.Traits["TRAIT_OCEAN_MOVEMENT"].PrereqPolicy == nil or (GameInfo.Traits["TRAIT_OCEAN_MOVEMENT"].PrereqPolicy
					and pPlayer:HasPolicy(GameInfoTypes[GameInfo.Traits["TRAIT_OCEAN_MOVEMENT"].PrereqPolicy])))
				and iCargoUnit == GameInfoTypes["UNIT_CARRIER_FIGHTER_ADV"])
			or pUnit:GetUnitType() == GameInfoTypes["UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER"]
		then
			iCargoUnit = GameInfoTypes["UNIT_CARRIER_FIGHTER_ENGLISH_HARRIER_ADV"];
			print("English Unique 'Upgrade' CFJ!");
		elseif pUnit:GetTransportUnit():GetUnitType() == GameInfoTypes.UNIT_FRANCE_MISTRAL and iCargoUnit == GameInfoTypes.UNIT_GUIDED_MISSILE then
			iCargoUnit = GameInfoTypes["UNIT_FRANCE_EUROCOPTER_TIGER"];
			print("French Eurotiger Unique!");
		end

		if iCargoUnit ~= -1 then
			print("Found old aircrafts! Upgrade Price is: " .. iCost);
			local iLevel = pUnit:GetLevel();
			local iExperience = pUnit:GetExperience();
			local tUnitPromotions = {};
			for unitPromotion in GameInfo.UnitPromotions() do
				if pUnit:IsHasPromotion(unitPromotion.ID) and not unitPromotion.LostWithUpgrade then
					table.insert(tUnitPromotions, unitPromotion.ID);
				end
			end
			local unitAIType = pUnit:GetUnitAIType();
			pUnit:Kill();
			local pNewCargoUnit = pPlayer:InitUnit(iCargoUnit, pPlot:GetX(), pPlot:GetY(), unitAIType);
			pNewCargoUnit:SetLevel(iLevel);
			pNewCargoUnit:SetExperience(iExperience);
			for _, unitPromotionID in ipairs(tUnitPromotions) do
				pNewCargoUnit:SetHasPromotion(unitPromotionID, true);
			end

			pNewCargoUnit:SetMoves(0);
			return iCost;
		end
	end
end

-- MOD End   by CaptainCWB
function RemoveErrorPromotion(iPlayerID, iUnitID)
	-- keep for compatibility
end
print("UtilityFunctions Check Pass!")
