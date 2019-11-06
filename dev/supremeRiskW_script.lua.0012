--[[
Don't edit or remove this comment block! It is used by the editor to store information since i'm too lazy to write a good LUA parser... -Haz
SETTINGS
RestrictedEnhancements=ResourceAllocation,DamageStablization,AdvancedEngineering,T3Engineering,HeavyAntiMatterCannon,LeftPod,RightPod,Shield,ShieldGeneratorField,TacticalMissile,TacticalNukeMissile,Teleporter
RestrictedCategories=EXPERIMENTAL,MASSFABRICATION
END
--]]

local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')

--scenario utilities
local Utilities = import('/lua/utilities.lua')

--interface utilities
local UIUtil = import('/lua/ui/uiutil.lua')
local gameParent = import('/lua/ui/game/gamemain.lua').GetGameParent()

local executing = false
local beatTime = 5
local baseSizeMeters = 400;
local roundIdleSeconds = 0; -- this round is idle for n seconds now
local maxRoundIdleTime = 30; -- number of seconds from last round action to begin next round
local idleWarnTime = 7; -- warn n seconds before end of round
local roundnum = 0;

local players = {};

    function basicSerialize (o)
      if type(o) == "number" then
        return tostring(o)
      else   -- assume it is a string
        return string.format("%q", o)
      end
    end

    function Xsave (name, value, saved)
	  local str = ""
      saved = saved or {}       -- initial value
      str = str..name.." = "
      if type(value) == "number" or type(value) == "string" then
        str = str..basicSerialize(value).."\n"
      elseif type(value) == "table" then
        if saved[value] then    -- value already saved?
          str = str..saved[value].."\n"  -- use its previous name
        else
          saved[value] = name   -- save name for next time
          str = str.."{}\n"     -- create a new table
          for k,v in value do      -- save its fields
            local fieldname = string.format("%s[%s]", name,
                                            basicSerialize(k))
            str = str..Xsave(fieldname, v, saved)
          end
        end
      else
        --error("cannot save a " .. type(value))
      end
	  return str
    end

	
function dump(tbl)
	LOG(Xsave("var",tbl,nil))
end

function meter(m)
	return m*0.0512
end

function Pos(x,y)
	local p = {}
	p[1] = x
	p[3] = y
	p[2] = 128
	return p
end

  
function circleWalls(cdata)
	local x = cdata.pos.x
	local y = cdata.pos.y

	local wd = baseSizeMeters;
	local wallDistance = 1;
	local yo = 4;
	local xo = meter(wd)
	while yo+wallDistance < xo do
		xo = (math.sqrt(meter(wd)*meter(wd)-yo*yo))
		createWall4("ARMY_9",x,y,xo,yo)
		yo = yo+wallDistance
	end
	
	xo = 4;
	while xo < yo do
		yo = (math.sqrt(meter(wd)*meter(wd)-xo*xo))
		createWall4("ARMY_9",x,y,xo,yo)
		xo = xo+wallDistance
	end
end 


local tblGroup = nil;

local countries = {
	{	name='Iceland',
		pos = {
			x = 407, 
			y = 330
		},
		owner = "ARMY_1",
		walls = nil;
	},
	{	name='Alaska',
		pos = {
			x = 100, 
			y = 285
		},
		owner = "ARMY_1",
		walls = nil;
	},	
	
	-- NORTH AMERICA
	{	name='West United States',
		pos = {x = 170, y = 375},
		owner = "ARMY_9",
		walls = nil
	},
	{	name='Eastern United States',
		pos = {x = 200, y = 410},
		owner = "ARMY_9",
		walls = nil
	},	
	{	name='Mexico',
		pos = {x = 139, y = 455},
		owner = "ARMY_9",
		walls = nil
	},	
	{	name='Alberta',
		pos = {x = 150, y = 320},
		owner = "ARMY_9",
		walls = nil
	},		
	{	name='Ontario',
		pos = {x = 200, y = 320},
		owner = "ARMY_9",
		walls = nil
	},		
	{	name='Quebec',
		pos = {x = 282, y = 330},
		owner = "ARMY_9",
		walls = nil
	},		
	{	name='Northwest Territories',
		pos = {x = 282, y = 330},
		owner = "ARMY_9",
		walls = nil
	},			
	{	name='Greenland',
		pos = {x = 363, y = 303},
		owner = "ARMY_9",
		walls = nil
	},				
	-- SOUTH AMERICA
	{	name='ARMY_9',
		pos = {x = 290, y = 710},
		owner = "ARMY_9",
		walls = nil
	},
	{	name='ARMY_9',
		pos = {x = 350, y = 590},
		owner = "ARMY_9",
		walls = nil,
		startUnits = 7
	},	
	{	name='ARMY_9',
		pos = {x = 250, y = 540},
		owner = "ARMY_9",
		walls = nil
	},	
	
	-- AFRICA
	{	name='West Africa',
		pos = {x = meter(8700), y = meter(10300)},
		owner = "ARMY_9",
		walls = nil,
		startUnits = 6
	},
	{	name='Egypt',
		pos = {x = 530, y = 497},
		owner = "ARMY_9",
		walls = nil
	},
	{	name='Congo',
		pos = {x = 522, y = 617},
		owner = "ARMY_1",
		walls = nil
	},	
	{	name='South Africa',
		pos = {x = 560, y = 700},
		owner = "ARMY_1",
		walls = nil
	},		
	{	name='East Africa',
		pos = {x = 584, y = 632},
		owner = "ARMY_1",
		walls = nil
	},		
	{	name='Madagascar',
		pos = {x = 619, y = 684},
		owner = "ARMY_1",
		walls = nil
	},		
	
	
		{	name='Kamchatka',
		pos = {
			x = 920,			
			y = 305
		},
		owner = "ARMY_1",
		walls = circleWalls
	},
  {
		name='China',
		pos = {
			x = meter(4100), 
			y = meter(2800)
		},
		owner = "ARMY_9",
		walls = circleWalls
  }
  }

