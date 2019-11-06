--[[
Don't edit or remove this comment block! It is used by the editor to store information since i'm too lazy to write a good LUA parser... -Haz
SETTINGS
RestrictedEnhancements=ResourceAllocation,DamageStablization,AdvancedEngineering,T3Engineering,HeavyAntiMatterCannon,LeftPod,RightPod,Shield,ShieldGeneratorField,TacticalMissile,TacticalNukeMissile,Teleporter
RestrictedCategories=EXPERIMENTAL,MASSFABRICATION
END
--]]

############################################################
#               S U P R E M E   R I S K                    #
############################################################
#
# A Supreme Commander Modification
# Map and Scripting 
# (C) 2007 Stephan Blecher (stephan@blecher.at)
#
# Use at your own risk and have lots of fun!
#
############################################################



--         local dis=VDist3(location, unit:GetPosition()) 

local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local Factions = import('/lua/factions.lua').Factions

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
local idleWarnTime = 10; -- warn n seconds before end of round
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

function Pos(x,y,z)
	if z == nil then z = 128 end
	local p = {}
	p[1] = x
	p[3] = y
	p[2] = z
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

local trees20 = {
--	'/env/Evergreen/Props/Trees/Groups/DC01_group1_prop.bp',
--	'/env/Evergreen/Props/Trees/Groups/DC01_group2_prop.bp',
	'/env/Evergreen/Props/Trees/DC01_s2_prop.bp',
	'/env/Evergreen/Props/Trees/DC01_s3_prop.bp',
	'/env/Evergreen/Props/Trees/Oak01_s3_prop.bp',
--	'/env/Evergreen/Props/Trees/Groups/Pine06_big_groupA_prop.bp',
--	'/env/Evergreen/Props/Trees/Groups/Pine06_big_groupB_prop.bp',
	'/env/Evergreen/Props/Trees/Pine06_V2_prop.bp',
	'/env/Evergreen/Props/Trees/Pine07_s2_prop.bp'}

function spawnTrees()

    local sx,sy = GetMapSize()
	local count = 100000
	while count > 0 do
		local px = math.random(0.0,sx)+math.random()
		local py =  math.random(0.0,sy)+math.random()
		-- determine whick prop to spawn
        local pz = GetSurfaceHeight(px,py)
        local pz2 = GetTerrainHeight(px,py) 
		
--		LOG(px.."/"..py.." => "..pz.." "..pz2)
		
--		local GetTerrainHeight(x,y)
       if pz2 >4.4 and pz2 <8 then
			-- only on land
--			CreatePropHPR('DC01_s1_prop',proppos[1],surfaceY,proppos[3],0,0,0)
			local proppos=Pos(px,py,pz)
			
			-- pine and stuff
			if py > 300 and py < 450 or py > 560 and py < 750 then			
				
--				CreateProp(proppos,trees20[math.random(table.getn(trees20))])
				CreatePropHPR(trees20[math.random(table.getn(trees20))], px,pz,py, math.random(),0,0)
				
			end
		end
		count = count -1
	end

				
end


local tblGroup = nil;

