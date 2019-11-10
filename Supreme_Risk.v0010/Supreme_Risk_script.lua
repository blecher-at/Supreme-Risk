--[[
Don't edit or remove this comment block! It is used by the editor to store information since i'm too lazy to write a good LUA parser... -Haz
SETTINGS
RestrictedEnhancements=ResourceAllocation,DamageStablization,AdvancedEngineering,T3Engineering,HeavyAntiMatterCannon,LeftPod,RightPod,Shield,ShieldGeneratorField,TacticalMissile,TacticalNukeMissile,Teleporter
RestrictedCategories=EXPERIMENTAL,MASSFABRICATION
END
--]]

-------------------------------------------------------------
--               S U P R E M E   R I S K                    #
-------------------------------------------------------------
--
-- A Supreme Commander Modification
-- Map and Scripting 
-- (C) 2007 Stephan Blecher (stephan@blecher.at)
--
-- Use at your own risk and have lots of fun!
-- Version 10
--
-------------------------------------------------------------



--         local dis=VDist3(location, unit:GetPosition()) 

local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local Factions = import('/lua/factions.lua').Factions

--scenario utilities
local Utilities = import('/lua/utilities.lua')

--interface utilities
local UIUtil = import('/lua/ui/uiutil.lua')
--local gameParent = import('/lua/ui/game/gamemain.lua').GetGameParent()