local teleportationZones = {
	{
		sourceZone = Rect(0,0,350,500), -- redirect if into zone and 
		targetZone = Rect(700,0,1024,500), -- move order into this zone is issued
		name		='Alaska',
		teleporterSource = Pos(1,303),
		teleporterDest = Pos(1021,307),
    },
	{
		sourceZone = Rect(700,0,1024,500), -- redirect if into zone and 
		targetZone = Rect(1,1,300,500), -- move order into this zone is issued
		name		='kamc',
		teleporterSource = Pos(1022,305),
		teleporterDest = Pos(4,300),
    }
}
  
-- The profit table for cashing in cards. First one is the one being reclaimed, the other ones need to be there
local cardTypes = {
	{unit = 'uel0106', profit = 4},
	{unit = 'uel0201', profit = 6},
	{unit = 'uel0304', profit = 8},
}	
  
  
local player = nil;

function OnPopulate()
  LOG("OnPopulate ----------------------------------")
  
  -- prevent ACU warpin animation
  ScenarioInfo.Options['PrebuiltUnits'] = nil
  
  tblGroup = ScenarioUtils.InitializeArmies()

  ScenarioFramework.SetPlayableArea('AREA_1' , false)
  
  -- Set Camera to show full Map
  local Camera = import('/lua/SimCamera.lua').SimCamera
  local cam = Camera("WorldCamera")
--  cam:MoveTo(ScenarioUtils.AreaToRect('AREA_1'))
	cam:SetZoom(2000,0)

	for a, ccc in ScenarioUtils.AreaToRect('AREA_1') do LOG(a.." "..ccc) end

	
	dump(moho.navigator_methods)
	
  LOG("ONPOPULATE END")
end

function numPlayers()
	return table.getn(players)
end

function OnStart(self)
--	PrintText("KAKAKAAK",20,'FFFFFFFF',20,'center')
  LOG("OnStart -------------------------------")
  LOG("Hello world")

  init()
--  initFactories()
  initStartUnits()
  
  initMainThread()
end

function init()
	for index,army in ListArmies() do
		LOG(index.." "..army.." is playing")
		
		#Building Restrictions
		dump(categories)
		ScenarioFramework.AddRestriction(index, categories.ALLUNITS)
		ScenarioFramework.RemoveRestriction(index, categories.uel0106)
	end
end

-- acu functions
function onSRProduceUnit(self)
	if self.SRUnitsToBuild > 0 then
		self.SRUnitsToBuild = self.SRUnitsToBuild - 1
		self:SetProductionPerSecondMass(self.SRUnitsToBuild) -- update UI
		return true
	else
		return false
	end
end

function onSRAddUnitResources(acu, un)
--	acu.SRUnitsToBuild = acu.SRUnitsToBuild + un
	acu.SRUnitsToBuild = un -- max units to build is reset on each round, to prevent saving them up ,,,
	acu:SetProductionPerSecondMass(acu.SRUnitsToBuild) -- update UI
end


-- Bonus Card System
function spawnRandomCard(player)
	local cardType = cardTypes[math.random(table.getn(cardTypes))];
	spawnCard(player, cardType)
	
end

function spawnCard(player, cardType)
	
	if player.bonusCardSpawned == false then
		player.bonusCardSpawned = true

		if not player.cardSlots then
			player.cardSlots = {false, false, false, false, false}
		end
		for i, slot in player.cardSlots do
			if slot == false then
				LOG("Creating Card prop at slot "..i)
				spawnCardProp(player, cardType, i)
				break;
			end
		end
	end
end

function spawnCardProp(player, cardType, i)
	local acupos = player.acu:GetPosition();
	acupos[3] = acupos[3] - 5;
	acupos[1] = acupos[1] - 6;

	local card = CreateUnitHPR(cardType.unit, player.armyName, acupos[1]+2*i, 0, acupos[3], 0,0,0)		
	local wr = card:CreateWreckageProp(1)
	
	card:Destroy()
	wr.slotNumber = i
	wr.cardType = cardType
	player.cardSlots[i] = wr
	
	-- what happens if we reclaim?
	wr.OnReclaimed = function(self) 
			self.isAlreadyReclaimed = true;
			local myProfit = 0 
			
			-- check for 3 cards of the type
			if hasCard(player, self.cardType.unit) >= 3 then
				removeCard(player, self.cardType.unit)
				removeCard(player, self.cardType.unit)
				removeCard(player, self.cardType.unit) -- remove the third one too!
				myProfit = self.cardType.profit
			end
			
			-- check for three different cards
			local hasAll = true;
			for i, cardType in cardTypes do
				if hasCard(player, cardType.unit) == 0 then
					hasAll = false; -- we dont have this unit - profit is zero
				end
			end
				
			if myProfit == 0 and hasAll then
				myProfit = 10;
				-- remove cards
				for i, cardType in cardTypes do
					if(self.cardType.unit != cardType.unit) then
						removeCard(player, cardType.unit)
					end
				end
			end
			
			--- profit assignment
			LOG("Profit for next round is "..myProfit)

			
			if myProfit > 0 then -- cashed something in 
				-- assign profit to next round
				player.nextRoundBonusProfit = myProfit;
				player.cardSlots[self.slotNumber] = false -- remove the card
			else
				-- respawn prop
				spawnCardProp(player, self.cardType, self.slotNumber)