local continents = 
{
	na = {	name='North America',
		ownerBonus = 5,
		countries = {
			{name='Alaska',					pos = {x = 100, y = 285}},	
			{name='West United States',		pos = {x = 170, y = 375}},
			{name='Eastern United States',	pos = {x = 200, y = 410}},	
			{name='Mexico',					pos = {x = 139, y = 455}},	
			{name='Alberta',				pos = {x = 150, y = 320}},		
			{name='Ontario',				pos = {x = 200, y = 320}},		
			{name='Quebec',					pos = {x = 282, y = 330}},		
			{name='Northwest Territories',	pos = {x = 150, y = 285}},			
			{name='Greenland',				pos = {x = 362, y = 309}},
		}
	},
	sa = {	name='South America',
		ownerBonus = 2,
		countries = {
			{name='Argentinia',				pos = {x = 290, y = 710}},
			{name='Brasil',					pos = {x = 350, y = 590}},	
			{name='Venezuela',				pos = {x = 250, y = 540}},	
			{name='Peru',					pos = {x = 270, y = 592}},	
		}
	},
	af = {	name='Africa',
		ownerBonus = 3,
		countries = {	
			{name='West Africa',			pos = {x = 445, y = 525},},
			{name='Egypt',					pos = {x = 530, y = 497}},
			{name='Congo',					pos = {x = 522, y = 617}},
			{name='South Africa',			pos = {x = 560, y = 700}},		
			{name='East Africa',			pos = {x = 584, y = 632}},		
			{name='Madagascar',				pos = {x = 619, y = 684}},		
		}
	},
	eu = {
		name='Europe',
		ownerBonus = 5,
		countries = {
			{name='Iceland',				pos = {x = 407, y = 333}},
			{name='Middle Europe',			pos = {x = 489, y = 390}},
			{name='West Europe',			pos = {x = 460, y = 416}},
			{name='Eastern Europe',			pos = {x = 540, y = 413}},
			{name='Great Britain',			pos = {x = 448, y = 372}},
			{name='Scandinavia',			pos = {x = 499, y = 335}},
			{name='Ukraine',				pos = {x = 570, y = 328}},
			
		}
	},
	as = {
		name='Asia',
		ownerBonus = 7,
		countries = {
			{name='Kamchatka',				pos = {x = 912,	y = 315}},
			{name='Sibiria',				pos = {x = 777,	y = 342}},
			{name='Irkutsk',				pos = {x = 848,	y = 303}},
			{name='Jakutia',				pos = {x = 841,	y = 355}},
			{name='Mongolia',				pos = {x = 825,	y = 407}},
			{name='Japan',					pos = {x = 950,	y = 458}},
			{name='China',					pos = {x = 791, y = 460}},
			{name='Ural',					pos = {x = 714, y = 330}},
			{name='Afghanistan',			pos = {x = 694, y = 411}},
			{name='Middle East',			pos = {x = 600, y = 454}},
			{name='India',					pos = {x = 741, y = 518}},
			{name='Siam',					pos = {x = 825, y = 516}},
		}
	},
	au = {
		name='Australia',
		ownerBonus = 2,
		countries = {
			{name='Western Australia',		pos = {x = 920,	y = 715}},
			{name='Indonesia',				pos = {x = 883,	y = 608}},
			{name='Queensland',				pos = {x = 965,	y = 690}},
			{name='New Guinea',				pos = {x = 983,	y = 631}},
			
		}
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
  
local missions = {}


  
  
local player = nil;

function OnPopulate()
	LOG("OnPopulate ----------------------------------")

	-- spawn Trees
--	spawnTrees()
	
	
	-- prevent ACU warpin animation
--	ScenarioInfo.Options['PrebuiltUnits'] = nil

	tblGroup = ScenarioUtils.InitializeArmies()

	ScenarioFramework.SetPlayableArea('AREA_1' , false)
  
	zoomOut()
	for a, ccc in ScenarioUtils.AreaToRect('AREA_1') do LOG(a.." "..ccc) end

	LOG("ONPOPULATE END")
end

function zoomOut()
	-- Set Camera to show full Map
	local Camera = import('/lua/SimCamera.lua').SimCamera
	local cam = Camera("WorldCamera")
	--  cam:MoveTo(ScenarioUtils.AreaToRect('AREA_1'))
	cam:SetZoom(2000,0)
end
function numPlayers()
	return table.getn(players)
end

-- acu functions
function onSRProduceUnit(acu)
	if acu.SRUnitsToBuild > 0 then
		acu.SRUnitsToBuild = acu.SRUnitsToBuild - 1
		acu:SetProductionPerSecondMass(acu.SRUnitsToBuild) -- update UI
--		LOG("BUILD::"..acu.SRUnitsToBuild)
		return true
	else
		return false
	end
end

function onSRAddUnitResources(acu, un)
--	acu.SRUnitsToBuild = acu.SRUnitsToBuild + un
	acu.SRUnitsToBuild = un -- max units to build is reset on each round, to prevent saving them up ,,,
	if not acu:IsDead() then
		acu:SetProductionPerSecondMass(acu.SRUnitsToBuild) -- update UI
	end
end


################################
############ init ##############
################################
function OnStart(self)
  LOG("OnStart -------------------------------")
  LOG("Hello world")

  init()
  initPlayers() 
  initCountryOwnership()
  initStartUnits() -- putting up units and countries
  initMissions() -- setting up the missions, and assigning them
  
  initPlayerResources() -- setting up the resources to start with

  initMainThread()
end

function init()
	for index,army in ListArmies() do
		LOG(index.." "..army.." is playing")
		
		#Building Restrictions
		ScenarioFramework.AddRestriction(index, categories.ALLUNITS)
		ScenarioFramework.RemoveRestriction(index, categories.uel0106)
	end
	
end

-- randomly distribute counties among players
function initCountryOwnership()
	local countries = {};
	for ci,continent in continents do
		LOG("Setting up "..continent.name)
		for i,cdata in continent.countries do
			table.insert(countries, cdata)
		end
	end
	
	local countryNum = table.getn(countries)
	local playerNum = table.getn(players)
	
	while table.getn(countries) > 0 do
		for i, player in players do
			local randomI = math.random(table.getn(countries))
			local randomC = countries[randomI]
		
			if randomC then
				LOG("removing/assiging "..randomC.name)
				randomC.owner = player.armyName;
				table.remove(countries, randomI)
			end
		end
	end
	LOG(countryNum)
	
end
function initStartUnits()
	local yoffset = 6;
	for ci,continent in continents do
		LOG("Setting up "..continent.name)
		for i,cdata in continent.countries do
			-- Spawn one unit per country
			
			spawnCapital(cdata)
			setAsPresident(cdata, nil)		

			if cdata.startUnits then
				local ii = 0
				while ii < cdata.startUnits do
					local unit = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x-2,cdata.pos.y+10,cdata.pos.y+yoffset, 0,0,0)
					initUnit(unit)

					ii = ii+1
				end
			end
		end
--		local u = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x+2,cdata.pos.y+yoffset,cdata.pos.y+yoffset, 0,0,0)
	end
  	
	local i = 0		
	-- debug spawn some units
	while i < 0 do
	unit = CreateUnitHPR('uel0106', "ARMY_1",50,0,300, 0,0,0)
	i = i+1
	end
			