local executing = false
local beatTime = 5
local baseSizeMeters = 400;
local roundIdleSeconds = 0; -- this round is idle for n seconds now
local maxRoundIdleTime = 30; -- number of seconds from last round action to begin next round
local idleWarnMin = 12; -- warn n seconds before end of round
local idleWarnMax = 28; -- warn n seconds before end of round
local roundnum = 1;
local roundTotalTime = 0;

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
	local count = 100
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
			{name='Argentina',				pos = {x = 290, y = 670}},
			{name='Brasil',					pos = {x = 350, y = 590}},	
			{name='Venezuela',				pos = {x = 250, y = 540}},	
			{name='Peru',					pos = {x = 280, y = 595}},	
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
			{name='Central Europe',			pos = {x = 489, y = 390}},
			{name='Western Europe',			pos = {x = 460, y = 416}},
			{name='Eastern Europe',			pos = {x = 540, y = 413}},
			{name='Great Britain',			pos = {x = 448, y = 372}},
			{name='Scandinavia',			pos = {x = 505, y = 345}},
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
		teleporterDest = Pos(940,307),
    },
	{
		sourceZone = Rect(700,0,1024,500), -- redirect if into zone and 
		targetZone = Rect(1,1,300,500), -- move order into this zone is issued
		name		='kamc',
		teleporterSource = Pos(1022,305),
		teleporterDest = Pos(60,300),
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
	ScenarioInfo.Options.PrebuiltUnits = nil
	ScenarioInfo.Options.Victory = 'sandbox'

	InitializeSupremeRiskArmies()

	ScenarioFramework.SetPlayableArea('AREA_1' , false)
  
	--zoomOut()
	for a, ccc in ScenarioUtils.AreaToRect('AREA_1') do LOG(a.." "..ccc) end

	LOG("ONPOPULATE END")
end

function InitializeSupremeRiskArmies()
    local tblGroups = {}
    local tblArmy = ListArmies()

    local civOpt = ScenarioInfo.Options.CivilianAlliance

    --local bCreateInitial = ShouldCreateInitialArmyUnits()

    for iArmy, strArmy in pairs(tblArmy) do
        local tblData = Scenario.Armies[strArmy]

        tblGroups[ strArmy ] = {}

        if tblData then

            ----[ If an actual starting position is defined, overwrite the        ]--
            ----[ randomly generated one.                                         ]--

            --LOG('*DEBUG: InitializeArmies, army = ', strArmy)

            SetArmyEconomy(strArmy, tblData.Economy.mass, tblData.Economy.energy)

            --GetArmyBrain(strArmy):InitializePlatoonBuildManager()
            --LoadArmyPBMBuilders(strArmy)
            if GetArmyBrain(strArmy).SkirmishSystems then
                GetArmyBrain(strArmy):InitializeSkirmishSystems()
            end

            local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian

            if armyIsCiv and civOpt ~= 'neutral' and strArmy ~= 'NEUTRAL_CIVILIAN' then -- give enemy civilians darker color
                SetArmyColor(strArmy, 255, 48, 48) -- non-player red color for enemy civs
            end

            ----[ irumsey                                                         ]--
            ----[ Temporary defaults.  Make sure some fighting will break out.    ]--
            for iEnemy, strEnemy in tblArmy do
                local enemyIsCiv = ScenarioInfo.ArmySetup[strEnemy].Civilian
                local a, e = iArmy, iEnemy
                local state = 'Enemy'

                if a ~= e then
                    if armyIsCiv or enemyIsCiv then
                        if civOpt == 'neutral' or strArmy == 'NEUTRAL_CIVILIAN' or strEnemy == 'NEUTRAL_CIVILIAN' then
                            state = 'Neutral'
                        end

                        if ScenarioInfo.Options['RevealCivilians'] == 'Yes' and ScenarioInfo.ArmySetup[strEnemy].Human then
                            ForkThread(function()
                                WaitSeconds(.1)
                                local real_state = IsAlly(a, e) and 'Ally' or IsEnemy(a, e) and 'Enemy' or 'Neutral'

                                GetArmyBrain(e):SetupArmyIntelTrigger({
                                    Category=categories.ALLUNITS,
                                    Type='LOSNow',
                                    Value=true,
                                    OnceOnly=true,
                                    TargetAIBrain=GetArmyBrain(a),
                                    CallbackFunction=function()
                                        SetAlliance(a, e, real_state)
                                    end,
                                })
                                SetAlliance(a, e, 'Ally')
                            end)
                        end
                    end

                    if state then
                        SetAlliance(a, e, state)
                    end
                end
            end
        end
    end

    return tblGroups
end


function zoomOut()
	-- Set Camera to show full Map
	local Camera = import('/lua/SimCamera.lua').SimCamera
	local cam = Camera("WorldCamera")
	--  cam:MoveTo(ScenarioUtils.AreaToRect('AREA_1'))
	
	--WaitSeconds(10)
	LOG("ZOOM OUT")
	cam:SetZoom(2000,0)
end
function numPlayers()
	return table.getn(players)
end

-- acu functions
function onSRProduceUnit(acu, unitBeingBuilt)
	if acu.SRUnitsToBuild >= unitBeingBuilt.riskBuildCount then
		acu.SRUnitsToBuild = acu.SRUnitsToBuild - unitBeingBuilt.riskBuildCount;
		acu:SetProductionPerSecondMass(acu.SRUnitsToBuild) -- update UI
		LOG("BUILD ::"..acu.SRUnitsToBuild)

		-- unpause factories now tha
		for ci,continent in continents do
			for i,cdata in continent.countries do		
				if cdata.factory and cdata.owner == player.armyName then
					cdata.factory:SetProductionActive(true);
					--cdata.factory.onAI = true
				end
			end
		end
	
		return true
	else
		return false
	end
end

function onSRAddUnitResources(acu, un)
--	acu.SRUnitsToBuild = acu.SRUnitsToBuild + un
	acu.SRUnitsToBuild = un -- max units to build is reset on each round, to prevent saving them up ,,,
	
	if not acu:IsDead() then
		setPlayerRestrictions(acu.index, acu.SRUnitsToBuild)
		acu:SetProductionPerSecondMass(acu.SRUnitsToBuild) -- update UI
	end
end


---------------------------------
------------- init ##############
---------------------------------
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
  zoomOut()
  
end

function init()
	for index,army in ListArmies() do
		LOG(index.." "..army.." is playing")
		
		setPlayerRestrictions(index, 1)

	end
	
end

function setPlayerRestrictions( index, SRUnitsToBuild) 
		
		--Building Restrictions
		ScenarioFramework.AddRestriction(index, categories.ALLUNITS)
		ScenarioFramework.RemoveRestriction(index, categories.uel0106) -- mech marine
		
		-- striker 
		if SRUnitsToBuild >= 5 then ScenarioFramework.RemoveRestriction(index, categories.uel0201) end
		
		-- lobo
		if SRUnitsToBuild >= 10 then ScenarioFramework.RemoveRestriction(index, categories.uel0103) end
		--ScenarioFramework.RemoveRestriction(index, categories.ual0106)
		--ScenarioFramework.RemoveRestriction(index, categories.url0106)
		ScenarioFramework.RemoveRestriction(index, categories.ueb0301) -- factory
end

function getArmyByName(name)
	for index,army in ListArmies() do
		if army == name then
			return index
		end
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
	end			
end

function getPlayerByName(name)
    for i, player in players do
		if player.armyName == name then 
			return player
		end
	end
	return nil
end


function getPlayerByIndex(index)
    for i, player in players do
		if player.index == index then 
			return player
		end
	end
	return nil
end

function initPlayers()
	-- ACU and Resources
	local tblArmy = ListArmies()
    local factions = import('/lua/factions.lua')
    local bCreateInitial = ShouldCreateInitialArmyUnits()
    local armies = {}
	
    --for i, name in tblArmy do
    --    armies[name] = i
    --end

    ScenarioInfo.CampaignMode = true
    --Sync.CampaignMode = true
    import('/lua/sim/simuistate.lua').IsCampaign(true)

	--local playerACUs = GetUnitsInRect(Rect(0,900,1024,1024))
    --for i,acu in playerACUs do
	
     for i, name in tblArmy do
		local tblData = Scenario.Armies[name]
		dump(tblData)
		
		-- spawn ARMY_9 as 3rd player if only two players are in the game
		if tblData.SRInit or i == 3 and not tblData.SRInit then
			--armies[name] = i
			
			local army = i;
			local x = army * ( 1024 / 7);
			local y = 910;
			local player = {}
			player.acu = CreateUnitHPR('xrb0104', army, x,y,y, 0,0,0)


			--player.index = acu:GetArmy();
			player.index = i;
			--player.acu = acu;
			
			player.acu:SetProductionPerSecondMass(0);
			player.acu:SetProductionPerSecondEnergy(2000);
			player.acu.SRUnitsToBuild = 0;
			player.acu.player = player;
			
			player.nextRoundBonusProfit = 0; --- card bonuses
			player.bonusCardSpawned = false;
			
			player.armyName = getArmyName(player.acu)
			players[army] = player;
			LOG("found ACU "..i.." - "..player.armyName)

			-- resource stuff
			player.acu.SRProduceUnit = onSRProduceUnit
			player.acu.SRAddUnitResources = onSRAddUnitResources
			player.acu.index = player.index;

			player.resourceMultiplyer = 1 --player.acu:GetBlueprint().Economy.ProductionPerSecondMass
			
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
			
			if not player.brain.OnOrigDefeat then
				player.brain.OnOrigDefeat = player.brain.OnDefeat
			end
			player.brain.OnDefeat = onPlayerDefeat
			
			-- helper Functions for an AI or other scripts	
			player.GetRoundIdleTime = function()	return roundIdleSeconds	end
			player.GetContinents = 	  function()	return continents		end
			
			player.faction = GetFaction(player);
			player.empireSize = 0;
		end
	end
end

function onPlayerDefeat(brain)
	-- TODO: Spawn an AI here, for now just dieing is disabled
	brain.player.isAI = true
	
	for ci,continent in continents do
		continent.owners = {};
		for i,cdata in continent.countries do		
			if cdata.factory and cdata.owner == brain.player.armyName and not cdata.factory.onAI then
				IssueBuildFactory({cdata.factory}, "uel0106",9999)
				cdata.factory.onAI = true
			end
		end
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
	if ScenarioInfo.Options.Victory == "eradication" then
		for i, player in players do
			player.mission = getMissionWD()
			player.mission.owner = player
		end
	else
		addMissionContinent({continents.as, continents.sa})
		addMissionContinent({continents.as, continents.af})
		addMissionContinent({continents.na, continents.af})
		addMissionContinent({continents.na, continents.au})	
		addMissionContinent({continents.eu, continents.sa, 'any'}) -- these two and any third one
		addMissionContinent({continents.eu, continents.au, 'any'}) -- these two and any third one
		for i, player in players do
			addMissionKill(player)
		end
		if table.getn(players) > 2 then
			addMissionCountries(18,2) -- 2 units in 18 countries
			addMissionCountries(24,1) -- 1 unit in 24 countries
		end
		
		-- Assigning them to players now
		for i, player in players do
			while not player.mission do
				local rm = missions[math.random(table.getn(missions))]
				-- mission not yet given
				if not rm.owner then
					-- dont kill yourself as a mission
					if not rm.target or not IsAlly(rm.target.index, player.index) then
						rm.owner = player
						player.mission = rm
					end
				end
			end
			
			local nn = GetArmyBrain(player.armyName).Nickname
--DEUBG		LOG(nn..": "..player.mission:getText())
		end
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
			local count = table.getn(self.reqContinents);
			for i,continent in self.reqContinents do
				local cn = ""
				if continent == "any" then 
					cn = ", and a 3rd continent of your choice"
				else
					cn = continent.name
				end
			
				if i == 1 and count > 1 then
					if count == 2 then
						names = names..cn.." and "
					else
						names = names..cn..", "
					end
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
					if checkContinentOwn(continent, self.owner) then
						continentCount = continentCount + 1
					end
				end
				if continentCount < table.getn(self.reqContinents) then
					return false -- not enough
				end
			
				for i, continent in self.reqContinents do
					if continent != 'any' and not checkContinentOwn(continent, self.owner) then
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


function getMissionWD()
	local mission = Class() {
		icon='kill',
		owner = false,
		check = function (self)
			if self.owner then
				for i, player in players do
					if not IsAlly(player.index, self.owner.index) and not player.acu:IsDead() then return false 
					end
				end
				return true
			else
				return false
			end
		end,
		getText = function(self)
			return "Dominate the world. Eliminate all enemies"
		end
		
	}
	return mission
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
	local name = 'ueb0301'
	local country = cdata
	
--	if GetArmyBrain(cdata.owner):GetFactionIndex() == 2 then
--		name = 'uab0101';
--	end
--	if GetArmyBrain(cdata.owner):GetFactionIndex() == 3 then
--		name = 'urb0101';
--	end
	
	local u = CreateUnitHPR(name, army, x,y,y, 0,0,0)

	
	u.CreateWreckage = function() end

	u:SetAllWeaponsEnabled(false)		
	u:SetCanBeKilled(true)
	u:SetIsValidTarget(false)
	u:SetDoNotTarget(true)
	u:SetMaxHealth(10000)
	u:SetHealth(nil,10000)
	u:SetRegenRate(1)
	u:SetIntelRadius('Vision', meter(baseSizeMeters*7))
	u:SetCustomName(name)
	cdata.factory = u
--	cdata.ownerId = armyId

	--u.OnStopBuild = function(factory, unit) 
	--	onRoundAction()
	--	initUnit(unit)
	--	Warp(unit, {x+0,0,y+5},{0,0,0,1})
	--end

	u:AddOnUnitBuiltCallback(function (factory, unitBeingBuilt) 
		LOG("Unit has been Built in "..cdata.name..": "..unitBeingBuilt:GetEntityId().." owner: "..country.owner)
		
		--onRoundAction()

		--dump(unitbp)
		local count = unitBeingBuilt.riskBuildCount
		unitBeingBuilt:Destroy()
		
		for i=1, count do 
			local spot = findFreeUnitSpot(country)
			
			--local x = country.pos.x-5 + country.friendlyUnits * 1
			--local y = country.pos.y+5 -- + (country.friendlyUnits / 10) * 1
			unit = CreateUnitHPR('uel0106', country.owner, spot.x,0,spot.y, 0,0,0)
			--unit.isInitialPresident = true;
			initUnit(unit)	
			country.friendlyUnits = country.friendlyUnits + 1
		end

		local player = getPlayerByName(country.owner)
		
		LOG("Unit has been Built in "..cdata.name..". Left: "..player.acu.SRUnitsToBuild)
		setPlayerRestrictions(country.owner, player.acu.SRUnitsToBuild)
	
		--self.FactoryBuildFailed = true
		--StructureUnit.OnStopBuild(self, unitBeingBuilt, order )
		--end
		--local unit = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x,cdata.pos.y+10,cdata.pos.y+10, 0,0,0)
		--initUnit(unit)


		
		end
		, categories.MOBILE)

	u.OnStartBuildOriginal = u.OnStartBuild
	u.OnStartBuild = function(self, unitBeingBuilt, order)