--				spawnCard(player, self.cardType)
			end
	end
	return card;
end

function hasCard(player, unitType)
	local hasCounter = 0;
	for i, slot in player.cardSlots do
		if slot then
			if slot.cardType.unit == unitType then
				hasCounter = hasCounter + 1
			end
		end
	end
	return hasCounter;
end


function removeCard(player, unitType)
	local hasCounter = 0;
	for i, slot in player.cardSlots do
		if slot then
			if slot.cardType.unit == unitType then
				if not slot.isAlreadyReclaimed then -- prevent duplicate removal
					player.cardSlots[i] = false;
					slot:Destroy() -- remove wreckage
				end
				return;
			end
		end
	end
	return hasCounter;
end

############ init ##############

function initStartUnits()
	local yoffset = 6;
	for i,cdata in countries do
		-- Spawn one unit per country
		setAsPresident(cdata, nil)
		
		if cdata.startUnits then
			local ii = 0
			while ii < cdata.startUnits do
				CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x-2,cdata.pos.y+10,cdata.pos.y+yoffset, 0,0,0)
				ii = ii+1
			end
		end
--		local u = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x+2,cdata.pos.y+yoffset,cdata.pos.y+yoffset, 0,0,0)
		spawnCapital(cdata)
--		spawnFactory(cdata)
	end
	
	-- ACU and Resources
	local playerACUs = GetUnitsInRect(Rect(0,900,1024,1024))
	for i,acu in playerACUs do
		LOG("found ACU "..acu:GetArmy())
	
		local player = {};
		player.acu = acu;
		player.acu:SetProductionPerSecondMass(0);
		player.acu:SetProductionPerSecondEnergy(2000);
		player.acu.SRUnitsToBuild = 0;
		
		player.nextRoundBonusProfit = 0; --- card bonuses
		player.bonusCardSpawned = false;
		
		player.armyName = getArmyName(player.acu);
		players[acu:GetArmy()] = player;
		
		-- resource stuff
		player.acu.SRProduceUnit = onSRProduceUnit
		player.acu.SRAddUnitResources = onSRAddUnitResources

		-- enhancement stuff (disable all of them!)
        AddUnitEnhancement(player.acu,'dummy', 'Back')	
        AddUnitEnhancement(player.acu,'dummy', 'RCH')	
        AddUnitEnhancement(player.acu,'dummy', 'LCH')	
		player.acu:RequestRefreshUI()
  		
		-- mobility
		player.acu:SetImmobile(true)
	end
  
	-- set Starting Resources depending on owned Countries and # of players
    for i, player in players do
		local startResources = 50-(numPlayers()*5) - GetEmpireSize(player.armyName)
		player.acu:SRAddUnitResources(startResources)
	end
  
  
  
	
	local i = 0		
	-- debug spawn some units
	while i < 150 do
	unit = CreateUnitHPR('uel0106', "ARMY_1",50,0,300, 0,0,0)
	i = i+1
	end
			
end

function GetEmpireSize(armyName)
	local es = 0
	for i,cdata in countries do
		if cdata.owner == armyName then
			es = es +1
		end
	end
	return es
end

function spawnCapital(cdata)
	cdata.factoryOwnershipChanged = false
	spawnFactory(cdata)
	
	if cdata.walls != nil then
		cdata:walls(cdata)
	end
end

function spawnFactory(cdata)
	local x = cdata.pos.x
	local y = cdata.pos.y
	local name = cdata.name
	local army = cdata.owner
	local u = CreateUnitHPR( 'ueb0101', army, x,y,y, 0,0,0)

	u.CreateWreckage = function() end

	u:SetAllWeaponsEnabled(false)		
	u:SetCanBeKilled(true)
	u:SetDoNotTarget(true)
	u:SetMaxHealth(1)
	u:SetHealth(nil,1)
	u:SetRegenRate(1)
	u:SetIntelRadius('Vision', meter(baseSizeMeters*7))
	u:SetCustomName(name)
	cdata.factory = u
--	cdata.ownerId = armyId

	u:AddOnUnitBuiltCallback(function (factory, unit) 
		LOG("Unit has been Built: "..unit:GetEntityId())
		
		onRoundAction()
		u:AddOnKilledCallback(function(self) onRoundAction() end) -- round is delayed on kills
		end
		, categories.MOBILE)


	u.OnStartBuildOriginal = u.OnStartBuild
	u.OnStartBuild = function(self, unitBeingBuilt, order)
--		dump(unitBeingBuilt)
		
		local player = players[self:GetArmy()]

		if player.acu:SRProduceUnit() then 
			LOG(self:GetArmy().." start building ")
			self:OnStartBuildOriginal(unitBeingBuilt, order)
		else
--			LOG("Build limit reached")
--			WaitTicks(50)
			unitBeingBuilt:Kill()
		end
	end
		
	u:SetBuildTimeMultiplier(0.01)
	u:SetConsumptionPerSecondMass(0)
	u.SetConsumptionPerSecondMass = function() end
--	u.UpdateConsumptionValues = function() end
	
end

function round(num)
	return math.floor(num + 0.5)
end

