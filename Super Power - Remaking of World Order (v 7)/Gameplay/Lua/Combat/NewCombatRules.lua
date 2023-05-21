-- New Combat Rules


--include( "UtilityFunctions.lua" )
include("FLuaVector.lua");
--******************************************************************************* Unit Combat Rules *******************************************************************************
local g_DoNewAttackEffect = nil;
local NewAttackOff = GameInfo.SPNewEffectControler.SP_NEWATTACK_OFF.Enabled
local SplashAndCollateralOff = PreGame.GetGameOption("GAMEOPTION_SP_SPLASH_AND_COLLATERAL_OFF")
function NewAttackEffectStarted(iType, iPlotX, iPlotY)
	if NewAttackOff then
		print("SP Attack Effect - OFF!");
		return;
	end

	if iType == GameInfoTypes["BATTLETYPE_MELEE"]
		or iType == GameInfoTypes["BATTLETYPE_RANGED"]
		or iType == GameInfoTypes["BATTLETYPE_AIR"]
		or iType == GameInfoTypes["BATTLETYPE_SWEEP"]
	then
		g_DoNewAttackEffect = {
			attPlayerID = -1,
			attUnitID   = -1,
			defPlayerID = -1,
			defUnitID   = -1,
			attODamage  = 0,
			defODamage  = 0,
			PlotX       = iPlotX,
			PlotY       = iPlotY,
			bIsCity     = false,
			defCityID   = -1,
			battleType  = iType,
		};
	end
end

GameEvents.BattleStarted.Add(NewAttackEffectStarted);
tCaptureSPUnits = {};
function NewAttackEffectJoined(iPlayer, iUnitOrCity, iRole, bIsCity)
	if g_DoNewAttackEffect == nil
		or Players[iPlayer] == nil or not Players[iPlayer]:IsAlive()
		or (not bIsCity and Players[iPlayer]:GetUnitByID(iUnitOrCity) == nil)
		or (bIsCity and (Players[iPlayer]:GetCityByID(iUnitOrCity) == nil or iRole == GameInfoTypes["BATTLEROLE_ATTACKER"]))
		or iRole == GameInfoTypes["BATTLEROLE_BYSTANDER"]
	then
		return;
	end
	if bIsCity then
		g_DoNewAttackEffect.defPlayerID = iPlayer;
		g_DoNewAttackEffect.defCityID = iUnitOrCity;
		g_DoNewAttackEffect.bIsCity = bIsCity;
	elseif iRole == GameInfoTypes["BATTLEROLE_ATTACKER"] then
		g_DoNewAttackEffect.attPlayerID = iPlayer;
		g_DoNewAttackEffect.attUnitID = iUnitOrCity;
		g_DoNewAttackEffect.attODamage = Players[iPlayer]:GetUnitByID(iUnitOrCity):GetDamage();
	elseif iRole == GameInfoTypes["BATTLEROLE_DEFENDER"] or iRole == GameInfoTypes["BATTLEROLE_INTERCEPTOR"] then
		g_DoNewAttackEffect.defPlayerID = iPlayer;
		g_DoNewAttackEffect.defUnitID = iUnitOrCity;
		g_DoNewAttackEffect.defODamage = Players[iPlayer]:GetUnitByID(iUnitOrCity):GetDamage();
	end

	-- Prepare for Capture Unit!
	if not bIsCity and g_DoNewAttackEffect.battleType == GameInfoTypes["BATTLETYPE_MELEE"]
		and Players[g_DoNewAttackEffect.attPlayerID] ~= nil and
		Players[g_DoNewAttackEffect.attPlayerID]:GetUnitByID(g_DoNewAttackEffect.attUnitID) ~= nil
		and Players[g_DoNewAttackEffect.defPlayerID] ~= nil and
		Players[g_DoNewAttackEffect.defPlayerID]:GetUnitByID(g_DoNewAttackEffect.defUnitID) ~= nil
	then
		local attPlayer = Players[g_DoNewAttackEffect.attPlayerID];
		local attUnit   = attPlayer:GetUnitByID(g_DoNewAttackEffect.attUnitID);
		local defPlayer = Players[g_DoNewAttackEffect.defPlayerID];
		local defUnit   = defPlayer:GetUnitByID(g_DoNewAttackEffect.defUnitID);

		if attUnit:GetCaptureChance(defUnit) > 0 then
			local unitClassType = defUnit:GetUnitClassType();
			local unitPlot = defUnit:GetPlot();
			local unitOriginalOwner = defUnit:GetOriginalOwner();

			local sCaptUnitName = nil;
			if defUnit:HasName() then
				sCaptUnitName = defUnit:GetNameNoDesc();
			end

			local unitLevel = defUnit:GetLevel();
			local unitEXP   = attUnit:GetExperience();
			local attMoves  = attUnit:GetMoves();
			print("attacking Unit remains moves:" .. attMoves);

			tCaptureSPUnits = { unitClassType, unitPlot, g_DoNewAttackEffect.attPlayerID, unitOriginalOwner, sCaptUnitName,
				unitLevel, unitEXP, attMoves };
		end
	end