end

function initPlayers()
	-- ACU and Resources
	local playerACUs = GetUnitsInRect(Rect(0,900,1024,1024))
	for i,acu in playerACUs do
		LOG("found ACU "..acu:GetArmy())
	
		local player = {};
		player.index = acu:GetArmy();
		player.acu = acu;
		
		player.acu:SetProductionPerSecondMass(0);
		player.acu:SetProductionPerSecondEnergy(2000);
		player.acu.SRUnitsToBuild = 0;
		player.acu.player = player;
		
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

		--brain
		player.brain = GetArmyBrain(player.armyName)
		player.brain.player = player -- callback ( useful for coding an AI later)
		player.brain.CalculateScore = function(self)
			return player.empireSize
		end
		
		-- helper Functions for an AI or other scripts	
		player.GetRoundIdleTime = function()	return roundIdleSeconds	end
		player.GetContinents = 	  function()	return continents		end
		
		player.empireSize = 0;
	end
end

function initPlayerResources()
	checkCountryOwnership() -- initialize Country Ownerships
	-- set Starting Resources depending on owned Countries and # of players
    for i, player in players do
		local startResources = 50-(numPlayers()*5) - player.empireSize
		
		player.build = nil; --statistics
		player.acu:SRAddUnitResources(startResources)
	end
end