--		dump(unitBeingBuilt)
		
		local player = players[self:GetArmy()]
		
		local count = 1;
		local unitbp = unitBeingBuilt:GetBlueprint()
		local unitid = unitbp.BlueprintId;
		
		unitBeingBuilt.riskBuildCount = 1;
		if unitid == 'uel0201' then unitBeingBuilt.riskBuildCount = 5 end
		if unitid == 'uel0103' then unitBeingBuilt.riskBuildCount = 10 end

		if player.acu:SRProduceUnit(unitBeingBuilt) then 
			LOG(self:GetArmy().." start building ")
			--onRoundAction()
			self:OnStartBuildOriginal(unitBeingBuilt, order)
			
			
			--unitBeingBuilt:Kill()
			--cdata.factory:SetProductionActive(false);

		else
			LOG("Build limit reached in Factory")
			unitBeingBuilt:Destroy() 
			--IssueStop({cdata.factory});
			--cdata.factory:SetPaused(true);
			--cdata.factory:SetProductionActive(false);

--			WaitTicks(50)
		end
		
		
	end
		
	u:SetBuildTimeMultiplier(0.01)
	u:SetConsumptionPerSecondMass(0)
	u.SetConsumptionPerSecondMass = function() end
--	u.UpdateConsumptionValues = function() end
	