end

GameEvents.BattleJoined.Add(NewAttackEffectJoined);
function NewAttackEffect()
	--Defines and status checks
	if g_DoNewAttackEffect == nil or Players[g_DoNewAttackEffect.defPlayerID] == nil
		or Players[g_DoNewAttackEffect.attPlayerID] == nil or not Players[g_DoNewAttackEffect.attPlayerID]:IsAlive()
		or Players[g_DoNewAttackEffect.attPlayerID]:GetUnitByID(g_DoNewAttackEffect.attUnitID) == nil
		-- or Players[ g_DoNewAttackEffect.attPlayerID ]:GetUnitByID(g_DoNewAttackEffect.attUnitID):IsDead()
		or Map.GetPlot(g_DoNewAttackEffect.PlotX, g_DoNewAttackEffect.PlotY) == nil
	then
		return;
	end

	local attPlayerID = g_DoNewAttackEffect.attPlayerID;
	local attPlayer = Players[attPlayerID];
	local defPlayerID = g_DoNewAttackEffect.defPlayerID;
	local defPlayer = Players[defPlayerID];

	local attUnit = attPlayer:GetUnitByID(g_DoNewAttackEffect.attUnitID);
	local attPlot = attUnit:GetPlot();

	local plotX = g_DoNewAttackEffect.PlotX;
	local plotY = g_DoNewAttackEffect.PlotY;
	local batPlot = Map.GetPlot(plotX, plotY);
	local batType = g_DoNewAttackEffect.battleType;

	local bIsCity = g_DoNewAttackEffect.bIsCity;
	local defUnit = nil;
	local defPlot = nil;
	local defCity = nil;

	local attFinalUnitDamage = attUnit:GetDamage();
	local defFinalUnitDamage = 0;
	local defUnitDamage = 0;

	if not bIsCity and defPlayer:GetUnitByID(g_DoNewAttackEffect.defUnitID) then
		defUnit = defPlayer:GetUnitByID(g_DoNewAttackEffect.defUnitID);
		defPlot = defUnit:GetPlot();
		defFinalUnitDamage = defUnit:GetDamage();
		defUnitDamage = defFinalUnitDamage - g_DoNewAttackEffect.defODamage;
	elseif bIsCity and defPlayer:GetCityByID(g_DoNewAttackEffect.defCityID) then
		defCity = defPlayer:GetCityByID(g_DoNewAttackEffect.defCityID);
	end

	g_DoNewAttackEffect = nil;

	--Complex Effects Only for Human VS AI(reduce time and enhance stability)
	if not attPlayer:IsHuman() and not defPlayer:IsHuman() then
		return;
	end
	-- Not for Barbarins
	if attPlayer:IsBarbarian() then
		return;
	end

	------- PromotionID
	local GunpowderInfantryUnitID = GameInfo.UnitPromotions["PROMOTION_GUNPOWDER_INFANTRY_COMBAT"].ID
	local InfantryUnitID = GameInfo.UnitPromotions["PROMOTION_INFANTRY_COMBAT"].ID
	local KnightID = GameInfo.UnitPromotions["PROMOTION_KNIGHT_COMBAT"].ID
	local TankID = GameInfo.UnitPromotions["PROMOTION_TANK_COMBAT"].ID
	local PillageFreeID = GameInfo.UnitPromotions["PROMOTION_CITY_PILLAGE_FREE"].ID
	local SpeComID = GameInfo.UnitPromotions["PROMOTION_SPECIAL_FORCES_COMBAT"].ID
	local SPForce2ID = GameInfo.UnitPromotions["PROMOTION_SP_FORCE_2"].ID

	local CQBCombat1ID = GameInfo.UnitPromotions["PROMOTION_CQB_COMBAT_1"].ID
	local CQBCombat2ID = GameInfo.UnitPromotions["PROMOTION_CQB_COMBAT_2"].ID

	local KillingEffectsID = GameInfo.UnitPromotions["PROMOTION_GAIN_MOVES_AFFER_KILLING"].ID

	local EMPBomberID = GameInfo.UnitPromotions["PROMOTION_EMP_ATTACK"].ID
	local AntiEMPID = GameInfo.UnitPromotions["PROMOTION_ANTI_EMP"].ID

	local ChainReactionID = GameInfo.UnitPromotions["PROMOTION_CHAIN_REACTION"].ID

	local AntiDebuffID = GameInfo.UnitPromotions["PROMOTION_ANTI_DEBUFF"].ID

	-------Nuclear Rocket Launcher Kills itself (<suicide>is not working!)
	if attUnit:GetUnitType() == GameInfoTypes.UNIT_BAZOOKA then
		attUnit:ChangeDamage(attUnit:GetCurrHitPoints());
	end


	-- Carrier-based aircrafts give EXP to carrier
	if not attUnit:IsDead() and attUnit:IsCargo() and batType == GameInfoTypes["BATTLETYPE_AIR"]
		and attUnit:GetSpecialUnitType() ~= GameInfo.SpecialUnits.SPECIALUNIT_STEALTH.ID
	then
		print("Found a carrier-based aircraft!")
		local AircraftEXP = attUnit:GetExperience()
		if AircraftEXP > 0 then
			print("Gained EXP:" .. AircraftEXP);
			local CarrierUnit = attUnit:GetTransportUnit()
			print("Found its carrier!")
			CarrierUnit:ChangeExperience(AircraftEXP)
			attUnit:SetExperience(0)
		end
	end


	-- Heavy Knight&Tank attacking cities lose all MPs
	if bIsCity and not attUnit:IsDead() and batType == GameInfoTypes["BATTLETYPE_MELEE"]
		and not attUnit:IsHasPromotion(PillageFreeID) and not attUnit:IsHasPromotion(AntiDebuffID)
		and (attUnit:IsHasPromotion(KnightID) or attUnit:IsHasPromotion(TankID))
	then
		attUnit:SetMoves(0)
		print("Attacking City and lost all MPs!")
		if attPlayer:IsHuman() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_ATTACKING_CITY_LOST_MOVEMENT",
				attUnit:GetName()))
		end
	end


	if not defPlayer:IsAlive() then
		return
	end

	----------------EMP Bomber effects
	if attUnit:IsHasPromotion(EMPBomberID) then
		local pTeam = Teams[defPlayer:GetTeam()]
		if not pTeam:IsHasTech(GameInfoTypes["TECH_COMPUTERS"]) then
			print("No Tech - Computer!");
		else
			if defCity then
				defCity:ChangeResistanceTurns(1);
				print("EMP City!");
			end
			local unitCount = batPlot:GetNumUnits();
			if unitCount > 0 then
				for i = 0, unitCount - 1, 1 do
					local pFoundUnit = batPlot:GetUnit(i)
					if pFoundUnit and not pFoundUnit:IsHasPromotion(AntiEMPID) then
						pFoundUnit:SetMoves(0);
						print("EMP same tile Unit!");
					end
				end
				for i = 0, 5 do
					local adjPlot = Map.PlotDirection(plotX, plotY, i);
					if (adjPlot ~= nil) then
						if adjPlot:IsCity() then
							adjPlot:GetPlotCity():ChangeResistanceTurns(1);
							print("EMP around City!");
						end
						unitCount = adjPlot:GetNumUnits();
						if unitCount > 0 then
							for i = 0, unitCount - 1, 1 do
								local pFoundUnit = adjPlot:GetUnit(i);
								if pFoundUnit and not pFoundUnit:IsHasPromotion(AntiEMPID) then
									pFoundUnit:SetMoves(0);
									print("EMP around Unit!");
								end
							end
						end
					end
				end
			end

			-- Notification
			if defPlayer:IsHuman() then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_US_EMP_SHORT")
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_US_EMP")
				defPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, heading, plotX, plotY)
			elseif attPlayer:IsHuman() then
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_ENEMY_EMP_SHORT")
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_UNIT_ENEMY_EMP")
				attPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, heading, plotX, plotY)
			end
		end
	end


	------------------------- Chain Reaction
	if attUnit:IsHasPromotion(ChainReactionID) then
		for unit in defPlayer:Units() do
			local plot = unit:GetPlot()
			if unit and unit ~= defUnit and not unit:IsHasPromotion(AntiDebuffID) and not unit:IsTrade()
				and plot and PlotIsVisibleToHuman(plot)
			then
				local DamageOri = attUnit:GetRangeCombatDamage(unit, nil, false);
				local ChainDamage = 0.33 * DamageOri;
				if ChainDamage >= unit:GetCurrHitPoints() then
					ChainDamage = unit:GetCurrHitPoints();
					local eUnitType = unit:GetUnitType();
				end
				unit:ChangeDamage(ChainDamage, attPlayer);
				print("Chain Reaction!");
			end
		end
	end



	-------------- attacking Cities
	if defCity then
		-- Special Forces sabotage city
		if not attUnit:IsDead() and attUnit:IsHasPromotion(SPForce2ID) then
			print("Special Forces attacking City!")
			if not (attPlayer:HasPolicy(GameInfo.Policies['POLICY_FUTURISM']) and defCity:IsOriginalCapital()) then ---Avoid 0 culture when sabotage a capital city--by HMS
				defCity:ChangeResistanceTurns(1)
			end
			local unitCount = batPlot:GetNumUnits()
			if defCity:GetDamage() < defCity:GetMaxHitPoints() and unitCount > 0 then
				print("Units in the city!")
				for i = 0, unitCount - 1, 1 do
					local pFoundUnit = batPlot:GetUnit(i)
					if pFoundUnit and not pFoundUnit:IsHasPromotion(SpeComID) then
						pFoundUnit:SetMoves(0)
						print("Units in the city are Sabotaged!")
						if attPlayer:IsHuman() then
							Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_SPFORCE_CITY_SABOTAGE",
								pFoundUnit:GetName()))
						end
					end
				end
			end



		end

		-------------- Ranged Attack Kill Popluation of Heavily Damaged City
		if batType == GameInfoTypes["BATTLETYPE_RANGED"] or batType == GameInfoTypes["BATTLETYPE_AIR"] then
			--		print ("Ranged Unit attacked City!")
			if (defCity:GetDamage() >= defCity:GetMaxHitPoints() - 1) then
				local cityPop = defCity:GetPopulation()
				if (cityPop > 1) then
					local NewCityPop = cityPop - 1
					defCity:SetPopulation(NewCityPop, true) ----Set Real Population
					local CityOwner = defCity:GetOwner()

					if Players[CityOwner]:IsHuman() then
						local pPlayer = Players[CityOwner]
						local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_CITY_POPULATION_LOST_BY_RANGEDFIRE", attUnit:GetName()
							, defCity:GetName())
						local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_CITY_POPULATION_LOST_BY_RANGEDFIRE_SHORT")
						pPlayer:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, plotX, plotY)
					end
				end
			end
		end

		-- Attacking a Unit!
	elseif defUnit then
		----------- PROMOTION_GAIN_MOVES_AFFER_KILLING Effects
		if attUnit:IsHasPromotion(KillingEffectsID) then
			print("DefUnit Damage:" .. defFinalUnitDamage);
			if defFinalUnitDamage >= 100 then
				attUnit:SetMoves(attUnit:MovesLeft() + GameDefines["MOVE_DENOMINATOR"]);
				attUnit:SetMadeAttack(false);
				print("Ah, fresh meat!");
			end
		end

		-- Debuff immune unit
		if defUnit:IsHasPromotion(AntiDebuffID) then
			print("This unit is debuff immune")
			return
		end


		if not attUnit:IsDead() and not attUnit:IsHasPromotion(AntiDebuffID) and batType == GameInfoTypes["BATTLETYPE_MELEE"]
			and defUnit:GetDomainType() == attUnit:GetDomainType()
			and ((defUnit:IsHasPromotion(CQBCombat1ID) and attFinalUnitDamage < 20) or defUnit:IsHasPromotion(CQBCombat2ID))
			and not defUnit:IsHasPromotion(GunpowderInfantryUnitID) and not defUnit:IsHasPromotion(InfantryUnitID)
		then
			attUnit:SetMoves(0)
			Message = 3
			print("Attacker Stopped!")
		end

		-------Fighters will damage land and naval AA units in an air-sweep
		if not attUnit:IsDead() and not defUnit:IsDead() and defUnit:IsCombatUnit()
			and batType == GameInfoTypes["BATTLETYPE_SWEEP"]
		then
			print("Airsweep!")

			-- This AA unit is exempted from Air-sweep damage!

			-- local attUnitStrength = attUnit:GetBaseCombatStrength()
			-- local defUnitStrength = defUnit:GetBaseCombatStrength()

			print("Airsweep and the defender is an AA unit!")

			local attDamageInflicted = defUnit:GetRangeCombatDamage(defUnit, nil, false) * 0.5
			local defDamageInflicted = attUnit:GetRangeCombatDamage(defUnit, nil, false)

			------------Defender exempt/reduced from damage
			if defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_ANTI_HELICOPTER"].ID) then
				defDamageInflicted = 0
				print("This AA unit is exempted from Air-sweep damage!")
			end
			if defUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_FLANK_GUN_1"].ID) then
				defDamageInflicted = 0.5 * defDamageInflicted
				print("This AA unit is reduced (-50%) from Air-sweep damage!")
			end

			------------In case of the AA unit is a melee unit
			if not defUnit:IsRanged() then
				attDamageInflicted = defDamageInflicted * 0.25;
			end

			---------------fix embarked unit bug
			if defUnit:IsEmbarked() then
				attDamageInflicted = 1;
				print("Air-sweep embarked unit!");
			end

			-- local defDamageInflicted = attUnit:GetCombatDamage(defUnitStrength, attUnitStrength, defUnit:GetDamage(),false,false, false)

			--------------Death Animation
			-- defUnit:PushMission(MissionTypes.MISSION_DIE_ANIMATION)
			-- attUnit:PushMission(MissionTypes.MISSION_DIE_ANIMATION)

			------------Notifications
			local text = nil;
			local attUnitName = attUnit:GetName();
			local defUnitName = defUnit:GetName();

			if attDamageInflicted >= attUnit:GetCurrHitPoints() then
				attDamageInflicted = attUnit:GetCurrHitPoints();
				local eUnitType = attUnit:GetUnitType();
				print("Airsweep Unit died!")

				if defPlayerID == Game.GetActivePlayer() then
					text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_AIRSWEEP_KILLED_ENEMY_FIGHTER", attUnitName, defUnitName);
				elseif attPlayerID == Game.GetActivePlayer() then
					text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_AIRSWEEP_KILLED_BY_ENEMY", attUnitName, defUnitName);
				end
			elseif attDamageInflicted > 0 then
				attDamageInflicted = math.floor(attDamageInflicted);
				attUnit:ChangeExperience(4)
				if attPlayerID == Game.GetActivePlayer() then
					text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_AIRSWEEP_TO_ENEMY", attUnitName, defUnitName,
						tostring(attDamageInflicted));
				end
			end

			if defDamageInflicted >= defUnit:GetCurrHitPoints() then
				defDamageInflicted = defUnit:GetCurrHitPoints();
				local eUnitType = defUnit:GetUnitType();
				print("AA Unit died!")

				if defPlayerID == Game.GetActivePlayer() then
					text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_AIRSWEEP_AA_KILLED_BY_ENEMY", attUnitName, defUnitName);
				elseif attPlayerID == Game.GetActivePlayer() then
					text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_AIRSWEEP_KILLED_ENEMY_AA", attUnitName, defUnitName);
				end
			elseif defDamageInflicted > 0 then
				defDamageInflicted = math.floor(defDamageInflicted);
				defUnit:ChangeExperience(2);
				if defPlayerID == Game.GetActivePlayer() then
					text = Locale.ConvertTextKey("TXT_KEY_SP_NOTIFICATION_AIRSWEEP_BY_ENEMY", attUnitName, defUnitName,
						tostring(attDamageInflicted));
				end
			end

			if text and (attPlayer:IsHuman() or defPlayer:IsHuman()) then
				Events.GameplayAlertMessage(text)
			end

			print("Air Sweep Damage Dealt: " .. attDamageInflicted);
			print("Air Sweep Damage Received: " .. defDamageInflicted);

			attUnit:ChangeDamage(attDamageInflicted, defPlayer);
			defUnit:ChangeDamage(defDamageInflicted, attPlayer);
		end
	end