function createWall(army,x,y)
		local u = CreateUnitHPR('ueb5101', army, x,y,y, 0,0,0)
		u:SetCanBeKilled(false)
        u:CreateWreckageProp(1)
        u:Destroy()
--		u:EnableUnitIntel('Cloak')
--		u:DisableUnitIntel('Vision')
	

end


function createWall4(army,x,y,ox,oy)
	createWall(army,x+ox,y+oy)
	createWall(army,x-ox,y+oy)
	createWall(army,x+ox,y-oy)
	createWall(army,x-ox,y-oy)
end

function initMainThread()
	ForkThread(mainThread)
	ForkThread(jobsThread)
	ForkThread(maintenanceThread)
end

function getArmyName(unit)
	local unitArmy = unit
	if unit.GetArmy then
		unitArmy = unit:GetArmy()
	end
	
	return ListArmies()[unitArmy]
end

function presidentIsAlive(country)
	if country.president == nil or country.president:IsDead() == true then
		return false
	else
		return true
	end
end


function setAsPresident(country, unit)

	local x = country.pos.x+1
	local y = country.pos.y+4
	if not unit then
		unit = CreateUnitHPR('uel0106', country.owner, x,0,y, 0,0,0)
		unit.isInitialPresident = true;
	end

	-- only alive units can be elected president
	if not unit:IsBeingBuilt() and not unit:IsDead() then
		LOG(country.name.." elected a new president")
		country.president = unit
		unit:SetCustomName("President of "..country.name)
		unit.isPresident = true

		-- stop unit from moving
		unit:SetImmobile(true)
		unit:SetUnSelectable(true)
--		unit:SetElevation(200)
--		local e = unit:GetElevation()
--		dump(e)
		
		unit:GetBlueprint().Economy.BuildCostMass = 0

--GetNavigator
--GetRallyPoint
--CanPathTo		
		
--		for index, o in moho.unit_methods do
--			LOG(index)
--		end
		
		-- only warp if not initial
		if not unit.isInitialPresident then
--	unit:SetSpeedMult(0)
--	unit.OnMotionHorzEventChange = function() end
--	unit.OnMotionVertEventChange = function() end
--	unit.OnMotionTurnEventChange = function() end
--	unit.UpdateMovementEffectsOnMotionEventChange = function() end

--		for a, ccc in unit:GetOrientation() do LOG(a.." "..ccc) end
--		for a, ccc in unit:GetPosition() do LOG(a.." "..ccc) end
--		LOG(unit:GetOrientation())
		
		unit.TeleportDrain = nil
		unit.SetImmobile = function() end -- prevent the following function to make the unit moveable again.
		unit.InitiateTeleportThread = myInitiateTeleportThread
		unit:OnTeleportUnit(unit, {x,0,y},{0,0,0,1})
--		Warp(unit,{country.pos.x,0,country.pos.y+6,0},{0,0,0,1})
		end
	end
end


function myInitiateTeleportThread(self, teleporter, location, orientation)
        self.UnitBeingTeleported = self
        self:SetImmobile(true)

        self:PlayUnitSound('TeleportStart')
        self:PlayUnitAmbientSound('TeleportLoop')

        # create teleport charge effect
        self:PlayTeleportChargeEffects()
        self:PlayTeleportOutEffects()
        self:CleanupTeleportChargeEffects()
        WaitSeconds( 0.1 )
        #Teleport Sound
        self:SetWorkProgress(0.0)
        Warp(self, location, orientation)
        self:PlayTeleportInEffects()
        WaitSeconds( 0.1 ) # Perform cooldown Teleportation FX here
    #Landing Sound
    #LOG('DROP')
    self:StopUnitAmbientSound('TeleportLoop')
    self:PlayUnitSound('TeleportEnd')
    self:SetImmobile(false)
    self.UnitBeingTeleported = nil
    self.TeleportThread = nil

	LOG("Teleport done")
	if self.targetRally then
		IssueMove( {self}, self.targetRally )
	end
end

function checkTeleportationZones()

--	sourceZone = Rect(0,0,300,500), -- redirect if into zone and 
--		targetZone = Rect(700,0,1024,500), -- move order into this zone is issued
--		name		='Alaska',
--		teleporterSource = Pos(0,300),
--		teleporterDest = Pos(1024,310),
--    },

	for i, zone in teleportationZones do
		local units = GetUnitsInRect(zone.sourceZone)
		if units then
			for index,unit in units do
				-- teleport these units
				if not unit:IsDead() and not unit:IsBeingBuilt() and not unit.isPresident and unit:GetWeaponCount() > 0 
				then
--					local newPosition = unit:GetPosition();
--					local heading = unit:GetHeading();
--					dump(heading);
					--LOG("unit found")
					-- unit is ordered into the targetZone
					if isInside(zone.targetZone, unit:GetNavigator():GetGoalPos()) then
--						LOG("unit going to teleport beacon "..zone.name)
--						LOG("original Goal:: ")
--						dump(unit:GetNavigator():GetGoalPos())
						-- store original Waypoint
						unit.originalWaypoint = unit:GetNavigator():GetGoalPos()
						dump(unit:GetNavigator():GetCurrentTargetPos())
					
						-- redirect to teleport zone
						--unit:GetNavigator():SetGoal(zone.teleporterSource)
						--IssueStop({unit})
						LOG("WP status: "..unit:GetNavigator():GetStatus())
						unit:GetNavigator():SetGoal(zone.teleporterSource)