end

function findFreeUnitSpot(country)
	local foundPos = {}
	local initialx = country.pos.x - 4.5;
	foundPos.x = initialx;
	foundPos.y = country.pos.y + 5;
	local maxWidth = 10
	local step = 1
	
	while true do
		local units = GetUnitsInRect(Rect(foundPos.x, foundPos.y, foundPos.x + 1, foundPos.y + 1))
		
		if not units then
			return foundPos
		else
			-- GetUnitsInRect is not exact, need to compare position
			local unitsfound = 0
			for i, unit in units do
				local unitpos = unit:GetPosition()
--				if (abs(unitpos[1] - foundPos.x) <= 1 and abs(unitpos[3] - foundPos.y) <= 1) then 
				if unitpos[1] == foundPos.x and unitpos[3] == foundPos.y then 
					unitsfound = unitsfound + 1
				end
			end
			
			if unitsfound > 0 then
				foundPos.x = foundPos.x + step
				if foundPos.x - initialx >= maxWidth then
					foundPos.x = initialx
					foundPos.y = foundPos.y + step
				end
			else 
				return foundPos
			end
			
			
		end
	end
end


function initUnit(unit)

--	unit:AddOnKilledCallback(
--	function(self) 
--		LOG("Unit died")
--		onRoundAction() 
--	end) -- round is delayed on kills
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

	local x = country.pos.x-4
	local y = country.pos.y-2
	if unit then
		unit:Destroy()
	end
	
	--if not unit then
		unit = CreateUnitHPR('uel0106', country.owner, x,0,y, 0,0,0)
		unit.isInitialPresident = true;
		initUnit(unit)		
	--end

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
		-- is this causing a bug? unit:OnTeleportUnit(unit, {x,0,y},{0,0,0,1})
		