end --function END

GameEvents.BattleFinished.Add(NewAttackEffect)


--*******************************************************************************Combat restrictions*******************************************************************************
-- MOD Begin - by CaptainCWB
-- Captured Unit Keeps the Name and remains some movements
-- Captured unit does not occupy normal unit's name
function OnCapturedUnitNoChangeName(iPlayer, iUnit, iName)
	if Players[iPlayer] == nil or Players[iPlayer]:GetUnitByID(iUnit) == nil
		or (tCaptureSPUnits and #tCaptureSPUnits > 0 and tCaptureSPUnits[5] ~= nil
			and Players[iPlayer]:GetUnitByID(iUnit):GetUnitClassType() == tCaptureSPUnits[1]
			and Players[iPlayer]:GetUnitByID(iUnit):GetPlot() == tCaptureSPUnits[2]
			and iPlayer == tCaptureSPUnits[3]
			and Players[iPlayer]:GetUnitByID(iUnit):GetOriginalOwner() == tCaptureSPUnits[4])
	then
		return false;
	else
		return true;
	end
end

GameEvents.UnitCanHaveName.Add(OnCapturedUnitNoChangeName)
-- Do Keeping Promotions & Name
function CaptureSPDKP(iPlayerID, iUnitID)
	local NewlyCapturedID = GameInfo.UnitPromotions["PROMOTION_NEWLYCAPTURED"].ID
	if Players[iPlayerID] == nil or Players[iPlayerID]:GetUnitByID(iUnitID) == nil
		or tCaptureSPUnits == nil or #tCaptureSPUnits == 0
	then
		return;
	end
	local pUnit = Players[iPlayerID]:GetUnitByID(iUnitID);

	if pUnit:GetUnitClassType() == tCaptureSPUnits[1]
		and pUnit:GetPlot() == tCaptureSPUnits[2] and iPlayerID == tCaptureSPUnits[3]
		and pUnit:GetOriginalOwner() == tCaptureSPUnits[4]
	then
		if tCaptureSPUnits[5] ~= nil then
			pUnit:SetName(tCaptureSPUnits[5]);
		end
		if pUnit:IsCombatUnit() then
			-- pUnit:SetLevel(tCaptureSPUnits[6]);
			pUnit:SetExperience(tCaptureSPUnits[7] / 4);
			pUnit:SetLevel(1);
			local pMoves = pUnit:MaxMoves();
			print("MaxMoves of captured unit is " .. pMoves);
			local qMoves = tCaptureSPUnits[8];
			local captureMoveRoll = Game.Rand(100, "At NewCombatRules.lua CaptureSPDKP(), roll for moves remain") + 1
			local rMoves = (pMoves * 0.2 + qMoves * 0.4) * (captureMoveRoll * 0.002 + 0.9);
			print("newly captured unit remains movements:" .. rMoves);
			pUnit:SetMoves(rMoves);
			pUnit:SetHasPromotion(NewlyCapturedID, true);
			local captureDamageRoll = Game.Rand(30, "At NewCombatRules.lua CaptureSPDKP(), roll for damage") + 1
			local pDamage = captureDamageRoll + 69 - qMoves / GameDefines["MOVE_DENOMINATOR"] * 4;
			print("newly captured unit remains hit points:" .. pDamage);
			pUnit:SetDamage(pDamage);
			tCaptureSPUnits = {};
		end
	end
end

Events.SerialEventUnitCreated.Add(CaptureSPDKP);
-- MOD End   - by CaptainCWB

print("New Combat Rules Check Pass!")