--						unit:GetNavigator():SetSpeedThroughGoal(zone.teleporterSource)
						 
						--IssueMove({unit}, zone.teleporterSource)
					end
				end
			end
		end
		
		local unitsToTeleport = GetUnitsInRect(Pos2Rect(zone.teleporterSource, 10))
		if unitsToTeleport then
			for index,unit in unitsToTeleport do
				-- teleport these units
				if not unit:IsDead() and not unit:IsBeingBuilt() and unit:GetWeaponCount() > 0 and unit.originalWaypoint
				then
					--unit.targetRally = zone.targetRally
					--unit.targetRally = zone.targetRally
					-- teleport is for free ... shadow economyEvent function
					--unit.CreateEconomyEvent = function () end
					-- shadow teleport function to issue move afterwards
					--unit.InitiateTeleportThread = myInitiateTeleportThread
					local rp = 2
							
					local teleportPos = Pos(zone.teleporterDest[1]+math.random(-rp, rp),zone.teleporterDest[3]+math.random(-rp, rp))
--					local teleportPos = Pos(zone.teleporterDest[1],zone.teleporterDest[3]+zone.tpoffset)
--					local teleportPos = Pos(zone.teleporterDest[1],zone.teleporterDest[3])

					LOG("Warping unit from Zone "..zone.name.." to "..Xsave('aaa',teleportPos))
--					if unit:CanPathTo(teleportPos) then 

					--fix ferry bug with transports?
					local cs = 0;

			        if EntityCategoryContains(categories.TRANSPORTATION, unit) then
			                local cargo = unit:GetCargo()
			                if table.getn(cargo) > 0 then
			                    for k, v in cargo do
--									dump(v)
			                    end
			                end
							
						LOG("cargo size pre teleport: "..table.getn(cargo))
						
						
						unit.OnRemoveFromStorage = function() 
							LOG("BBBB") 
						end
						
						unit:GetNavigator():SetGoal(unit.originalWaypoint)					
						WaitSeconds(0.2)
						Warp(unit, teleportPos, unit:GetOrientation())
		                local cargo = unit:GetCargo()
						LOG("cargo size post teleport: "..table.getn(cargo))
						WaitSeconds(0)
		                local cargo = unit:GetCargo()
						LOG("cargo size post teleport: "..table.getn(cargo))
					else
						Warp(unit, teleportPos, unit:GetOrientation())
						WaitSeconds(0.2)
					
			        end

						-- Move to Original Waypoint
						unit:GetNavigator():SetGoal(unit.originalWaypoint)					
--						IssueMove({unit}, unit.originalWaypoint)
						unit.wayPointAfterTeleport = unit.originalWaypoint
						unit.originalWaypoint = nil;
						unit.lastTeleportZoneUsed = zone;
						unit.teleporterStaleCounter = 0;
--					end
					--unit:OnTeleportUnit(unit, newPosition,{0,0,0,1})
					--unit.CreateEconomyEvent = ee -- dont reset, we are async
				end
			end
		end
		
	end
end

function checkTeleportationZonesPFWorkaround()
	-- Help the bugged pathfinding a little...
	for i, zone in teleportationZones do
		local staleUnits = GetUnitsInRect(Pos2Rect(zone.teleporterDest, 5))
		if staleUnits then
			for index,unit in staleUnits do
				if unit.wayPointAfterTeleport and unit.lastTeleportZoneUsed == zone and unit.teleporterStaleCounter < 50 then
						-- Move to Original Waypoint
						unit:GetNavigator():SetGoal(unit.wayPointAfterTeleport)					
				--		IssueMove({unit}, unit.wayPointAfterTeleport)
						unit.teleporterStaleCounter = unit.teleporterStaleCounter+1
						WaitSeconds(0)
						LOG("Unit path reassigned the "..unit.teleporterStaleCounter..". time")
				end
			end
		end
	end
end

function checkCountryOwnership()
	local baseSizeInner = 0.9
	for i,cdata in countries do
		rect = {x0 = cdata.pos.x - meter(baseSizeMeters)*baseSizeInner,
				x1 = cdata.pos.x + meter(baseSizeMeters)*baseSizeInner,
				y0 = cdata.pos.y - meter(baseSizeMeters)*baseSizeInner,
				y1 = cdata.pos.y + meter(baseSizeMeters)*baseSizeInner
				}
				
		local units = GetUnitsInRect(rect)
		
		local armycounters = {}
		if units then
			for index,unit in units do
				if not unit:IsDead() and not unit:IsBeingBuilt() and unit:GetWeaponCount() > 0 then
				
					local weapon = unit:GetWeapon(1)
					local h = 1
					unit:SetMaxHealth(h)
					unit:SetHealth(nil, h)
--				LOG(unit:GetBlueprint())
					if(armycounters[unit:GetArmy()]) then
						armycounters[unit:GetArmy()] = armycounters[unit:GetArmy()] +1
					else
						armycounters[unit:GetArmy()] = 1;
					end
					
					
					if(getArmyName(unit) == cdata.owner) then
						-- own unit
						unit:SetSpeedMult(2) -- reset for successful liberators
						
						weapon:ChangeRateOfFire(2)