--		Warp(unit,{country.pos.x,0,country.pos.y+6,0},{0,0,0,1})
		end
	end
end


function myInitiateTeleportThread(self, teleporter, location, orientation)
	LOG("Teleport start")
        self.UnitBeingTeleported = self
        self:SetImmobile(true)

        self:PlayUnitSound('TeleportStart')
        self:PlayUnitAmbientSound('TeleportLoop')

        -- create teleport charge effect
        -- self:PlayTeleportChargeEffects()
        self:PlayTeleportOutEffects()
        self:CleanupTeleportChargeEffects()
        WaitSeconds( 0.1 )
        --Teleport Sound
        self:SetWorkProgress(0.0)
        Warp(self, location, orientation)
        self:PlayTeleportInEffects()
        WaitSeconds( 0.1 ) # Perform cooldown Teleportation FX here
    --Landing Sound
    --LOG('DROP')
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
--						dump(unit:GetNavigator():GetCurrentTargetPos())
					
						-- redirect to teleport zone
--						LOG("WP status: "..unit:GetNavigator():GetStatus())
						unit:GetNavigator():SetGoal(zone.teleporterSource)
--						unit:GetNavigator():SetSpeedThroughGoal(zone.teleporterSource)
						 
						--IssueMove({unit}, zone.teleporterSource)
					end
				end
			end
		end
		
		local unitsToTeleport = GetUnitsInRect(Pos2Rect(zone.teleporterSource, 40))
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

--					LOG("Warping unit from Zone "..zone.name.." to "..Xsave('aaa',teleportPos))
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
		continent.owners = {};
		for i,cdata in continent.countries do		
		
			if roundTotalTime == 0 then
				cdata.conqueredThisRound = false
			end
			
			rect = {x0 = cdata.pos.x - meter(baseSizeMeters)*baseSizeInner,
					x1 = cdata.pos.x + meter(baseSizeMeters)*baseSizeInner,
					y0 = cdata.pos.y - meter(baseSizeMeters)*baseSizeInner,
					y1 = cdata.pos.y + meter(baseSizeMeters)*baseSizeInner
					}
					
			local units = GetUnitsInRect(rect)
			local currentOwnerIndex = getPlayerByName(cdata.owner).index
			
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
						
						
						currentOwnerIndex = getPlayerByName(cdata.owner).index
						if currentOwnerIndex and IsAlly(unit:GetArmy(), currentOwnerIndex) then
							-- own or allied unit
							unit:SetSpeedMult(5) -- reset for successful liberators
							unit:SetAccMult(5)
							unit:SetTurnMult(5)
							
							weapon:ChangeRateOfFire(2)
--						weapon:SetTurretYawSpeed(300)
--						weapon:SetTurretPitchSpeed(300)
							weapon:ChangeMaxRadius(meter(baseSizeMeters)*baseSizeInner*0.8)
							weapon:SetFiringRandomness(1.2)
						
							-- HOME BASES (Have units stay there for a while, and only move one territory per round), init at the beginning of the round
							if not unit.homebase or roundTotalTime == 0 or cdata.conqueredThisRound then
								unit.homebase = cdata
							end
							
							if cdata.president != unit then
								if unit.homebase == cdata then
								--unit:SetCustomName("") --Citizen of "..cdata.name)
--								unit:SetImmobile(false)
									unit:SetCustomName("Citizen of "..cdata.name)
									unit.isResting = false;
									unit:SetImmobile(false)
								else
	--								unit:SetImmobile(true) -- unit:SetSpeedMult(0.4) -- have it stay here for a while		
									