function initMissions()
	addMissionContinent({continents.as, continents.sa})
	addMissionContinent({continents.as, continents.af})
	addMissionContinent({continents.na, continents.af})
	addMissionContinent({continents.na, continents.au})	
	addMissionContinent({continents.eu, continents.sa, 'any'}) -- these two and any third one
	addMissionContinent({continents.eu, continents.au, 'any'}) -- these two and any third one
	for i, player in players do
		addMissionKill(player)
	end
	addMissionCountries(18,2) -- 2 units in 18 countries
	addMissionCountries(24,1) -- 1 unit in 24 countries
	
	-- Assigning them to players now
	for i, player in players do
		while not player.mission do
			local rm = missions[math.random(table.getn(missions))]
			-- mission not yet given
			if not rm.owner then
				-- dont kill yourself as a mission
				if not rm.target or rm.target != player then
					rm.owner = player
					player.mission = rm
				end
			end
		end
		
		local nn = GetArmyBrain(player.armyName).Nickname
--DEUBG		LOG(nn..": "..player.mission:getText())
	end
	
--	        player.objective = GetArmyBrain(player.armyName).Nickname..": Objective"
	--	LOG("Faction: "..GetFaction(player).SoundPrefix)
	

end

function addMissionContinent(cc)
	local mission = Class() {
		icon='capture',
		reqContinents = cc, 
		owner = false,
		getText = function(self)
			local names = ""
			for i,continent in self.reqContinents do
				local cn = ""
				if continent == "any" then 
					cn = "a 3rd continent of your choice"
				else
					cn = continent.name
				end
			
				if i < table.getn(self.reqContinents) then
					names = names..cn.." and "
				else
					names = names..cn
				end
			end
			return "Liberate "..names
		end,
		
		check = function (self)
			if self.owner then
				-- check number first
				continentCount = 0
				for i, continent in continents do
					if continent.owner == self.owner.armyName then
						continentCount = continentCount + 1
					end
				end
				if continentCount < table.getn(self.reqContinents) then
					return false -- not enough
				end
			
				for i, continent in self.reqContinents do
					if continent != 'any' and continent.owner != self.owner.armyName then
						return false
					end
				end
				return true
			else
				return false
			end
		end
	}
	table.insert(missions, mission)
end

function addMissionCountries(_empireSize, _minUnits)
	local mission = Class() {
		icon='capture',
		empireSize = _empireSize, 
		minUnits = _minUnits,
		owner = false,
		check = function (self)
			if self.owner then
				local matchingCountries = 0
				for ci,continent in continents do
					for i,country in continent.countries do		
						if country.owner == self.owner.armyName and country.friendlyUnits >= self.minUnits then
							matchingCountries = matchingCountries + 1
						end
					end
				end
				
				if matchingCountries >= self.empireSize then
					return true
				else
					return false
				end
			else
				return false
			end
		end,
		getText = function(self)
			if self.minUnits > 1 then
				return "Occupy "..self.empireSize.." territories with at least "..self.minUnits.." armies in each"
			else
				return "Occupy "..self.empireSize.." territories"
			end
		end
	}
	table.insert(missions, mission)
end

function addMissionKill(player)
	local mission = Class() {
		icon='kill',
		target = player,
		owner = false,
		check = function (self)
			if self.owner then
				if self.target.acu:IsDead() then return true
				else return false
				end
			else
				return false
			end
		end,
		getText = function(self)
			return "Eliminate "..GetArmyBrain(self.target.armyName).Nickname
		end
		
	}
	table.insert(missions, mission)
end


function GetFaction(player)
	return Factions[GetArmyBrain(player.armyName):GetFactionIndex()]
end

--[[
function GetEmpireSize(armyName)
	local es = 0
	for ci,continent in continents do
	for i,cdata in continent.countries do
		if cdata.owner == armyName then
			es = es +1
		end
	end
	end
	return es
end]]--