--						weapon:SetTurretYawSpeed(300)
--						weapon:SetTurretPitchSpeed(300)
						weapon:ChangeMaxRadius(meter(baseSizeMeters)*baseSizeInner*0.8)
						weapon:SetFiringRandomness(1.2)
					
						if cdata.president != unit then
							--unit:SetCustomName("") --Citizen of "..cdata.name)
						end
						
						if not presidentIsAlive(cdata) then
							setAsPresident(cdata, unit)
						end
					else
						-- enemy unit
						weapon:SetFiringRandomness(1.4)
						unit:SetSpeedMult(0.4) -- no easy retreat for liberators
						--unit:SetCustomName("Liberator of "..cdata.name)
					end
				end
			end
		end
	
		local enemyUnits = 0;
		local enemyArmy = nil;
		local enemyArmyId = nil;
		local friendlyUnits = 0;
		for index, counter in armycounters do
			--LOG("player "..index.." "..getArmyName(index)..": "..counter.." found in "..cdata.name.." ("..cdata.owner..")");
			if getArmyName(index) == cdata.owner then
				friendlyUnits = counter
			else
				enemyUnits = enemyUnits +counter
				enemyArmy = getArmyName(index)
				enemyArmyId = index
			end
	    end
		if enemyUnits > 0 then
			setFactoryName(cdata,cdata.name..": "..friendlyUnits.." attacked by "..enemyUnits)
		else
			setFactoryName(cdata,cdata.name..": "..friendlyUnits)
		
		end

		if friendlyUnits == 0 and enemyUnits > 0 then
			LOG(cdata.name.." liberated by "..enemyArmy)
			
			spawnRandomCard(players[enemyArmyId]) -- spawn card for player
			cdata.owner = enemyArmy
			cdata.factoryOwnershipChanged = true;
		end
		if friendlyUnits == 0 and enemyUnits == 0 and cdata.owner != "ARMY_9" then
			cdata.owner = "ARMY_9"
			cdata.factoryOwnershipChanged = true;
		
		end
	end

end

function setFactoryName(country, text)
--	if country.factory.isDead and not country.factory:isDead() then 
		if country.factory != nil and not country.factory:IsDead() then
			country.factory:SetCustomName(text)
			end
--	end

end

function reassignFactories()
	for i,c in countries do
		if c.factoryOwnershipChanged == true or c.factoryOwnershipChanged == nil or c.factory:IsDead() then
			if c.factory != nil and not c.factory:IsDead() then
				local f = c.factory
				c.factory = nil;
				f:Kill()
				WaitSeconds(7)
			end
			spawnFactory(c)
			c.factoryOwnershipChanged = false
		end
	end
end

##########################################
# Round Functions
##########################################

function checkEndOfRound()

	roundIdleSeconds = roundIdleSeconds + 1
	if roundIdleSeconds >= maxRoundIdleTime then
		roundIdleSeconds = 0
		beginNextRound()
	end
	
	if roundIdleSeconds+idleWarnTime > maxRoundIdleTime and roundIdleSeconds < maxRoundIdleTime-0 then
		displayRoundCountdown()
	end
	
	-- display after 5 seconds into each round
	if roundIdleSeconds == 5 then
		displayRoundCountdown()
	end
end

function displayRoundCountdown()
	local ileft = maxRoundIdleTime - roundIdleSeconds
	PrintText("Next Round will start in "..ileft.." seconds",20,'FFFFFFFF',0,'centerbottom') 
	WaitTicks(3)
end

function displayRoundBegin()
	local ileft = maxRoundIdleTime - roundIdleSeconds
	PrintText("Round "..roundnum.." - Produce Units and Attack. Next Round will begin after "..ileft.." seconds idle",
		20,'Red',3,'centertop') 
		
	local E01_M01_060 = {{text = '<LOC E01_M01_060_010>[{i EarthCom}]: Sir, maybe you should check your objectives.', 
	vid = 'E01_EarthCom_M01_01131.sfd', bank = 'E01_VO', cue = 'E01_EarthCom_M01_01131', faction = 'UEF'},}
	local E01_M01_062 = {{text = '<LOC E01_T01_030_010>[{i Leopard11}]: We want to be free. Is that too much to ask?', 
	vid = 'E01_Leopard11_T01_0033.sfd', bank = 'E01_VO', cue = 'E01_Leopard11_T01_0033', faction = 'Cybran'}}
	local E01_M01_061 = {{text = '<LOC E01_T01_030_010>[{i Leopard11}]: We want to be free. Is that too much to ask?', 
	vid = 'E01_Leopard11_T01_0033.sfd', bank = 'Experimental_VO', cue = 'Experimental_EarthCom_UEF_01219', faction = 'Cybran'}}
	local E01_M01_061 = {{text = '<LOC E01_T01_030_010>[{i Leopard11}]: We want to be free. Is that too much to ask?', 
	vid = 'E01_Leopard11_T01_0033.sfd', bank = 'Ops', cue = 'Ops_EarthCom_EarthCom_01425', faction = 'Cybran'}}

	
	-- primary objective: 'UEFComputer_NewExpansion_01390' -- COMPUTER_UEF_VO
	
	