--									unit:SetSpeedMult(0) -- dont move a lot anymore
										--unit:SetImmobile(true)
									if not unit.isResting then
										unit.TeleportDrain = nil
--									unit.SetImmobile = function() end -- prevent the following function to make the unit moveable again.
										unit.InitiateTeleportThread = myInitiateTeleportThread
										if not cdata.restingpos or cdata.restingpos > 20 then
											cdata.restingpos = 0
										else
											cdata.restingpos = cdata.restingpos + 1
										end
										
										if cdata.restingpos>10 then
											--unit:OnTeleportUnit(unit, {cdata.pos.x-15+cdata.restingpos,0,cdata.pos.y-6},{0,0,0,1})
										else
											--unit:OnTeleportUnit(unit, {cdata.pos.x-5+cdata.restingpos,0,cdata.pos.y-4},{0,0,0,1})										
										end
										
										--if cdata.restingpos == 0 then
										--	unit:SetCustomName("resting - moving next round again") --Citizen of "..cdata.name)
										--else
										--	unit:SetCustomName("resting") --Citizen of "..cdata.name)
										--end
										--unit.isResting = true;
									end
								end
							end
							
							if not presidentIsAlive(cdata) then
							LOG("President of "..cdata.name.." is dead")
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
				if currentOwnerIndex and IsAlly(index, currentOwnerIndex) then
					friendlyUnits = friendlyUnits + counter
					cdata.friendlyUnits = friendlyUnits
				else
					enemyUnits = enemyUnits +counter
					enemyArmy = getArmyName(index)
					enemyArmyId = index
				end

				--LOG("player "..index.." "..getArmyName(index)..": friendlyUnits"..friendlyUnits.." found in "..cdata.name.." ("..cdata.owner..")");
				--LOG("player "..index.." "..getArmyName(index)..": enemyUnits"..enemyUnits.." found in "..cdata.name.." ("..cdata.owner..")");
		    end
			
			if enemyUnits > 0 then
				LOG(cdata.name.." has enemies - destroying factory")
				-- kill factory
				if cdata.factory then
					setFactoryName(cdata,cdata.name..": "..friendlyUnits.." attacked by "..enemyUnits)
					cdata.factory:SetCanBeKilled(true)
					cdata.factory:Kill()
					cdata.factory=nil
				end
				cdata.isAttacked = true
				cdata.attacker = enemyArmy
			else
				setFactoryName(cdata,cdata.name..": "..friendlyUnits)
				cdata.isAttacked = false
			end

			if friendlyUnits == 0 and enemyUnits > 0 then
				LOG(cdata.name.." liberated by "..cdata.attacker)
				
				spawnRandomCard(getPlayerByName(cdata.attacker)) -- spawn card for player
				cdata.owner = cdata.attacker				
				cdata.factoryOwnershipChanged = true;
				cdata.conqueredThisRound = true;


			end
			
			if friendlyUnits == 0 and enemyUnits == 0 then
				-- respawn president unit if no enemies left after battle
				LOG("President of "..cdata.name.." resurrected")
				setAsPresident(cdata, nil)
			end
			
			-- update
			currentOwnerIndex = getArmyByName(cdata.owner)

			-- Continent Ownership
			if not continent.owners[currentOwnerIndex] then 
				continent.owners[currentOwnerIndex] = 1
			else
				continent.owners[currentOwnerIndex] = continent.owners[currentOwnerIndex] +1;
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
	LOG("respawnFactory "..c.name)
	if c.factory != nil then
		local f = c.factory
		c.factory = nil;
		f:SetCanBeKilled(true)
		if not f:IsDead() then f:Destroy() end
		WaitSeconds(1)
	end
	
	--WaitSeconds(2)
	--LOG("SPAWNING FACTORY in "..c.name.." - "..string.format("bool: %t", c.isAttacked))
	if not c.isAttacked and c.factory == nil then -- only respawn if not being attacked
		spawnFactory(c)
		c.factoryOwnershipChanged = false
		
		local liberatorPlayer = getPlayerByName(c.owner)
		local focusPlayer = players[GetFocusArmy()]
				
		local income = computeIncome(liberatorPlayer)
		if focusPlayer == liberatorPlayer and income then
			PrintText('You liberated '..c.name..'!',
					24, 'FFCCFFCC',10,'center')
			PrintText('Next round you will receive '..income.total..' units.',
					20, 'FFEEFFEE',10,'center')
			PrintText('('..income.ter..' from territories, '..income.cont..' from continents, '..income.bonus..' from wreckage)',
					15, 'FFEEFFEE',10,'center')
		else
			local liberatorNickname = GetArmyBrain(liberatorPlayer.armyName).Nickname
			PrintText(c.name..' has been liberated by '..liberatorNickname, 20, 'FFFFCCCC',3,'center')
		end
	end