function spawnCapital(cdata)
	cdata.factoryOwnershipChanged = false
	spawnFactory(cdata)
	
	if cdata.walls != nil then
		cdata:walls(cdata)
	end
	
	if cdata.props != nil then
		cdata:props()
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
	u:SetIsValidTarget(false)
	u:SetDoNotTarget(true)
	u:SetMaxHealth(1)
	u:SetHealth(nil,1)
	u:SetRegenRate(1)
	u:SetIntelRadius('Vision', meter(baseSizeMeters*7))
	u:SetCustomName(name)
	cdata.factory = u
--	cdata.ownerId = armyId

	u:AddOnUnitBuiltCallback(function (factory, unit) 
		--debug: LOG("Unit has been Built: "..unit:GetEntityId())
		
		onRoundAction()
		initUnit(unit)
		
		unit.TeleportDrain = nil
--		unit.SetImmobile = function() end -- prevent the following function to make the unit moveable again.
		unit.InitiateTeleportThread = myInitiateTeleportThread
		local x = unit:GetNavigator():GetGoalPos()[1]+3;
		local y = unit:GetNavigator():GetGoalPos()[3];
		
		unit:OnTeleportUnit(unit, {x,0,y},{0,0,0,1})
--		IssueMove({unit}, Pos(x,y+1))

		
		end
		, categories.MOBILE)

	u.OnStartBuildOriginal = u.OnStartBuild
	u.OnStartBuild = function(self, unitBeingBuilt, order)
--		dump(unitBeingBuilt)
		
		local player = players[self:GetArmy()]

		if player.acu:SRProduceUnit() then 
			--debug: LOG(self:GetArmy().." start building ")
			onRoundAction()
			self:OnStartBuildOriginal(unitBeingBuilt, order)
		else
			--LOG("Build limit reached in Factory")
--			WaitTicks(50)
			unitBeingBuilt:Kill()
		end
	end
		
	u:SetBuildTimeMultiplier(0.01)
	u:SetConsumptionPerSecondMass(0)
	u.SetConsumptionPerSecondMass = function() end
--	u.UpdateConsumptionValues = function() end
	
end

function initUnit(unit)

	unit:AddOnKilledCallback(
	function(self) 
		LOG("Unit died")
		onRoundAction() 
	end) -- round is delayed on kills
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

	local x = country.pos.x-3
	local y = country.pos.y+5
	if not unit then
		unit = CreateUnitHPR('uel0106', country.owner, x,0,y, 0,0,0)
		unit.isInitialPresident = true;
		initUnit(unit)		
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

--debug	LOG("Teleport done")
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
	
	for i, player in players do
		player.empireSize = 0
	end
	
	for ci,continent in continents do
		continent.owner = nil;
		for i,cdata in continent.countries do		
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
							unit:SetSpeedMult(8) -- reset for successful liberators
							unit:SetAccMult(5)
							unit:SetTurnMult(5)
							
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
							unit:SetSpeedMult(0.6) -- no easy retreat for liberators
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
					cdata.friendlyUnits = friendlyUnits
				else
					enemyUnits = enemyUnits +counter
					enemyArmy = getArmyName(index)
					enemyArmyId = index
				end
		    end
			if enemyUnits > 0 then
				-- kill factory
				if cdata.factory then
					cdata.factory:SetCanBeKilled(true)
					cdata.factory:Kill()
					cdata.factory=nil
				end
--				setFactoryName(cdata,cdata.name..": "..friendlyUnits.." attacked by "..enemyUnits)
				cdata.isAttacked = true
			else
				setFactoryName(cdata,cdata.name..": "..friendlyUnits)
				cdata.isAttacked = false
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
			
			if continent.owner == nil or continent.owner == cdata.owner then
				continent.owner = cdata.owner
			else
				continent.owner = false
			end
					
			-- update Empire Size
			for i, player in players do
				if player.armyName == cdata.owner then
					player.empireSize = player.empireSize +1
				end
			end
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

function respawnFactory(c)
	if c.factory != nil then
		local f = c.factory
		c.factory = nil;
		f:SetCanBeKilled(true)
		if not f:IsDead() then f:Kill() end
		WaitSeconds(3)
	end
	
	WaitSeconds(2)
	if not c.isAttacked and c.factory == nil then -- only respawn if not being attacked
		LOG("SPAWNING FACTORY")
		spawnFactory(c)
		c.factoryOwnershipChanged = false
	end