--	local sounds = {'UEFComputer_UnitRevalation_01373','UEFComputer_UnitRevalation_01371','UEFComputer_Commanders_02450','UEFComputer_UnitRevalation_01374','UEFComputer_UnitRevalation_01372','UEFComputer_UnitRevalation_01370','UEFComputer_Transports_01334','UEFComputer_Transports_01333','UEFComputer_Transports_01332','UEFComputer_Transports_01331','UEFComputer_Transports_01330','UEFComputer_Transports_01329','UEFComputer_Transports_01328','UEFComputer_Stop_01265','UEFComputer_Stop_01264','UEFComputer_Stop_01263','UEFComputer_Stop_01262','UEFComputer_Stop_01261','UEFComputer_Stop_01260','UEFComputer_Stop_01258','UEFComputer_Stop_01257','UEFComputer_Stop_01256','UEFComputer_Resources_01313','UEFComputer_Resources_01312','UEFComputer_Resources_01311','UEFComputer_Resources_01310','UEFComputer_Resources_01309','UEFComputer_Resources_01308','UEFComputer_Resources_01307','UEFComputer_Resources_01306','UEFComputer_Resources_01305','UEFComputer_Resources_01304','UEFComputer_Resources_01303','UEFComputer_Patrol_01249','UEFComputer_Patrol_01248','UEFComputer_Patrol_01247','UEFComputer_Patrol_01246','UEFComputer_Patrol_01245','UEFComputer_Patrol_01244','UEFComputer_Patrol_01243','UEFComputer_Patrol_01241','UEFComputer_Patrol_01239','UEFComputer_Patrol_01238'
--	,'UEFComputer_NewExpansion_01390','UEFComputer_NewExpansion_01389','UEFComputer_NewExpansion_01388','UEFComputer_Move_01193','UEFComputer_Move_01192','UEFComputer_Move_01191','UEFComputer_Move_01190','UEFComputer_Move_01189','UEFComputer_Move_01188','UEFComputer_Move_01187','UEFComputer_Move_01186','UEFComputer_Move_01185','UEFComputer_Move_01184','UEFComputer_Move_01183','UEFComputer_Move_01182','UEFComputer_Move_01181','UEFComputer_Move_01180','UEFComputer_MissileLaunch_01359','UEFComputer_MissileLaunch_01358','UEFComputer_MissileLaunch_01357','UEFComputer_MissileLaunch_01355','UEFComputer_MissileLaunch_01354','UEFComputer_MissileLaunch_01353','UEFComputer_MissileLaunch_01352','UEFComputer_MissileLaunch_01350','UEFComputer_MissileLaunch_01349','UEFComputer_MissileLaunch_01348','UEFComputer_MissileLaunch_01347','UEFComputer_MissileLaunch_01346','UEFComputer_MissileLaunch_01345','UEFComputer_MissileLaunch_01344','UEFComputer_MissileLaunch_01343','UEFComputer_MissileLaunch_01342','UEFComputer_MissileLaunch_01341','UEFComputer_MissileLaunch_01340','UEFComputer_MissileLaunch_01339','UEFComputer_MissileLaunch_01338','UEFComputer_MissileLaunch_01337','UEFComputer_MissileLaunch_01336','UEFComputer_MapExpansion_01381','UEFComputer_MapExpansion_01380','UEFComputer_Intel_01199','UEFComputer_Intel_01198','UEFComputer_Intel_01197','UEFComputer_Intel_01196','UEFComputer_Intel_01195','UEFComputer_Intel_01194','UEFComputer_Failed_01422','UEFComputer_Failed_01421','UEFComputer_Failed_01420','UEFComputer_Failed_01408','UEFComputer_Failed_01407','UEFComputer_Failed_01406','UEFComputer_Failed_01405','UEFComputer_Expiremental_01369','UEFComputer_Expiremental_01368','UEFComputer_Expiremental_01367','UEFComputer_Expiremental_01366','UEFComputer_Expiremental_01365','UEFComputer_Expiremental_01364','UEFComputer_Expiremental_01363','UEFComputer_Expiremental_01362','UEFComputer_Expiremental_01361','UEFComputer_Expiremental_01360','UEFComputer_Engineering_01284','UEFComputer_Engineering_01283','UEFComputer_Engineering_01282','UEFComputer_Engineering_01281','UEFComputer_Engineering_01280','UEFComputer_Engineering_01279','UEFComputer_Construction_01276','UEFComputer_Construction_01275','UEFComputer_Construction_01274','UEFComputer_Construction_01273','UEFComputer_Construction_01272','UEFComputer_Construction_01271','UEFComputer_Construction_01270','UEFComputer_Construction_01269','UEFComputer_Completed_01404','UEFComputer_Completed_01403','UEFComputer_Completed_01402','UEFComputer_Completed_01401','UEFComputer_Completed_01400','UEFComputer_Completed_01399','UEFComputer_Completed_01398','UEFComputer_Commanders_01327','UEFComputer_Commanders_01326','UEFComputer_Commanders_01325','UEFComputer_Commanders_01324','UEFComputer_Commanders_01323','UEFComputer_Commanders_01322','UEFComputer_Commanders_01321','UEFComputer_Commanders_01320','UEFComputer_Commanders_01319','UEFComputer_Commanders_01318','UEFComputer_Commanders_01317','UEFComputer_Commanders_01316','UEFComputer_Commanders_01315','UEFComputer_CommandControl_01290','UEFComputer_CommandControl_01289','UEFComputer_CommandControl_01288','UEFComputer_CommandControl_01287','UEFComputer_CommandControl_01286','UEFComputer_CommandControl_01285','UEFComputer_CommandCap_01302','UEFComputer_CommandCap_01301','UEFComputer_CommandCap_01300','UEFComputer_CommandCap_01299','UEFComputer_CommandCap_01297','UEFComputer_CommandCap_01296','UEFComputer_CommandCap_01295','UEFComputer_CommandCap_01294','UEFComputer_CommandCap_01293','UEFComputer_CommandCap_01292','UEFComputer_CommandCap_01291','UEFComputer_Combat_01232','UEFComputer_Combat_01231','UEFComputer_Combat_01229','UEFComputer_Combat_01227','UEFComputer_Combat_01226','UEFComputer_Combat_01225','UEFComputer_Combat_01222','UEFComputer_Combat_01221','UEFComputer_Combat_01218','UEFComputer_Combat_01217','UEFComputer_Combat_01216','UEFComputer_Combat_01215','UEFComputer_Combat_01214','UEFComputer_Combat_01213','UEFComputer_Combat_01212','UEFComputer_Combat_01211','UEFComputer_Combat_01210','UEFComputer_Combat_01209','UEFComputer_Combat_01208','UEFComputer_Combat_01207','UEFComputer_Combat_01206','UEFComputer_Combat_01205','UEFComputer_Combat_01204','UEFComputer_Combat_01203','UEFComputer_Combat_01202','UEFComputer_Combat_01201','UEFComputer_Combat_01200','UEFComputer_Changed_01435','UEFComputer_Changed_01434','UEFComputer_Changed_01424','UEFComputer_Changed_01423','UEFComputer_Basic_Orders_01179','UEFComputer_Basic_Orders_01178','UEFComputer_Basic_Orders_01177','UEFComputer_Basic_Orders_01176','UEFComputer_Basic_Orders_01175','UEFComputer_Basic_Orders_01174','UEFComputer_Basic_Orders_01173','UEFComputer_Basic_Orders_01172','UEFComputer_Basic_Orders_01170','UEFComputer_Basic_Orders_01169','UEFComputer_Basic_Orders_01168','UEFComputer_Basic_Orders_01167','UEFComputer_Basic_Orders_01166','UEFComputer_Basic_Orders_01164','UEFComputer_Basic_Orders_01163','UEFComputer_Assist_01268','UEFComputer_Assist_01267','UEFComputer_Assist_01266','UEFComputer_MissileLaunch_01356','UEFComputer_MissileLaunch_01351','UEFComputer_Commanders_01314','UEFComputer_CommandCap_01298','UEFComputer_TransportIsFull'}
	