end

function reassignFactories()
	for ci,continent in continents do
		for i,c in continent.countries do
			local dead = c.factory == nil or c.factory:IsDead()
			if c.factoryOwnershipChanged == true then
				LOG("REASSIGNING FACTORY TO OWNER "..c.name)
				ForkThread(respawnFactory,c)
			end
		end
	end
end

-------------------------------------------
-- Round Functions
-------------------------------------------

function checkEndOfRound()

	roundIdleSeconds = roundIdleSeconds + 1
	roundTotalTime = roundTotalTime + 1
	--Sync.ObjectiveTimer = maxRoundIdleTime - roundIdleSeconds --targetTime - math.floor(GetGameTimeSeconds())
	
	-- Restart Round
	if roundIdleSeconds >= maxRoundIdleTime then
		roundIdleSeconds = 0
		beginNextRound()
	end
	
	displayRoundCountdown(0)
	
	if roundIdleSeconds == 10 then
		local ileft = maxRoundIdleTime - roundIdleSeconds
	
		PrintText("Round "..roundnum.." - Liberate Territories to get more reinforcements.", 20, 'FFFFFFFF',ileft - 2,'centertop')
	end

	-- display after 5 seconds into each round
	--if roundIdleSeconds == 5  then displayRoundCountdown(5) end
	--if roundIdleSeconds == 15 then displayRoundCountdown(2) end
end

function displayRoundCountdown(staytime)
	if roundIdleSeconds < idleWarnMin or roundIdleSeconds > idleWarnMax then
		return
	end
	local ileft = maxRoundIdleTime - roundIdleSeconds
	
	-- prefix seconds
	if (ileft < 10) then ileft = "0"..ileft end
	
	PrintText("Reinforcements arrive in 0:"..ileft.."", 20, '00DDDDDD', staytime, 'centertop') 
end

function displayMissions()
  
	local mission = players[GetFocusArmy()].mission
	local missionText = mission:getText()
	
	PrintText('                                           ', 60,'FF0000FF', 999999,'centertop') -- to move text down
	PrintText(missionText, 30, '00FF4040',999999,'centertop') 
	
end

function displayRoundBegin()

	local player = players[GetFocusArmy()]
	-- todo: replace with real timer
	local ileft = maxRoundIdleTime + 2
	local missionText = player.mission:getText()
	
	--PrintText('                                           ', 60,'FF0000FF',ileft,'centertop') -- to move text down
	--PrintText(missionText, 30, 'FF5050FF',ileft,'centertop') 
	--PrintText("Round "..roundnum.." - Produce Units and Attack. ", 20, 'FFFFFFFF',ileft,'centertop')

	local objTitle = "Round "..roundnum..' - Reinforce your territories - you can build '..player.acu.SRUnitsToBuild..' units. '
	if player.build then
		if player.build.starting then
			objTitle = objTitle..'(Initial Units)'
		else
			objTitle = objTitle..'('..player.build.total..' this round, '..player.build.ter..' from territories, '..player.build.cont..' from continents, '..player.build.bonus..' from wreckage)'
		end
	end
	PrintText(objTitle, 20, 'FFFFFFFF', 9, 'centertop')
	--end

    --if roundIdleSeconds == 10 then
	--	PrintText("Round "..roundnum.." - Attack! ", 20, 'FFFFFFFF',ileft - 10,'centertop')
	--end
		
end


-- An Action that delays the next round (fighting, building)
function onRoundAction(start)
	if start then
		roundIdleSeconds = start
	else
		roundIdleSeconds = 0
	end
end

function getAllies(me)
	local allies = {}
	for i, player in players do
		if IsAlly(player.index, me.index) then
			table.insert(allies, player)
		end
	end
	return allies
end

function checkContinentOwn(continent, player)
	local o = false
	for army, counter in continent.owners do
		if IsAlly(player.index, army) then -- allied?
			o = true
			--teams[army] = army
		else
			o = false
			break
		end
	end
	return o
end

function computeIncome(player)
		local build = {};
		build.ter = math.floor(player.empireSize/3)
		if build.ter < 3 then build.ter = 3 end
		
		local teams = getAllies(player)
		-- bonus card cashin
		build.bonus = player.nextRoundBonusProfit

		build.ter = build.ter * player.resourceMultiplyer
		build.bonus = build.bonus * player.resourceMultiplyer
		
		-- Continent resources
		build.cont = 0
		for i,continent in continents do