end

function reassignFactories()
	for ci,continent in continents do
		for i,c in continent.countries do
			if c.factoryOwnershipChanged == true or c.factoryOwnershipChanged == nil or (c.factory and c.factory:IsDead()) or not c.factory then
				ForkThread(respawnFactory,c)
			end
		end
	end
end

##########################################
# Round Functions
##########################################

function checkEndOfRound()

	roundIdleSeconds = roundIdleSeconds + 1
	Sync.ObjectiveTimer = maxRoundIdleTime - roundIdleSeconds --targetTime - math.floor(GetGameTimeSeconds())
	

	if roundIdleSeconds >= maxRoundIdleTime then
		onRoundAction()
		beginNextRound()
	end
	
	if roundIdleSeconds+idleWarnTime > maxRoundIdleTime and roundIdleSeconds < maxRoundIdleTime-0 then
		displayRoundCountdown(0)
	end
	
	-- display after 5 seconds into each round
	if roundIdleSeconds == 5  then displayRoundCountdown(5) end
	if roundIdleSeconds == 15 then displayRoundCountdown(2) end
end

function displayRoundCountdown(staytime)
	local ileft = maxRoundIdleTime - roundIdleSeconds
	PrintText("Next Round will start in "..ileft.." seconds",20,'FFFFFFFF',staytime,'centerbottom') 
	WaitTicks(3)
end

function displayMissions()
  
	local m1 = {{text = '<LOC E01_M01_060_010>[{i EarthCom}]: Sir, maybe you should check your objectives.', vid = 'E01_EarthCom_M01_01131.sfd', bank = 'E01_VO', cue = 'E01_EarthCom_M01_01131', faction = 'UEF'}}

--	local m1 = {{text = '<LOC E01_M01_060_010>[{i EarthCom}]: Mission', 
--	vid = 'E01_EarthCom_M01_01131.sfd', bank = 'COMPUTER_UEF_VO', cue = 'UEFComputer_NewExpansion_01389', faction = 'UEF'}}
--	ScenarioFramework.Dialogue(m1)

	local mission = players[GetFocusArmy()].mission
	
--	        {ShowFaction = 'Cybran'}'capture'  'capture'
	if mission then
	ScenarioFramework.Objectives.Basic(
        'primary',
        'incomplete',
        'Your mission is to '..mission:getText(),
        "detail",
        ScenarioFramework.Objectives.GetActionIcon(mission.icon),
        {Category = categories.uel0001}
    )
	end
--	PrintText(mission:getText(),20,'FFFFFFFF',5,'center') 
--	WaitSeconds(1)
	
end

function displayRoundBegin()
	local ileft = maxRoundIdleTime - roundIdleSeconds
	PrintText("Round "..roundnum.." - Produce Units and Attack. Next Round will begin after "..ileft.." seconds idle",
		20,'Red',6,'centertop') 
		
	local E01_M01_060 = {{text = '<LOC E01_M01_060_010>[{i EarthCom}]: Sir, maybe you should check your objectives.', 
	vid = 'E01_EarthCom_M01_01131.sfd', bank = 'E01_VO', cue = 'E01_EarthCom_M01_01131', faction = 'UEF'},}
	local E01_M01_062 = {{text = '<LOC E01_T01_030_010>[{i Leopard11}]: We want to be free. Is that too much to ask?', 
	vid = 'E01_Leopard11_T01_0033.sfd', bank = 'E01_VO', cue = 'E01_Leopard11_T01_0033', faction = 'Cybran'}}
	local E01_M01_061 = {{text = '<LOC E01_T01_030_010>[{i Leopard11}]: We want to be free. Is that too much to ask?', 
	vid = 'E01_Leopard11_T01_0033.sfd', bank = 'Experimental_VO', cue = 'Experimental_EarthCom_UEF_01219', faction = 'Cybran'}}
	local E01_M01_061 = {{text = '<LOC E01_T01_030_010>[{i Leopard11}]: We want to be free. Is that too much to ask?', 
	vid = 'E01_Leopard11_T01_0033.sfd', bank = 'Ops', cue = 'Ops_EarthCom_EarthCom_01425', faction = 'Cybran'}}

	local E01_M01_061 = {{text = '<LOC E01_T01_030_010>[{i Leopard11}]: We want to be free. Is that too much to ask?', 
	vid = 'E01_Leopard11_T01_0033.sfd', bank = 'Ops', cue = 'Ops_EarthCom_EarthCom_01425', faction = 'Cybran'}}
	
	--		ScenarioFramework.Dialogue(E01_M01_061)

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
function onRoundAction(start)
	if start then
		roundIdleSeconds = start
	else
		roundIdleSeconds = 0
	end