--	for i,s in sounds do
--		local E01_M01_061 = {{text = '<LOC E01_T01_030_010>[{i Leopard11}]: We want to be free. Is that too much to ask?', 
--		vid = 'E01_Leopard11_T01_0033.sfd', bank = 'COMPUTER_UEF_VO', cue = s, faction = 'Cybran'}}
--	
--		ScenarioFramework.Dialogue(E01_M01_061)
--		WaitSeconds(1)
--	end
	

--	{text = '<LOC E01_T01_030_010>[{i Leopard11}]: We want to be free. Is that too much to ask?', 
---	vid = 'E01_Leopard11_T01_0033.sfd', bank = 'E01_VO', cue = 'E01_Leopard11_T01_0033', faction = 'Cybran'})
--	ScenarioFramework.CreateTimerTrigger( M1Dialog4, M1DialogDelay4 )
--	ScenarioFramework.CreateTimerTrigger( M1Dialog4, M1DialogDelay4 )
	
--	table.insert(Sync.MissionText, '<LOC A06_M01_010_010>[{i Choir}]: We have prepared a base for you.')

end


-- An Action that delays the next round (fighting, building)
function onRoundAction()
	roundIdleSeconds = 0
--	displayRoundCountdown()
end



function beginNextRound()
	
	roundnum = roundnum +1
	LOG("A NEW ROUND "..roundnum.." has begun")
	
	displayRoundBegin()
	-- distribute Resources
	for i, player in players do
		local reinforcements = math.floor(GetEmpireSize(player.armyName)/3)
		if reinforcements < 3 then reinforcements = 3 end
		
		-- bonus card cashin
		reinforcements = reinforcements + player.nextRoundBonusProfit
		player.nextRoundBonusProfit = 0
		player.bonusCardSpawned = false
		-- TODO: Add continents
		
		player.acu:SRAddUnitResources(reinforcements)
	end
	-- reset spawning of card
end




function mainThread()

	displayRoundBegin()
	while true do
		checkCountryOwnership()
		checkEndOfRound()
		WaitSeconds(1)
	end
end

function jobsThread()
	while true do
		reassignFactories()
		checkTeleportationZones()
		WaitSeconds(1)
	end
end

function maintenanceThread()
	while true do
		checkTeleportationZonesPFWorkaround()
		WaitSeconds(5)
	end
end

function garbage__()

		if unit.originalUpdateMovementEffectsOnMotionEventChange == nil then
			unit.originalUpdateMovementEffectsOnMotionEventChange = unit.UpdateMovementEffectsOnMotionEventChange
			unit.UpdateMovementEffectsOnMotionEventChange = function(self, new, old)
				self:originalUpdateMovementEffectsOnMotionEventChange(new,old)
				LOG("New Move Command")
				local navi = self:GetNavigator()
				dump(navi:GetGoalPos())
				
				
				if navi.SetGoalOriginal == nil then
					navi.SetGoalOriginal = navi.SetGoal
					navi.myUnit = self
					navi.SetGoal = function (self2, position)
						self2:SetGoalOriginal(position)
						LOG("SETGOAL")
					end
				end
			end
--			dump(unit:GetRallyPoint())
		end
end


function isInside(zone, pos)
	if  pos[1] <= zone.x1 and pos[1] >= zone.x0 
	and pos[3] <= zone.y1 and pos[3] >= zone.y0 then
		return true
	else
		return false
	end
end

function Pos2Rect(pos, radius)
	return Rect(pos[1]-radius, pos[3]-radius, pos[1]+radius, pos[3]+radius)
end