--			dump(continent.owners)
			if checkContinentOwn(continent, player) then
				build.cont = build.cont + continent.ownerBonus
			end
		end
		
		local teamSize = table.getn(teams)
		if build.cont > 0 and teamSize > 1 then
			local ns = math.floor(build.cont/teamSize)
			local rest = build.cont - ns*teamSize
			
			build.cont = ns;
			for i, p in teams do
				if rest > 0 then
					rest = rest -1
					if p.index == player.index then
						build.cont = build.cont +1
					end
				end
			end
		end
		LOG(player.brain.Nickname.." receives "..build.cont.." for continents")
		
		build.total = build.ter + build.cont + build.bonus
		return build
end

function beginNextRound()
	
	roundnum = roundnum +1
	LOG("A NEW ROUND "..roundnum.." has begun")
	roundTotalTime = 0
	
	-- distribute Resources
	for i, player in players do
		player.build = computeIncome(player)
		player.nextRoundBonusProfit = 0
		player.bonusCardSpawned = false
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
	LOG("checking win on "..player.mission:getText())
	if player.mission:check() and not player.acu:IsDead() then
		PrintText(player.brain.Nickname.." won: "..player.mission:getText(),20,'FFFFFFFF',5,'center') 

		-- Kill all other units!
		player.acu:SetIntelRadius('Vision', 2000)
		continents = {} -- destroy countries to prevent respawns
		WaitSeconds(1)		
		
		for i, player in players do
			player.brain.OnDefeat = player.brain.OnOrigDefeat -- restore defeat
		end

		local otherUnits = GetUnitsInRect(Rect(0,0,1024,1024))
		for i, unit in otherUnits do
			if not IsAlly(player.index, unit:GetArmy()) then
				unit:Kill()
				--player.brain:OnDefeat()
			end
		end		

		WaitSeconds(500)
	end
end

function updateSecondaryMissions()
	for i, player in players do
	
--		LOG(i.." "..player.acu.SRUnitsToBuild)

		if player.index == GetFocusArmy() then
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
				-- kill preview
				if player.previewObjective then
					ScenarioFramework.Objectives.UpdateObjective( objTitle, 'complete', "complete", player.previewObjective.Tag)
					player.previewObjective = nil
				end
				
				-- show real
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
			if not player.acu:IsDead() and player.acu.SRUnitsToBuild > 0 and (roundIdleSeconds == 10 or roundIdleSeconds == 20) then
				player.buildObjectiveWarn = true
				local m1 = {{text = '<LOC E01_M01_060_010>You have '..player.acu.SRUnitsToBuild..' units left to build, Sir.', 
				vid = 'E01_EarthCom_M01_01131.sfd', bank = 'E01_VO', 
				cue = 'E01_EarthCom_M01_01131', faction = 'UEF'}}
				
				ScenarioFramework.Dialogue(m1)		
			end
			
			-- check bonus unit cards
			if canCashinAny(player) then
--				LOG("We could cash in bonus cards!")
				-- Add secondary objective - use these resources!!
				if not player.cardObjective  then
					local m1 = {{text = '<LOC E01_M01_060_010>[{i EarthCom}]: Reclaim the wreckages at the map bottom for Bonus Units. ', vid = 'E01_EarthCom_M01_01131.sfd', bank = 'E01_VO', cue = 'E01_EarthCom_M01_01131', faction = 'UEF'}}
					ScenarioFramework.Dialogue(m1)		

				
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
			        {Category = categories.ueb0301}
					)
			end
			
			if player.acu.SRUnitsToBuild == 0 and not player.previewObjective then
				player.previewObjective = ScenarioFramework.Objectives.Basic(
			        '',
			        'incomplete',
					'',
			        "detail",
			        ScenarioFramework.Objectives.GetActionIcon("build"),
			        {Category = categories.ueb0301}
					)
			end
			if player.acu.SRUnitsToBuild == 0 and player.previewObjective then
				-- update
				local b = computeIncome(player)
				local ptitle = 'Next Round (begins after noone attacks or builds for '..maxRoundIdleTime..' seconds) you can build '..b.total..
				' units ('..b.ter..' from territories, '..b.cont..' from continents, '..b.bonus..' from wreckage)'
		        ScenarioFramework.Objectives.UpdateObjective( ptitle, 'title', ptitle, player.previewObjective.Tag)
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

	zoomOut()

	while true do
		checkCountryOwnership()
		
		checkEndOfRound()
		checkEndOfGame()
		
		updateSecondaryMissions()
--		updateScore()
		WaitSeconds(1)
	end
end

function jobsThread()
	while true do
		reassignFactories()
		checkTeleportationZones()
		controlAIPlayers()
		WaitSeconds(1)
	end
end

function controlAIPlayers()
	for i, player in players do
	-- Start the AI (no human)
		if player.brain.BrainType == "AI" then
			onPlayerDefeat(player.brain)
		end
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

------- bonus cards #########

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