end



function beginNextRound()
	
	roundnum = roundnum +1
	LOG("A NEW ROUND "..roundnum.." has begun")
	
	-- distribute Resources
	for i, player in players do

		player.build = {};
		player.build.ter = math.floor(player.empireSize/3)
		if player.build.ter < 3 then player.build.ter = 3 end
		
		-- bonus card cashin
		player.build.bonus = player.nextRoundBonusProfit
		player.nextRoundBonusProfit = 0
		player.bonusCardSpawned = false

		-- Continent resources
		player.build.cont = 0
		for i,continent in continents do
			if continent.owner == player.armyName then
				LOG(continent.owner.." receives "..continent.ownerBonus.." for "..continent.name)
				player.build.cont = player.build.cont + continent.ownerBonus
			end
		end
		
		player.build.total = player.build.ter + player.build.cont + player.build.bonus
		player.acu:SRAddUnitResources(player.build.total)
	end
	
	-- new round, display it has begun
	displayRoundBegin()
end

function checkPlayerDeath(player)
-- this is buggy
	if player.empireSize == 0 then
		if not player.acu:IsDead() then 
			player.acu:Kill() -- goodbye ACU
		end
--		player.brain:OnDefeat()
	end
end

function checkPlayerWin(player)
--	LOG("checking win on "..player.mission:getText())
	if player.mission:check() then
		PrintText(player.brain.Nickname.." won: "..player.mission:getText(),20,'FFFFFFFF',5,'center') 

		-- Kill all other units!
		player.acu:SetIntelRadius('Vision', 2000)
		continents = {} -- destroy countries to prevent respawns
		WaitSeconds(1)		
		local otherUnits = GetUnitsInRect(Rect(0,0,1024,1024))
		for i, unit in otherUnits do
			if player.armyName != getArmyName(unit) then
				unit:Kill()
			end
		end

		WaitSeconds(500)
	end
end

function updateSecondaryMissions()
	for i, player in players do
	
--		LOG(i.." "..player.acu.SRUnitsToBuild)

		if i == GetFocusArmy() then
			-- only do in own sim state, not for others (this doesnt desync!)
			
			local objTitle = 'Reinforce your territories - you can place '..player.acu.SRUnitsToBuild..' units. '
			if player.build then
				objTitle = objTitle..'('..player.build.total..' this round, '..player.build.ter..' from territories, '..player.build.cont..' from continents, '..player.build.bonus..' from wreckage)'
			end
			
			
			if player.buildObjective then
				if player.acu.SRUnitsToBuild == 0 then
					-- remove objective
--		            ScenarioFramework.Objectives.UpdateObjective( objTitle, 'delete', objTitle, player.buildObjective.Tag)
					ScenarioFramework.Objectives.UpdateObjective( objTitle, 'complete', "complete", player.buildObjective.Tag)
--					ScenarioFramework.Objectives.DeleteObjective(player.buildObjective, false)
					player.buildObjective = nil
				else
		            ScenarioFramework.Objectives.UpdateObjective( objTitle, 'title', objTitle, player.buildObjective.Tag)
				end
			end
		
			-- Add secondary objective - use these resources!!
			if not player.buildObjective and player.acu.SRUnitsToBuild > 0 then
				player.buildObjective = ScenarioFramework.Objectives.Basic(
		        '',
		        'incomplete',
		        objTitle,
		        "detail",
		        ScenarioFramework.Objectives.GetActionIcon("build"),
		        {Category = categories.uel0106}
				)
			end
			
			-- warn player if he has still not built his units
			if player.acu.SRUnitsToBuild > 0 and maxRoundIdleTime - roundIdleSeconds == 15 then
				player.buildObjectiveWarn = true
				local m1 = {{text = '<LOC E01_M01_060_010>[{i EarthCom}]: Sir, maybe you should check your objectives.', vid = 'E01_EarthCom_M01_01131.sfd', bank = 'E01_VO', cue = 'E01_EarthCom_M01_01131', faction = 'UEF'}}
				ScenarioFramework.Dialogue(m1)		
			end
			
			-- check bonus unit cards
			if canCashinAny(player) then
--				LOG("We could cash in bonus cards!")
				-- Add secondary objective - use these resources!!
				if not player.cardObjective  then
					player.cardObjective = ScenarioFramework.Objectives.Basic(
			        '',
			        'incomplete',
			        'Reclaim the wreckages near your ACU for Bonus Units. Rightclick to zoom in',
			        "detail",
			        ScenarioFramework.Objectives.GetActionIcon("reclaim"),
			        --{Category = categories.uel0001, Units = {player.acu}}
			        {Units = {player.acu}}
					)
				end
			else
				if player.cardObjective then
					-- remove objective
					ScenarioFramework.Objectives.UpdateObjective( objTitle, 'complete', "complete", player.cardObjective.Tag)
					player.cardObjective = nil
				end
			end
			
			--- show a Liberate a country mission
			if player.bonusCardSpawned and player.fightObjective then
				ScenarioFramework.Objectives.UpdateObjective( objTitle, 'complete', "complete", player.fightObjective.Tag)
				player.fightObjective = nil
			end
			if player.acu.SRUnitsToBuild == 0 and not player.bonusCardSpawned and not player.fightObjective then
					player.fightObjective = ScenarioFramework.Objectives.Basic(
			        '',
			        'incomplete',
			        'Liberate a territory of your choice to receive bonus wreckage',
			        "detail",
			        ScenarioFramework.Objectives.GetActionIcon("kill"),
			        {Category = categories.ueb0101}
					)
				end
			
		end
	end
end

function checkEndOfGame()
	for i, player in players do
		checkPlayerDeath(player)
		checkPlayerWin(player)
	end
end

function mainThread()

	-- We are in the game!
	displayMissions()
	displayRoundBegin()

	while true do
		checkCountryOwnership()
		
		checkEndOfRound()
		checkEndOfGame()
		
--		updateScore()
		WaitSeconds(1)
		updateSecondaryMissions()
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

###### bonus cards #########

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
--				removeCard(player, self.cardType.unit) -- remove the third one too!
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
				
				if player.index == GetFocusArmy() then
					zoomOut()
				end
			else
				-- respawn prop
				spawnCardProp(player, self.cardType, self.slotNumber)
--				spawnCard(player, self.cardType)
			end
	end
	return card;
end

function canCashinAny(player)
	-- check for three different cards
	local hasAll = true;
	for i, cardType in cardTypes do
		if hasCard(player, cardType.unit) >= 3 then
			return true
		end
	
		if hasCard(player, cardType.unit) == 0 then
			hasAll = false; -- we dont have this unit - profit is zero
		end
	end
	if hasAll then
		return true
	end
	return false
end

function hasCard(player, unitType)
	local hasCounter = 0;
	if player.cardSlots then
		for i, slot in player.cardSlots do
			if slot then
				if slot.cardType.unit == unitType then
					hasCounter = hasCounter + 1
				end
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
					return;
				end
			end
		end
	end
	return hasCounter;
end
